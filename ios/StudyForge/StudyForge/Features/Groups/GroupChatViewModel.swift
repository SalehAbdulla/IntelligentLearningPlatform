//
//  GroupChatViewModel.swift
//  StudyForge
//
//  Presentation logic for I11 (`91_GroupSpace_Chat_{M4}`) — the group's message list and input bar.
//
//  WHY SENDING RELOADS
//  -------------------
//  A message is appended to the group and the group rewritten, so the screen shows what was stored
//  rather than an optimistic copy that could disagree with the next launch. The cost is one read on
//  a local store; the benefit is one source of truth for the conversation.
//
//  WHY MODERATION IS AN OPTIONAL SEAM (F16)
//  ----------------------------------------
//  `ChatModerationState` cannot exist without a moderator (see `GroupModeration.swift`), so a chat
//  either has the group's moderator or it does not. I11 predates N01–N06, so the moderator and the
//  signed-in student's uid arrive as optional initialiser arguments with `nil` defaults: `nil` means
//  "this screen was opened without a moderation context", never "this group has no moderator". The
//  defaults are why I11's existing construction still compiles; a call site that passes them gets
//  the tombstones, the pin, the audit log and the controls with no other change.
//
//  WHY TWO IDENTITIES AND NOT ONE
//  ------------------------------
//  The group's moderator decides what is hidden, and every member's screen needs that answer to
//  draw a tombstone. The viewer's uid decides whether the CONTROLS appear. A classmate's screen
//  therefore passes a moderator and no viewer: correct tombstones, no controls.
//
//  WHY A REFUSAL IS NOT AN `AppError`
//  ----------------------------------
//  `ChatModerationError` deliberately has no `AppError` mapping yet (see the TODO beside it): the
//  refusal on N02 must read in English and Arabic, and hard-coded English would be worst in the one
//  place a learner is told "no". So the typed reason is exposed as `refusal` and the copy waits for
//  the keys. Store failures do map, via `ChatModerationStoreError.asAppError`, because a failed
//  write is our defect rather than a rule.
//
//  WHY A FAILED LOG READ DOES NOT BLANK THE CHAT
//  ---------------------------------------------
//  `moderationError` is separate from `error` on purpose. A chat whose audit log cannot be read is
//  still a readable chat; it is unmoderated, which is honest, rather than empty, which would be a
//  lie about the conversation.
//
//  WHY EACH ACTION RE-READS THE LOG
//  --------------------------------
//  `ChatModerationState.apply` already knows the visible effect, so mutating the held state would be
//  one line. But the log is the source of truth, so what the screen shows is always re-derived from
//  what the store accepted — the same reason `send()` reloads the group. A refusal or a failed
//  append therefore cannot leave the screen claiming a moderation that never landed.
//

import Foundation

@MainActor
@Observable
final class GroupChatViewModel {

    private(set) var state: LoadState<StudyGroup> = .idle
    private(set) var error: AppError?

    /// The message being typed.
    var draft = ""

    private(set) var isSending = false

    /// The group's moderation log, folded for reading.
    ///
    /// `nil` when this screen has no moderation context (see the header) or when the log has never
    /// been read — in both cases the chat renders exactly as I11 built it.
    private(set) var moderation: ChatModerationState?

    /// A moderation failure. Deliberately not `error`: a log that cannot be read must not blank the
    /// conversation.
    private(set) var moderationError: AppError?

    /// Why the last moderation action was refused, when it was. The copy for these arrives with the
    /// localisation commit; until then this at least separates a refusal from a store failure.
    private(set) var refusal: ChatModerationError?

    /// Whether a moderation action is in flight, so N02's sheet disables rather than appends twice.
    private(set) var isModerating = false

    private let groupId: String
    private let store: any GroupStore
    private let me: String

    /// The group's permanent moderator, when this screen was opened from moderation.
    private let moderator: GroupModerator?

    /// The signed-in student's uid, when known: decides `canModerate` and is stamped on each action.
    private let viewerId: String?

    private let moderationStore: any ChatModerationStore

    /// - Parameters:
    ///   - moderator: The group's permanent moderator, or `nil` when this screen has no moderation
    ///     context. Omitting it keeps I11's construction valid.
    ///   - viewerId: The signed-in student's uid. Without it nobody can moderate from this screen.
    ///   - moderationStore: Where the log is read and appended. Defaulted so that the screens which
    ///     pass no moderator need to know nothing about moderation storage.
    init(
        groupId: String,
        store: any GroupStore,
        me: String,
        moderator: GroupModerator? = nil,
        viewerId: String? = nil,
        moderationStore: any ChatModerationStore = InMemoryChatModerationStore()
    ) {
        self.groupId = groupId
        self.store = store
        self.me = me
        self.moderator = moderator
        self.viewerId = viewerId
        self.moderationStore = moderationStore
    }

    // MARK: Derived

    var group: StudyGroup? { state.value }

    /// Oldest first, which is how a conversation reads.
    var messages: [GroupMessage] {
        state.value?.messages.sorted { $0.sentAt < $1.sentAt } ?? []
    }

    var isEmpty: Bool { messages.isEmpty }
    var isLoading: Bool { state.isLoading }

    /// Whether the draft is worth sending — the send button's enablement.
    var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    // MARK: Copy

    var title: String { L10n.groupChatTitle.string }
    var placeholder: String { L10n.groupChatPlaceholder.string }
    var sendTitle: String { L10n.groupChatSend.string }
    var emptyTitle: String { L10n.groupChatEmpty.string }

    /// Whether a message was written by the student themselves — I11 draws their own lines
    /// differently from everyone else's.
    func isMine(_ message: GroupMessage) -> Bool { message.senderName == me }

    // MARK: Moderation — reading

    /// Whether this screen was opened with a moderation context, so N01's presence banner knows
    /// whether there is a moderator to announce.
    var isModerationAvailable: Bool { moderation != nil }

    /// Whether the student reading this chat is the group's moderator — N01's badge, N02's sheet.
    ///
    /// Asks `ModerationPolicy` rather than comparing names: the rule that decides who may moderate
    /// lives in one place, and a view model that re-implemented it could disagree with the store.
    var canModerate: Bool {
        guard let moderation, let viewerId else { return false }
        return ModerationPolicy.mayModerate(uid: viewerId, state: moderation)
    }

    /// The body a member sees, or `nil` when the message was hidden and N03's tombstone belongs in
    /// its place.
    ///
    /// The only way a view should read a message's text: reading `message.text` directly renders a
    /// body the room has removed. Without a moderation context this is the text unchanged, which is
    /// what I11 shows today.
    func visibleBody(of message: GroupMessage) -> String? {
        moderation?.visibleBody(of: message) ?? message.text
    }

    /// Whether a message is hidden, so the row can draw a tombstone instead of a bubble.
    func isHidden(_ message: GroupMessage) -> Bool {
        moderation?.isHidden(message.id) ?? false
    }

    /// Why a message was hidden — the tombstone's reason line.
    func hiddenReason(for message: GroupMessage) -> ModerationReason? {
        moderation?.hiddenReason(for: message.id)
    }

    /// The group's single pinned announcement (N04), resolved against the loaded messages so a pin
    /// for a message that is no longer in the group shows nothing rather than a dangling id.
    var pinnedMessage: GroupMessage? {
        guard let id = moderation?.pinnedMessageId else { return nil }
        return messages.first { $0.id == id }
    }

    /// Every action taken, oldest first — N06's audit row.
    var auditLog: [ModerationAction] { moderation?.actions ?? [] }

    // MARK: Moderation — acting

    /// Hides a message behind a tombstone for everyone.
    @discardableResult
    func hide(_ message: GroupMessage, reason: ModerationReason, note: String? = nil) async -> Bool {
        await moderate(.hide, message: message, reason: reason, note: note)
    }

    /// Removes a message outright. The log keeps the evidence; members see the tombstone.
    @discardableResult
    func delete(_ message: GroupMessage, reason: ModerationReason, note: String? = nil) async -> Bool {
        await moderate(.delete, message: message, reason: reason, note: note)
    }

    /// Makes a message the group's single pinned announcement, replacing any earlier pin.
    @discardableResult
    func pin(_ message: GroupMessage, reason: ModerationReason, note: String? = nil) async -> Bool {
        await moderate(.pin, message: message, reason: reason, note: note)
    }

    /// Raises a message to the admin queue without changing what members see.
    @discardableResult
    func flag(_ message: GroupMessage, reason: ModerationReason, note: String? = nil) async -> Bool {
        await moderate(.flag, message: message, reason: reason, note: note)
    }

    /// Records one action, then re-reads and re-folds the log.
    ///
    /// Returns whether the action landed. A refusal changes nothing and reports why through
    /// `refusal`; a store failure changes nothing and reports through `moderationError`.
    @discardableResult
    func moderate(
        _ kind: ModerationActionKind,
        message: GroupMessage,
        reason: ModerationReason,
        note: String? = nil
    ) async -> Bool {
        guard !isModerating, var working = moderation else { return false }
        guard let viewerId else {
            refusal = .notTheModerator
            return false
        }

        isModerating = true
        refusal = nil
        defer { isModerating = false }

        do {
            // Applied to a copy: a refusal must not half-apply to what the screen shows, and the
            // copy's own mutation is then discarded because the log is read back rather than
            // trusted.
            let action = try working.apply(
                kind, to: message.id, reason: reason, note: note, by: viewerId
            )
            try await moderationStore.append(action, to: groupId)
            let log = try await moderationStore.actions(for: groupId)
            moderation = .replaying(log, moderator: working.moderator)
            moderationError = nil
            return true
        } catch let refused as ChatModerationError {
            refusal = refused
            return false
        } catch ChatModerationStoreError.duplicateAction {
            // The action is already in the log, so the decision did land — the offline
            // re-submission in F16's edge cases arriving at a log it had already reached.
            // Reporting a storage fault would be a lie, so the log is re-read and the caller told
            // the message was dealt with.
            await reloadModeration()
            return moderationError == nil
        } catch let failure as ChatModerationStoreError {
            moderationError = failure.asAppError
            return false
        } catch {
            moderationError = AppError.from(error)
            return false
        }
    }

    // MARK: Actions

    func load() async {
        state = .loading
        do {
            guard let group = try await store.group(id: groupId) else {
                state = .empty
                return
            }
            state = .loaded(group)
        } catch {
            self.error = AppError.from(error)
            return
        }
        await reloadModeration()
    }

    /// Re-reads the moderation log and folds it.
    ///
    /// Silent when this screen has no moderation context: there is nothing to fold. Separate from
    /// `load()` so a failed log read can be retried without reloading the conversation, and on
    /// failure the last good fold is kept rather than replaced — a stale tombstone is still a true
    /// one, because nothing un-hides a message, while an invented one would be a guess.
    func reloadModeration() async {
        guard let moderator else {
            moderation = nil
            return
        }

        do {
            let log = try await moderationStore.actions(for: groupId)
            moderation = .replaying(log, moderator: moderator)
            moderationError = nil
        } catch let failure as ChatModerationStoreError {
            moderationError = failure.asAppError
        } catch {
            moderationError = AppError.from(error)
        }
    }

    func send() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }
        isSending = true
        defer { isSending = false }

        do {
            guard var group = try await store.group(id: groupId) else { return }
            group.messages.append(GroupMessage(senderName: me, text: text))
            group.updatedAt = .now
            try await store.add(group)
            draft = ""
            state = .loaded(group)
        } catch {
            self.error = AppError.from(error)
        }
    }
}
