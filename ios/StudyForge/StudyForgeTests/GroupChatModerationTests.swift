//
//  GroupChatModerationTests.swift
//  StudyForgeTests
//
//  F16 — the moderation seam on `GroupChatViewModel`, driven the way the screen drives it.
//
//  WHY THROUGH THE VIEW MODEL AND NOT THE STATE
//  --------------------------------------------
//  `GroupModerationTests` already proves the fold is correct. What it cannot prove is that the
//  screen USES it: a view model that never folded the log would pass every pure test and still hand
//  the row `message.text`. So each test here reads back through `visibleBody(of:)`,
//  `hiddenReason(for:)`, `pinnedMessage` or `canModerate` — the only members a SwiftUI row reaches.
//
//  WHY `forceFailure` RATHER THAN A FAKE
//  -------------------------------------
//  `InMemoryChatModerationStore` is a real conformance with a documented failure switch, so the
//  failed path is exercised against the store the app itself uses. A hand-written stub would not
//  also enforce the append-only rule, and could let the view model pass against behaviour the
//  product does not have.
//
//  WHY THE GROUP STORE IS CHECKED TOO
//  ----------------------------------
//  N03 hides a message; it does not erase it. If a change ever made `hide` drop the message from
//  `StudyGroup`, every test here except `hidingKeepsTheTextInTheGroup` would still pass while the
//  audit trail lost its subject.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Chat moderation through the view model (F16)")
@MainActor
struct GroupChatModerationTests {

    private let moderator = GroupModerator(id: "admin-1", displayName: "Haetham")

    private let text = "Anyone free at 6?"

    /// A two-member group, a moderation log, and a view model already loaded.
    ///
    /// `failure` is forced before `load()`, so a test can drive the unreadable-log path; pass `nil`
    /// to have the log behave. The viewer defaults to the moderator, which is the screen that can
    /// actually take an action.
    private func model(
        messages: [GroupMessage]? = nil,
        log: [ModerationAction] = [],
        viewer: String? = "admin-1",
        failure: ChatModerationStoreError? = nil
    ) async -> (GroupChatViewModel, InMemoryChatModerationStore, InMemoryGroupStore) {
        let group = StudyGroup(
            id: "g1",
            name: "Database revision",
            members: [GroupMember(name: "Haetham", isOwner: true), GroupMember(name: "Omar")],
            messages: messages ?? [message("m1", text)]
        )
        let groups = InMemoryGroupStore(seededWith: [group])
        let store = InMemoryChatModerationStore(seededWith: log.isEmpty ? [:] : ["g1": log])
        if let failure { await store.forceFailure(failure) }

        let viewModel = GroupChatViewModel(
            groupId: "g1",
            store: groups,
            me: "Haetham",
            moderator: moderator,
            viewerId: viewer,
            moderationStore: store
        )
        await viewModel.load()
        return (viewModel, store, groups)
    }

    /// A message posted by Omar, the classmate in every fixture.
    private func message(_ id: String, _ body: String) -> GroupMessage {
        GroupMessage(id: id, senderName: "Omar", text: body)
    }

    /// A hide recorded before the screen was ever opened — a cold launch's starting log.
    private func recordedHide(_ messageId: String, reason: ModerationReason = .unsafe) -> ModerationAction {
        ModerationAction(kind: .hide, messageId: messageId, moderatorUid: "admin-1", reason: reason)
    }

    // MARK: Who may moderate

    @Test("The moderator's screen offers the controls; a classmate's does not")
    func onlyTheModeratorSeesTheControls() async {
        let (asModerator, _, _) = await model()
        let (asClassmate, _, _) = await model(viewer: "student-9")

        #expect(asModerator.canModerate)
        #expect(asModerator.isModerationAvailable)
        #expect(asClassmate.canModerate == false)
        // The classmate still gets the moderator's decisions: hiding is not a private action.
        #expect(asClassmate.isModerationAvailable)
    }

    @Test("A screen opened without a moderation context renders the plain chat")
    func withoutAModeratorNothingIsHidden() async {
        let groups = InMemoryGroupStore(seededWith: [
            StudyGroup(id: "g1", name: "Database revision", messages: [message("m1", text)])
        ])
        let store = InMemoryChatModerationStore(seededWith: ["g1": [recordedHide("m1")]])
        let viewModel = GroupChatViewModel(
            groupId: "g1", store: groups, me: "Haetham", moderationStore: store
        )

        await viewModel.load()

        // I11's construction, unchanged: no controls, no tombstone, and the log is not folded at all.
        #expect(viewModel.moderation == nil)
        #expect(viewModel.canModerate == false)
        #expect(viewModel.visibleBody(of: viewModel.messages[0]) == text)
        #expect(viewModel.auditLog.isEmpty)
    }

    @Test("A classmate's hide is refused and nothing is written")
    func aClassmateCannotModerate() async throws {
        let (viewModel, store, _) = await model(viewer: "student-9")

        let hid = await viewModel.hide(viewModel.messages[0], reason: .spam)

        #expect(hid == false)
        #expect(viewModel.refusal == .notTheModerator)
        #expect(try await store.actions(for: "g1").isEmpty)
        #expect(viewModel.visibleBody(of: viewModel.messages[0]) == text)
    }

    // MARK: Hiding

    @Test("Hiding takes the body away, so the row can draw a tombstone")
    func hidingReplacesTheBody() async {
        let (viewModel, _, _) = await model()

        let hid = await viewModel.hide(viewModel.messages[0], reason: .spam)

        #expect(hid)
        #expect(viewModel.visibleBody(of: viewModel.messages[0]) == nil)
        #expect(viewModel.isHidden(viewModel.messages[0]))
        #expect(viewModel.hiddenReason(for: viewModel.messages[0]) == .spam)
        #expect(viewModel.auditLog.count == 1)
        #expect(viewModel.auditLog.first?.kind == .hide)
        #expect(viewModel.auditLog.first?.reason == .spam)
        #expect(viewModel.auditLog.first?.moderatorUid == moderator.id)
    }

    @Test("Hiding leaves the message in the group: a tombstone is not a deletion")
    func hidingKeepsTheTextInTheGroup() async throws {
        let (viewModel, _, groups) = await model()

        await viewModel.hide(viewModel.messages[0], reason: .spam)

        #expect(viewModel.messages.count == 1)
        #expect(try await groups.group(id: "g1")?.messages.first?.text == text)
    }

    @Test("Deleting hides the body exactly as hiding does, under its own reason")
    func deletingHidesTheBody() async {
        let (viewModel, _, _) = await model()

        await viewModel.delete(viewModel.messages[0], reason: .offTopic)

        #expect(viewModel.visibleBody(of: viewModel.messages[0]) == nil)
        #expect(viewModel.hiddenReason(for: viewModel.messages[0]) == .offTopic)
        #expect(viewModel.auditLog.first?.kind == .delete)
    }

    @Test("A hide is in the log, so reopening the chat still hides the message")
    func aHideSurvivesAReopen() async {
        let (viewModel, store, groups) = await model()
        await viewModel.hide(viewModel.messages[0], reason: .spam)

        // A second screen on the same group and the same log — what a cold launch starts from.
        let reopened = GroupChatViewModel(
            groupId: "g1",
            store: groups,
            me: "Omar",
            moderator: moderator,
            viewerId: "student-9",
            moderationStore: store
        )
        await reopened.load()

        #expect(reopened.isHidden(reopened.messages[0]))
        #expect(reopened.visibleBody(of: reopened.messages[0]) == nil)
        #expect(reopened.canModerate == false)
    }

    @Test("A log written before this screen existed is folded on load")
    func anExistingLogIsFoldedOnLoad() async {
        let (viewModel, _, _) = await model(log: [recordedHide("m1", reason: .unsafe)])

        #expect(viewModel.isHidden(viewModel.messages[0]))
        #expect(viewModel.hiddenReason(for: viewModel.messages[0]) == .unsafe)
        #expect(viewModel.auditLog.count == 1)
    }

    @Test("Moderation never rewrites the conversation")
    func moderationNeverRewritesTheConversation() async {
        let (viewModel, _, _) = await model()
        let before = viewModel.messages

        await viewModel.hide(before[0], reason: .spam)
        await viewModel.pin(before[0], reason: .spam)

        #expect(viewModel.messages == before)
    }

    // MARK: Pinning

    @Test("Pinning surfaces the announcement without hiding the message")
    func pinningSurfacesTheAnnouncement() async {
        let (viewModel, _, _) = await model()

        let pinned = await viewModel.pin(viewModel.messages[0], reason: .offTopic)

        #expect(pinned)
        #expect(viewModel.pinnedMessage?.id == "m1")
        #expect(viewModel.visibleBody(of: viewModel.messages[0]) == text)
        #expect(viewModel.isHidden(viewModel.messages[0]) == false)
    }

    @Test("A second pin replaces the first: there is one announcement, not a board")
    func aSecondPinReplacesTheFirst() async throws {
        let messages = [message("m1", text), message("m2", "Bring the slides")]
        let (viewModel, _, _) = await model(messages: messages)

        let first = try #require(viewModel.messages.first { $0.id == "m1" })
        let second = try #require(viewModel.messages.first { $0.id == "m2" })

        await viewModel.pin(first, reason: .offTopic)
        await viewModel.pin(second, reason: .offTopic)

        #expect(viewModel.pinnedMessage?.id == "m2")
        #expect(viewModel.auditLog.count == 2)
    }

    @Test("A pin for a message that is no longer in the group resolves to nothing")
    func aDanglingPinShowsNothing() async {
        let pin = ModerationAction(
            kind: .pin, messageId: "gone", moderatorUid: "admin-1", reason: .offTopic
        )
        let (viewModel, _, _) = await model(log: [pin])

        #expect(viewModel.pinnedMessage == nil)
        #expect(viewModel.visibleBody(of: viewModel.messages[0]) == text)
    }

    // MARK: Refusals

    @Test("'Other' is refused without a note, and nothing reaches the log")
    func otherRequiresANote() async throws {
        let (viewModel, store, _) = await model()

        let hid = await viewModel.hide(viewModel.messages[0], reason: .other)

        #expect(hid == false)
        #expect(viewModel.refusal == .reasonRequiresNote)
        #expect(try await store.actions(for: "g1").isEmpty)
        #expect(viewModel.visibleBody(of: viewModel.messages[0]) == text)
        #expect(viewModel.moderationError == nil)
    }

    @Test("A note is stored trimmed")
    func aNoteIsStoredTrimmed() async {
        let (viewModel, _, _) = await model()

        let hid = await viewModel.hide(viewModel.messages[0], reason: .other, note: "  Spoiler for week 3  ")

        #expect(hid)
        #expect(viewModel.auditLog.last?.note == "Spoiler for week 3")
        #expect(viewModel.hiddenReason(for: viewModel.messages[0]) == .other)
        #expect(viewModel.refusal == nil)
    }

    @Test("A note on a reason that explains itself is kept, not discarded")
    func aNoteOnASelfExplainingReasonIsKept() async {
        let (viewModel, _, _) = await model()

        await viewModel.hide(viewModel.messages[0], reason: .spam, note: "Third time today")

        #expect(viewModel.auditLog.last?.note == "Third time today")
        #expect(viewModel.hiddenReason(for: viewModel.messages[0]) == .spam)
    }

    // MARK: Flagging

    @Test("Flagging raises the message without changing what members see")
    func flaggingChangesNothingMembersSee() async {
        let (viewModel, _, _) = await model()

        let flagged = await viewModel.flag(viewModel.messages[0], reason: .unsafe)

        #expect(flagged)
        #expect(viewModel.visibleBody(of: viewModel.messages[0]) == text)
        #expect(viewModel.isHidden(viewModel.messages[0]) == false)
        #expect(viewModel.pinnedMessage == nil)
        #expect(viewModel.auditLog.first?.kind == .flag)
    }

    // MARK: Failures

    @Test("An unreadable log leaves the chat readable and unmoderated, not empty")
    func anUnreadableLogLeavesTheChatReadable() async {
        let (viewModel, _, _) = await model(failure: .storageFailed)

        #expect(viewModel.messages.count == 1)
        #expect(viewModel.moderation == nil)
        #expect(viewModel.canModerate == false)
        #expect(viewModel.moderationError == ChatModerationStoreError.storageFailed.asAppError)
        // A failure in the moderation store is not a failure of the conversation.
        #expect(viewModel.error == nil)
        #expect(viewModel.visibleBody(of: viewModel.messages[0]) == text)
    }

    @Test("A failed append is reported and leaves the message visible")
    func aFailedAppendIsReported() async throws {
        let (viewModel, store, _) = await model()
        await store.forceFailure(.storageFailed)

        let hid = await viewModel.hide(viewModel.messages[0], reason: .spam)

        #expect(hid == false)
        #expect(viewModel.moderationError == ChatModerationStoreError.storageFailed.asAppError)
        // Nothing was optimistically hidden: the row never shows a moderation that did not land.
        #expect(viewModel.visibleBody(of: viewModel.messages[0]) == text)
        #expect(viewModel.auditLog.isEmpty)

        // Read the log back with the store working again, so "nothing landed" is a real read.
        await store.forceFailure(nil)
        #expect(try await store.actions(for: "g1").isEmpty)
    }

    @Test("A duplicate append is not reported as a storage fault")
    func aDuplicateAppendIsNotAStorageFault() async {
        let (viewModel, store, _) = await model()
        await store.forceFailure(.duplicateAction)

        let hid = await viewModel.hide(viewModel.messages[0], reason: .spam)

        // The store refuses both the write and the confirming re-read, so the action cannot be
        // confirmed — but what is reported must not claim storage broke, because it did not.
        #expect(hid == false)
        #expect(viewModel.moderationError == ChatModerationStoreError.duplicateAction.asAppError)
        #expect(viewModel.moderationError != ChatModerationStoreError.storageFailed.asAppError)
        #expect(viewModel.visibleBody(of: viewModel.messages[0]) == text)
    }

    @Test("Reloading after the log recovers clears the reported failure")
    func aReloadClearsAReportedFailure() async {
        let (viewModel, store, _) = await model(failure: .storageFailed)
        #expect(viewModel.moderationError != nil)

        await store.forceFailure(nil)
        await viewModel.load()

        #expect(viewModel.moderationError == nil)
        #expect(viewModel.canModerate)
        #expect(viewModel.auditLog.isEmpty)
    }
}
