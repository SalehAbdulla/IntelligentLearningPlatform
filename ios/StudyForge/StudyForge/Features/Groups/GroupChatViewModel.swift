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

import Foundation

@MainActor
@Observable
final class GroupChatViewModel {

    private(set) var state: LoadState<StudyGroup> = .idle
    private(set) var error: AppError?

    /// The message being typed.
    var draft = ""

    private(set) var isSending = false

    private let groupId: String
    private let store: any GroupStore
    private let me: String

    init(groupId: String, store: any GroupStore, me: String) {
        self.groupId = groupId
        self.store = store
        self.me = me
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