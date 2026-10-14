//
//  GroupModerationTests.swift
//  StudyForgeTests
//
//  Tests for F16's moderator — the guarantee that an admin is ALWAYS in a group's chat.
//
//  THE TESTS THAT MATTER MOST are `theModeratorCanNeverBeRemoved` and `aMemberCannotModerate`:
//  those are the two ways the feature could look correct in a screenshot and be untrue in the
//  product. The rest cover the tombstone and the append-only log, both of which fail silently if
//  they regress.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("F16 group moderation")
struct GroupModerationTests {

    private let now = Date(timeIntervalSince1970: 3_000_000)

    private let moderator = GroupModerator(id: "admin-1", displayName: "Haetham")

    private func state() -> ChatModerationState {
        ChatModerationState(moderator: moderator)
    }

    private func message(_ id: String, _ text: String = "hello") -> GroupMessage {
        GroupMessage(id: id, senderName: "Sara", text: text, sentAt: now)
    }

    // MARK: The headline guarantee — "admin always there"

    @Test("The moderator can never be removed, by anyone")
    func theModeratorCanNeverBeRemoved() {
        #expect(ModerationPolicy.canRemoveModerator() == false)
    }

    @Test("The moderator can never be demoted, because a demotion is a removal with better manners")
    func theModeratorCanNeverBeDemoted() {
        #expect(ModerationPolicy.canDemoteModerator() == false)
    }

    @Test("A state always carries a moderator, so an unmoderated chat is not representable")
    func aStateAlwaysHasAModerator() {
        #expect(state().moderator.id == "admin-1")
    }

    // MARK: Authority

    @Test("Only the moderator may moderate")
    func aMemberCannotModerate() {
        #expect(ModerationPolicy.mayModerate(uid: "admin-1", state: state()))
        #expect(ModerationPolicy.mayModerate(uid: "student-9", state: state()) == false)
    }

    @Test("A member's attempt to hide a message is refused, not silently ignored")
    func aMemberHidingIsRefused() {
        var moderation = state()

        #expect(throws: ModerationError.notTheModerator) {
            try moderation.apply(.hide, to: "m1", reason: .spam, by: "student-9", at: now)
        }
        #expect(moderation.isHidden("m1") == false)
        #expect(moderation.actions.isEmpty)
    }

    // MARK: Hiding and the tombstone

    @Test("Hiding a message records the reason and hides the body")
    func hidingRecordsTheReason() throws {
        var moderation = state()

        try moderation.apply(.hide, to: "m1", reason: .unsafe, by: moderator.id, at: now)

        #expect(moderation.isHidden("m1"))
        #expect(moderation.hiddenReason(for: "m1") == .unsafe)
        #expect(moderation.visibleBody(of: message("m1")) == nil)
    }

    @Test("A message that was never hidden keeps its body")
    func untouchedMessagesStayVisible() {
        let moderation = state()
        #expect(moderation.visibleBody(of: message("m1", "still here")) == "still here")
    }

    @Test("Deleting hides the message the same way hiding does")
    func deletingAlsoHides() throws {
        var moderation = state()

        try moderation.apply(.delete, to: "m1", reason: .spam, by: moderator.id, at: now)

        #expect(moderation.isHidden("m1"))
        #expect(moderation.visibleBody(of: message("m1")) == nil)
    }

    // MARK: Pinning

    @Test("Pinning makes a message the group's single announcement")
    func pinningIsExclusive() throws {
        var moderation = state()

        try moderation.apply(.pin, to: "m1", reason: .other, note: "exam date",
                             by: moderator.id, at: now)
        #expect(moderation.pinnedMessageId == "m1")

        // Pinning a second message replaces the first, rather than building a noticeboard.
        try moderation.apply(.pin, to: "m2", reason: .other, note: "new date",
                             by: moderator.id, at: now)
        #expect(moderation.pinnedMessageId == "m2")
    }

    @Test("Pinning does not hide the message")
    func pinningDoesNotHide() throws {
        var moderation = state()

        try moderation.apply(.pin, to: "m1", reason: .offTopic, by: moderator.id, at: now)

        #expect(moderation.isHidden("m1") == false)
        #expect(moderation.visibleBody(of: message("m1")) != nil)
    }

    // MARK: Flagging

    @Test("Flagging records the action without changing what members see")
    func flaggingLeavesTheMessageVisible() throws {
        var moderation = state()

        try moderation.apply(.flag, to: "m1", reason: .spam, by: moderator.id, at: now)

        #expect(moderation.actions.count == 1)
        #expect(moderation.actions.first?.kind == .flag)
        #expect(moderation.isHidden("m1") == false)
    }

    // MARK: Reasons

    @Test("An 'other' reason without a note is refused, because it explains nothing")
    func otherReasonNeedsANote() {
        var moderation = state()

        #expect(throws: ModerationError.reasonRequiresNote) {
            try moderation.apply(.hide, to: "m1", reason: .other, by: moderator.id, at: now)
        }
        // Whitespace is not a note.
        #expect(throws: ModerationError.reasonRequiresNote) {
            try moderation.apply(.hide, to: "m1", reason: .other, note: "   ",
                                 by: moderator.id, at: now)
        }
    }

    @Test("An 'other' reason with a note is accepted, and the note is trimmed")
    func otherReasonWithANoteIsAccepted() throws {
        var moderation = state()

        try moderation.apply(.hide, to: "m1", reason: .other, note: "  off-syllabus  ",
                             by: moderator.id, at: now)

        #expect(moderation.actions.first?.note == "off-syllabus")
    }

    @Test("The named reasons may be used without a note")
    func namedReasonsNeedNoNote() throws {
        var moderation = state()

        for (index, reason) in [ModerationReason.spam, .offTopic, .unsafe].enumerated() {
            try moderation.apply(.flag, to: "m\(index)", reason: reason, by: moderator.id, at: now)
        }

        #expect(moderation.actions.count == 3)
        #expect(moderation.actions.allSatisfy { $0.note == nil })
    }

    // MARK: The audit log

    @Test("Every action is appended in order, so the log reads as a history")
    func theLogIsAppendOnlyInOrder() throws {
        var moderation = state()

        try moderation.apply(.flag, to: "m1", reason: .spam, by: moderator.id, at: now)
        try moderation.apply(.hide, to: "m1", reason: .unsafe, by: moderator.id, at: now)
        try moderation.apply(.pin, to: "m2", reason: .offTopic, by: moderator.id, at: now)

        #expect(moderation.actions.map(\.kind) == [.flag, .hide, .pin])
        #expect(moderation.actions.allSatisfy { $0.moderatorUid == moderator.id })
    }

    @Test("The action carries the reason and the moment, which is what N06 shows")
    func theActionIsAccountable() throws {
        var moderation = state()

        let action = try moderation.apply(.hide, to: "m1", reason: .unsafe,
                                          by: moderator.id, at: now)

        #expect(action.kind == .hide)
        #expect(action.messageId == "m1")
        #expect(action.reason == .unsafe)
        #expect(action.at == now)
    }
}
