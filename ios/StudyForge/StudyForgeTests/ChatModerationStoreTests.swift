//
//  ChatModerationStoreTests.swift
//  StudyForgeTests
//
//  Tests for F16's moderation log: the seam the chat appends to, and the fold that turns the log
//  back into what the room sees.
//
//  THE TESTS THAT MATTER MOST are `theSameActionCannotBeWrittenTwice` and
//  `replayHidesTheMessageWithItsReason`. The first is the append-only guarantee N06 claims — an
//  audit log that can be written twice is not an audit log. The second is N03: a hidden message must
//  come back as a tombstone with its reason, not as a missing row the room reads as a bug.
//
//  The store is exercised through both implementations wherever the behaviour is a rule rather than
//  a storage detail, because a preview or a test that behaves differently from the file the app
//  ships is worse than no preview at all.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Chat moderation store (F16)")
struct ChatModerationStoreTests {

    // MARK: Fixtures

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("chat-moderation-tests-\(UUID().uuidString)", isDirectory: true)
    }

    private var moderator: GroupModerator {
        GroupModerator(id: "admin-1", displayName: "Saleh Abdulla")
    }

    private func action(
        _ kind: ModerationActionKind = .hide,
        message: String = "m1",
        reason: ModerationReason = .spam,
        note: String? = nil,
        at: TimeInterval = 1_000
    ) -> ModerationAction {
        ModerationAction(
            kind: kind,
            messageId: message,
            moderatorUid: "admin-1",
            reason: reason,
            note: note,
            at: Date(timeIntervalSince1970: at)
        )
    }

    // MARK: Reading and appending

    @Test("A group that has never been moderated has an empty log, not an error")
    func untouchedGroupIsEmpty() async throws {
        let store = InMemoryChatModerationStore()
        #expect(try await store.actions(for: "g1").isEmpty)
    }

    @Test("An appended action reads back with its reason, its note and the moment it was taken")
    func appendedActionReadsBack() async throws {
        let store = InMemoryChatModerationStore()
        let recorded = action(.hide, message: "m7", reason: .offTopic, note: "off the syllabus", at: 42)

        try await store.append(recorded, to: "g1")

        let log = try await store.actions(for: "g1")
        #expect(log.count == 1)
        #expect(log.first == recorded, "the audit row must not lose the note or the timestamp")
        #expect(log.first?.moderatorUid == "admin-1")
    }

    @Test("Two groups keep their own logs")
    func groupsAreKeptApart() async throws {
        let store = InMemoryChatModerationStore()
        try await store.append(action(.hide, message: "m1"), to: "g1")
        try await store.append(action(.pin, message: "m2"), to: "g2")

        #expect(try await store.actions(for: "g1").map(\.messageId) == ["m1"])
        #expect(try await store.actions(for: "g2").map(\.messageId) == ["m2"])
    }

    @Test("The same action cannot be written twice, and the log does not grow")
    func theSameActionCannotBeWrittenTwice() async throws {
        let store = InMemoryChatModerationStore()
        let once = action(.hide, message: "m1")

        try await store.append(once, to: "g1")
        await #expect(throws: ChatModerationStoreError.duplicateAction) {
            try await store.append(once, to: "g1")
        }

        #expect(try await store.actions(for: "g1").count == 1)
    }

    @Test("The log reads oldest first, whatever order the actions arrived in")
    func theLogReadsOldestFirst() async throws {
        let store = InMemoryChatModerationStore()
        let later = action(.pin, message: "m2", at: 2_000)
        let earlier = action(.hide, message: "m1", at: 1_000)

        // Offline actions resolve out of order: the later decision can arrive first.
        try await store.append(later, to: "g1")
        try await store.append(earlier, to: "g1")

        #expect(try await store.actions(for: "g1").map(\.messageId) == ["m1", "m2"])
    }

    @Test("A forced failure surfaces as a storage error, and clearing it restores success")
    func forcedFailure() async throws {
        let store = InMemoryChatModerationStore()
        // Bound before the closure so the assertion does not capture the test case itself.
        let attempt = action(.hide, message: "m9")
        await store.forceFailure(.storageFailed)

        await #expect(throws: ChatModerationStoreError.storageFailed) {
            try await store.append(attempt, to: "g1")
        }
        await #expect(throws: ChatModerationStoreError.storageFailed) {
            try await store.actions(for: "g1")
        }

        await store.forceFailure(nil)
        try await store.append(attempt, to: "g1")
        #expect(try await store.actions(for: "g1").count == 1)
    }

    // MARK: The file store

    @Test("The log survives a file round-trip, read back by a second instance")
    func fileRoundTrip() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let hidden = action(.hide, message: "m1", reason: .unsafe, at: 1_000)
        let pinned = action(.pin, message: "m2", at: 2_000)
        let writer = FileChatModerationStore(directory: directory)
        try await writer.append(hidden, to: "g1")
        try await writer.append(pinned, to: "g1")

        // A fresh instance, so the assertion reads the file rather than the first store's cache.
        let reader = FileChatModerationStore(directory: directory)
        #expect(try await reader.actions(for: "g1") == [hidden, pinned])
        #expect(try await reader.actions(for: "g2").isEmpty)
    }

    @Test("The file store refuses a duplicate too, so the guarantee is not a memory-only one")
    func fileStoreRefusesDuplicates() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = FileChatModerationStore(directory: directory)
        let once = action(.delete, message: "m1")
        try await store.append(once, to: "g1")

        await #expect(throws: ChatModerationStoreError.duplicateAction) {
            try await store.append(once, to: "g1")
        }
        #expect(try await store.actions(for: "g1").count == 1)
    }

    @Test("A corrupt log is a storage failure, and it is never quietly replaced")
    func corruptLogIsSurfaced() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let file = directory.appendingPathComponent("chatModeration.json")
        let contents = Data("this is not json".utf8)
        try contents.write(to: file)
        let attempt = action()

        let store = FileChatModerationStore(directory: directory)
        await #expect(throws: ChatModerationStoreError.storageFailed) {
            try await store.actions(for: "g1")
        }
        // Appending reads first, so a broken log is left for a human instead of being overwritten
        // with what would look like a clean, never-moderated chat.
        await #expect(throws: ChatModerationStoreError.storageFailed) {
            try await store.append(attempt, to: "g1")
        }
        #expect(try Data(contentsOf: file) == contents)
    }

    // MARK: Replaying the log

    @Test("A hidden message replays as a tombstone carrying its reason")
    func replayHidesTheMessageWithItsReason() async throws {
        let store = InMemoryChatModerationStore()
        let message = GroupMessage(senderName: "Omar", text: "buy my notes")
        try await store.append(action(.hide, message: message.id, reason: .spam), to: "g1")

        let state = ChatModerationState.replaying(
            try await store.actions(for: "g1"),
            moderator: moderator
        )

        #expect(state.visibleBody(of: message) == nil, "the body must not survive a hide")
        #expect(state.hiddenReason(for: message.id) == .spam)
        #expect(state.actions.count == 1, "the tombstone and the audit row come from one write")
    }

    @Test("A pin replays as the group's single announcement, replacing the previous one")
    func replayPinsTheAnnouncement() async throws {
        let store = InMemoryChatModerationStore()
        try await store.append(action(.pin, message: "m1", at: 1_000), to: "g1")
        try await store.append(action(.pin, message: "m2", at: 2_000), to: "g1")

        let state = ChatModerationState.replaying(
            try await store.actions(for: "g1"),
            moderator: moderator
        )

        #expect(state.pinnedMessageId == "m2")
        #expect(state.actions.count == 2, "the superseded pin stays in the log as history")
    }

    @Test("Flagging is recorded but changes nothing the room sees")
    func replayOfAFlagChangesNothing() async throws {
        let store = InMemoryChatModerationStore()
        try await store.append(
            action(.flag, message: "m1", reason: .other, note: "check the link"),
            to: "g1"
        )

        let state = ChatModerationState.replaying(
            try await store.actions(for: "g1"),
            moderator: moderator
        )

        #expect(!state.isHidden("m1"))
        #expect(state.pinnedMessageId == nil)
        #expect(state.actions.first?.note == "check the link")
    }

    @Test("Replay follows the timestamp, not the arrival order")
    func replayFollowsTheTimestamp() async throws {
        let store = InMemoryChatModerationStore()
        let later = action(.hide, message: "m2", at: 2_000)
        let earlier = action(.pin, message: "m1", at: 1_000)
        try await store.append(later, to: "g1")
        try await store.append(earlier, to: "g1")

        let state = ChatModerationState.replaying(
            try await store.actions(for: "g1"),
            moderator: moderator
        )

        #expect(state.actions.map(\.id) == [earlier.id, later.id])
        #expect(state.hidden["m2"] == .spam)
        #expect(state.pinnedMessageId == "m1")
    }

    @Test("An empty log replays as a chat with no moderation in it")
    func replayOfNothingIsClean() {
        let state = ChatModerationState.replaying([], moderator: moderator)

        #expect(state.actions.isEmpty)
        #expect(state.pinnedMessageId == nil)
        #expect(state.hidden.isEmpty)
        #expect(state.moderator == moderator, "the moderator is present from the first launch")
    }

    // MARK: Error mapping

    @Test("A duplicate action is an internal breach, not a server outage")
    func duplicateActionIsNotReportedAsStorage() {
        // A refusal is shown to the moderator, so the two cases must not read the same: one is
        // "we could not save", the other is "this decision is already recorded".
        #expect(
            ChatModerationStoreError.storageFailed.asAppError
                == .server(reference: "chat-moderation-store-failed")
        )
        #expect(ChatModerationStoreError.duplicateAction.asAppError == .unknown)
    }
}
