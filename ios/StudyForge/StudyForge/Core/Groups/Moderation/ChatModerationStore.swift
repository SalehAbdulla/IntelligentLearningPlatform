//
//  ChatModerationStore.swift
//  StudyForge
//
//  F16 — where a group's moderation history lives, and the fold that turns it back into what the
//  chat shows (docs/03 §N, N02–N06).
//
//  WHY THE LOG *IS* THE STATE
//  --------------------------
//  N06 requires an append-only audit row for every action and N03 requires the chat to know which
//  messages are hidden and why. Those are the same fact stated twice: a message is hidden BECAUSE a
//  hide action was recorded. Keeping a mutable `hidden` map beside the log would give the app two
//  sources of truth that can disagree after a half-failed write — the tombstone on screen, no audit
//  row behind it — so the store exposes exactly two verbs, read the log and append to it, and
//  `ChatModerationState.replaying` derives what the screen shows. Rewriting history is then not
//  merely discouraged: it is not expressible through this seam.
//
//  WHY NOT ON `GroupStore` / `StudyGroup`
//  -------------------------------------
//  `StudyGroup` is F09's type in M4's lane, and `groups/{id}/moderation` is its own collection in
//  `firestore.rules` with its own write rule. Growing the group model would put moderation in a lane
//  that does not own it, and every screen that reads a group would carry a log it never looks at.
//
//  WHY APPENDING THE SAME ACTION TWICE IS AN ERROR
//  ----------------------------------------------
//  An id already in the log means a caller re-submitted an action that had already landed — the
//  offline path in F16's edge cases (an action taken with no connection, resolved on reconnect).
//  Absorbing it silently would hide that bug; appending it would record one decision twice in an
//  append-only log that is supposed to be evidence. So it is refused, with its own case, and the
//  caller decides whether to ignore it or surface it.
//

import Foundation

/// Reads and appends a group's moderation log.
protocol ChatModerationStore: Sendable {

    /// Every action recorded in one group, oldest first.
    ///
    /// A group that has never been moderated returns an empty array rather than throwing: an empty
    /// log is the normal state of a well-behaved chat, not a failure worth reporting.
    func actions(for groupId: String) async throws -> [ModerationAction]

    /// Records one action against a group. Appending is the only write this store offers.
    func append(_ action: ModerationAction, to groupId: String) async throws
}

/// Failures from the moderation log, in the app's own vocabulary.
enum ChatModerationStoreError: Error, Equatable {

    /// The local store could not be read or written.
    case storageFailed

    /// The action id is already in the log. See the header.
    case duplicateAction

    /// Maps to the app's single user-facing error type.
    ///
    /// Applied by the chat view model rather than by `AppError.from`, because `AppError` is shared
    /// state-layer code outside F16's lane — the same arrangement `RecallSettingsError` uses.
    /// `duplicateAction` maps to `.unknown` rather than to a storage error: nothing failed to save;
    /// the caller tried to write one moderation decision twice, and telling the learner the server
    /// is unreachable would be a lie about what happened.
    var asAppError: AppError {
        switch self {
        case .storageFailed:
            .server(reference: "chat-moderation-store-failed")
        case .duplicateAction:
            .unknown
        }
    }
}

// MARK: - Replaying the log

extension ChatModerationState {

    /// Rebuilds what a group's chat shows from its append-only log.
    ///
    /// `actions` is sorted here rather than trusted as given, because an action taken offline is
    /// stamped when it was taken, not when it reached the store: replaying in arrival order would
    /// let a late-arriving hide be undone by a pin that was recorded before it.
    static func replaying(
        _ actions: [ModerationAction],
        moderator: GroupModerator
    ) -> ChatModerationState {
        var state = ChatModerationState(moderator: moderator)
        let ordered = actions.sorted(by: isOlder)

        for action in ordered {
            switch action.kind {
            case .hide, .delete:
                state.hidden[action.messageId] = action.reason
            case .pin:
                state.pinnedMessageId = action.messageId
            case .flag:
                // Flagging is deliberately invisible to members: it raises the message to the
                // admin queue and changes nothing the room sees.
                break
            }
        }

        state.actions = ordered
        return state
    }

    /// The audit log's order: oldest first.
    ///
    /// The id breaks ties so two actions stamped in the same instant replay in the same order on
    /// every launch; without it the log would be stable only by accident of the sort algorithm.
    static func isOlder(_ lhs: ModerationAction, _ rhs: ModerationAction) -> Bool {
        if lhs.at != rhs.at { return lhs.at < rhs.at }
        return lhs.id < rhs.id
    }
}
