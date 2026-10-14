//
//  GroupModeration.swift
//  StudyForge
//
//  F16 — the admin-moderated group chat: the moderator who is ALWAYS in the space, the actions
//  they can take, and the rules that make the guarantee real (docs/03 §N, N01–N06).
//
//  WHY "ALWAYS THERE" IS A RULE AND NOT A BADGE
//  -------------------------------------------
//  The requirement is that an admin is always present in a group's chat. A badge drawn in the UI
//  would satisfy the screenshot and nothing else: the group owner could remove the moderator, or
//  an admin could delete the moderator document by accident, and the chat would quietly stop
//  being moderated while still claiming that it was. So the permanence lives in two places that
//  cannot be bypassed by a client — the security rules (`firestore.rules`, where a moderator
//  member document refuses every update and delete) and this file, which is where the decision is
//  expressed, named and tested. `ModerationPolicy.canRemoveModerator` is deliberately a function
//  that returns `false` rather than an omission, so the answer to "can the moderator be removed?"
//  is written down in code a reviewer can read.
//
//  WHY THIS IS A SEPARATE FILE FROM `StudyGroup`
//  --------------------------------------------
//  F09 owns `Core/Groups/StudyGroup.swift` (M4's lane). F16 owns moderation. Keeping the
//  moderation state in its own file means the two features can be built, tested and reviewed
//  without either member editing the other's file, which is the whole point of the lane map.
//  This file READS `GroupMessage`; it never changes it.
//
//  WHY HIDING IS A TOMBSTONE AND NOT A DELETION
//  -------------------------------------------
//  A deleted message leaves a hole that the next person to arrive reads as "something was said
//  here and removed", which is worse than the message. A tombstone says plainly that a moderator
//  removed it and why, so the room never silently loses its history and the decision is
//  accountable.
//

import Foundation

/// The permanent moderator of a group's chat.
///
/// Modelled as its own type rather than a flag on `GroupMember`, because permanence is the
/// defining property here and `GroupMember` is F09's type. `isSystemAdmin` is stored rather than
/// assumed so that a future non-admin moderator (a tutor, say) is expressible without a
/// migration.
struct GroupModerator: Identifiable, Equatable, Sendable, Codable {
    let id: String
    var displayName: String
    var isSystemAdmin: Bool

    init(id: String, displayName: String, isSystemAdmin: Bool = true) {
        self.id = id
        self.displayName = displayName
        self.isSystemAdmin = isSystemAdmin
    }
}

/// What a moderator can do to a message. N02's action sheet, in one enum.
enum ModerationActionKind: String, Sendable, Equatable, CaseIterable, Codable, Identifiable {
    /// Replace the body with a tombstone for everyone.
    case hide
    /// Remove the message outright.
    case delete
    /// Make it the group's single pinned announcement.
    case pin
    /// Raise it to the admin moderation queue without changing what members see.
    case flag

    var id: String { rawValue }

    // TODO(M5 · F16): Add the localised titles and the consequence sentence for each action,
    // with the other moderation copy, in the same commit that touches `Localizable.strings` for
    // both languages. Done when: `python3 tools/check-strings.py` still reports key parity.
}

/// Why a message was moderated. A short closed list, so the audit log is analysable rather than
/// a pile of free text, with `other` and a note for everything the list cannot name.
enum ModerationReason: String, Sendable, Equatable, CaseIterable, Codable, Identifiable {
    case spam
    case offTopic
    case unsafe
    case other

    var id: String { rawValue }
}

/// One recorded moderation action — the local mirror of the append-only `groups/{id}/moderation`
/// collection and the source of N06's audit row.
struct ModerationAction: Identifiable, Equatable, Sendable, Codable {
    let id: String
    let kind: ModerationActionKind
    let messageId: String
    let moderatorUid: String
    let reason: ModerationReason

    /// Free text for `other`, and the optional detail on any reason.
    let note: String?

    let at: Date

    init(
        id: String = UUID().uuidString,
        kind: ModerationActionKind,
        messageId: String,
        moderatorUid: String,
        reason: ModerationReason,
        note: String? = nil,
        at: Date = .now
    ) {
        self.id = id
        self.kind = kind
        self.messageId = messageId
        self.moderatorUid = moderatorUid
        self.reason = reason
        self.note = note
        self.at = at
    }
}

/// A moderation action that was refused, in the app's own vocabulary.
enum ModerationError: Error, Equatable {
    /// The person attempting the action is not the moderator.
    case notTheModerator
    /// A reason of `other` with no note explains nothing, so it is refused rather than stored.
    case reasonRequiresNote

    // TODO(M5 · F16): Map these to `AppError` with localised copy, in the same commit that adds
    // the moderation strings to both `Localizable.strings` files. Done when: the refusal on N02
    // renders in English and Arabic and `python3 tools/check-strings.py` still reports parity.
    //
    // Deliberately NOT mapped yet. `AppError` takes its user-facing reason as a String, so
    // mapping these without the keys would mean hard-coded English appearing inside an app that
    // ships Arabic — visible in the one place a learner is being told "no".
}

/// The moderation state of one group's chat.
///
/// Held separately from `StudyGroup` so F16 and F09 stay in their own lanes, and so the
/// moderation state can be read, tested and reasoned about without loading a whole group.
struct ChatModerationState: Equatable, Sendable, Codable {

    /// The permanent moderator. There is no initialiser that leaves this out, because a group
    /// chat without a moderator is precisely the state the feature exists to prevent.
    var moderator: GroupModerator

    /// Hidden message id to the reason it was hidden. Drives N03's tombstone.
    var hidden: [String: ModerationReason]

    /// The group's single pinned announcement (N04). One, not many: a board of pins is a
    /// noticeboard nobody reads.
    var pinnedMessageId: String?

    /// Every action taken, oldest first. The local mirror of the append-only moderation log.
    var actions: [ModerationAction]

    init(moderator: GroupModerator) {
        self.moderator = moderator
        self.hidden = [:]
        self.pinnedMessageId = nil
        self.actions = []
    }

    /// Whether a message is hidden, so the chat renders a tombstone rather than the body.
    func isHidden(_ messageId: String) -> Bool { hidden[messageId] != nil }

    /// Why a message was hidden, for the tombstone's reason line.
    func hiddenReason(for messageId: String) -> ModerationReason? { hidden[messageId] }

    /// The body a member sees, or `nil` when the message has been hidden.
    ///
    /// The single place that decides visibility, so no screen can accidentally render a hidden
    /// message by reading `message.text` directly.
    func visibleBody(of message: GroupMessage) -> String? {
        isHidden(message.id) ? nil : message.text
    }

    /// Records a moderation action and applies its visible effect.
    ///
    /// Throws rather than silently doing nothing when the caller is not the moderator: a
    /// moderation control that quietly fails is worse than one that is absent, because the
    /// moderator believes the message was dealt with.
    @discardableResult
    mutating func apply(
        _ kind: ModerationActionKind,
        to messageId: String,
        reason: ModerationReason,
        note: String? = nil,
        by uid: String,
        at now: Date = .now
    ) throws -> ModerationAction {
        guard ModerationPolicy.mayModerate(uid: uid, state: self) else {
            throw ModerationError.notTheModerator
        }

        let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        if ModerationPolicy.requiresNote(reason: reason), trimmed?.isEmpty != false {
            throw ModerationError.reasonRequiresNote
        }

        let action = ModerationAction(
            kind: kind,
            messageId: messageId,
            moderatorUid: uid,
            reason: reason,
            note: trimmed?.isEmpty == true ? nil : trimmed,
            at: now
        )

        switch kind {
        case .hide, .delete:
            hidden[messageId] = reason
        case .pin:
            pinnedMessageId = messageId
        case .flag:
            // Flagging changes nothing a member sees; it raises the message to the admin queue.
            break
        }

        actions.append(action)
        return action
    }
}

/// The moderation rules. Pure functions, so the one guarantee the feature makes — that the
/// moderator is always there — is stated in code and covered by a test rather than assumed.
enum ModerationPolicy {

    /// Whether the moderator may be removed from the group. **Never**, for anyone.
    ///
    /// Written as a function that returns `false` rather than left unstated so that the answer is
    /// visible to a reviewer and cannot be changed by accident in a view. The same guarantee is
    /// enforced server-side in `firestore.rules`, where a moderator member document refuses every
    /// update and delete — including by an admin, because an admin deleting the moderator is the
    /// one write that would break the promise silently.
    static func canRemoveModerator() -> Bool { false }

    /// Whether the moderator may be demoted to an ordinary member. **Never**, for the same
    /// reason as `canRemoveModerator`: a demotion is a removal with better manners.
    static func canDemoteModerator() -> Bool { false }

    /// Whether this person may moderate this chat.
    static func mayModerate(uid: String, state: ChatModerationState) -> Bool {
        uid == state.moderator.id
    }

    /// Whether a reason is too vague to stand on its own.
    ///
    /// `other` is the escape hatch, so it must say what it is escaping to. Every other reason
    /// carries its own meaning and may be used bare.
    static func requiresNote(reason: ModerationReason) -> Bool {
        reason == .other
    }

    // TODO(M5 · F16): Build the N01–N06 screens on top of this state — the presence banner, the
    // long-press action sheet, the reason sheet, the tombstone and the audit row — and extend
    // `GroupChatView`/`GroupChatViewModel` to render `visibleBody(of:)` rather than
    // `message.text`. Add the localisation keys in the same commit.
    // Done when: a hidden message renders as a tombstone, the reason is visible, and a test
    // drives hide then read-back through the view model.
}
