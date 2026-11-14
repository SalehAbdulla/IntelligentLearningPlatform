//
//  GroupChatView.swift
//  StudyForge
//
//  I11 — `91_GroupSpace_Chat_{M4}` (docs/03 §I, P1). The group's message list with sender avatars and
//  an input bar.
//
//  F16 extends it (docs/03 §N): N01's moderator banner above the conversation, N03's tombstone in
//  place of a hidden body, and N02's moderation sheet on a long press. The extension is written so
//  that I11's construction — `GroupChatView(groupId:store:me:)` — still compiles and still renders
//  exactly what it did: without a moderation context there is no banner, no sheet and no
//  tombstone, because `GroupChatViewModel.moderation` is `nil`. See that file's header for why the
//  two identities (the group's moderator, and the viewer) are separate arguments.
//
//  WHY THE ROW ASKS THE VIEW MODEL FOR THE BODY
//  --------------------------------------------
//  `Text(message.text)` would render a body the room has removed, because the message in the store
//  is never deleted — that is the whole point of a tombstone. Every row therefore reads
//  `visibleBody(of:)`, which is the only sanctioned accessor and returns `nil` for a hidden
//  message.
//

import SwiftUI

// Accessibility: each message row reads as one element and the send button is labelled; the scroll to a new
// message answers to Reduce Motion.

struct GroupChatView: View {

    @State private var viewModel: GroupChatViewModel

    /// The message whose moderation sheet is open. Held as the message rather than an id so the
    /// sheet can quote the line without looking it up in a list that may have reloaded.
    @State private var moderationTarget: GroupMessage?

    /// The scroll-to-newest on send is a motion, so it is the one thing here that answers to Reduce
    /// Motion: with it on, the list jumps to the newest message instead of gliding to it.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - moderator: the group's permanent moderator. Omit it and this is I11's chat unchanged.
    ///   - viewerId: the signed-in student's uid. Without it nobody can moderate from here, which is
    ///     how a member sees the same tombstones without the controls.
    ///   - moderationStore: where the audit log is read and appended.
    ///
    /// The default is the ON-DEVICE log, not the in-memory double. A moderation decision is
    /// accountability evidence: it has to survive the app being closed, or the audit trail N06
    /// promises exists only until the next launch. `FileChatModerationStore` already implements that
    /// — one append-only JSON file in Application Support — and it is F16's own file, so no shared
    /// file or another member's work is involved. Previews and tests still pass
    /// `InMemoryChatModerationStore`, so neither touches the disk.
    ///
    /// One store instance is created per chat screen and captured by the view model for the life of
    /// that screen; the store reads before it writes, so a second screen opened later sees the first
    /// screen's decisions. The chat is a single-writer surface (one conversation on screen at a
    /// time), which is what keeps a per-instance cache safe here.
    init(
        groupId: String,
        store: any GroupStore,
        me: String,
        moderator: GroupModerator? = nil,
        viewerId: String? = nil,
        moderationStore: any ChatModerationStore = FileChatModerationStore()
    ) {
        _viewModel = State(initialValue: GroupChatViewModel(
            groupId: groupId,
            store: store,
            me: me,
            moderator: moderator,
            viewerId: viewerId,
            moderationStore: moderationStore
        ))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
                    .padding(Layout.screenMargin)
            } else {
                conversation
            }
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        // N02. Presented as a sheet rather than a `confirmationDialog` because each action has to
        // name its own consequence, and a system dialog has nowhere to put that line.
        .sheet(item: $moderationTarget) { message in
            ModerationSheet(
                message: message,
                quotedText: viewModel.visibleBody(of: message),
                error: viewModel.moderationError,
                onApply: { kind, reason, note in
                    await viewModel.moderate(kind, message: message, reason: reason, note: note)
                }
            )
        }
    }

    private var conversation: some View {
        VStack(spacing: 0) {
            // N01 — the permanent moderator, above the conversation on every load rather than
            // folded into a member list, because "always in this space" is the claim being made.
            if let moderator = viewModel.moderation?.moderator {
                ModeratorPresenceBanner(moderator: moderator)
            }

            // A failed audit-log read must not blank the conversation (see the view model), so it
            // is reported here, above the list, with a retry that reloads only the log.
            if let moderationError = viewModel.moderationError {
                SFErrorBanner(
                    error: moderationError,
                    onRecover: { Task { await viewModel.reloadModeration() } }
                )
                .padding(.horizontal, Layout.screenMargin)
                .padding(.top, Spacing.s2)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.s3) {
                        if viewModel.isEmpty {
                            Text(viewModel.emptyTitle)
                                .font(.sfCallout)
                                .foregroundStyle(ColorTokens.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(Layout.screenMargin)
                        } else {
                            ForEach(viewModel.messages) { message in
                                messageRow(message)
                            }
                        }
                    }
                    .padding(Layout.screenMargin)
                    .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
                    .frame(maxWidth: .infinity)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    // A sent message should be visible without the student scrolling for it. The scroll
                    // is animated only when Reduce Motion is off; with it on, jumping to the newest
                    // message is the point, and the glide is not.
                    if let last = viewModel.messages.last {
                        withAnimation(reduceMotion ? nil : Motion.quick) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            inputBar
        }
    }

    private func messageRow(_ message: GroupMessage) -> some View {
        let isMine = viewModel.isMine(message)
        let isHidden = viewModel.isHidden(message)

        return HStack(alignment: .top, spacing: Spacing.s3) {
            if isMine { Spacer(minLength: Spacing.s10) }

            if !isMine {
                Image(systemName: "person.circle.fill")
                    .font(.sfTitleM)
                    .foregroundStyle(ColorTokens.primary)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: Spacing.s1) {
                if !isMine {
                    Text(message.senderName)
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.textSecondary)
                }

                if isHidden {
                    // N03. The body is never rendered — not greyed out, not blurred — and the
                    // reason comes from the log rather than from the message.
                    HiddenMessageTombstone(
                        reason: viewModel.hiddenReason(for: message) ?? .other,
                        moderatorName: moderationAuthor(for: message),
                        at: moderationDate(for: message)
                    )
                } else if let body = viewModel.visibleBody(of: message) {
                    Text(body)
                        .font(.sfCallout)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(message.sentAt.formatted(date: .omitted, time: .shortened))
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.textTertiary)
                }
            }
            // The tombstone draws its own bordered surface, so the bubble is skipped rather than
            // wrapped around it — two nested backgrounds would read as one muddy block.
            .padding(isHidden ? 0 : Spacing.s3)
            .background {
                if !isHidden {
                    RoundedRectangle(cornerRadius: Radius.m)
                        .fill(isMine ? ColorTokens.primaryContainer : ColorTokens.surfaceVariant)
                }
            }

            if !isMine { Spacer(minLength: Spacing.s10) }
        }
        .id(message.id)
        .accessibilityElement(children: .combine)
        // N02's entry point. A context menu rather than a visible control keeps the conversation
        // readable for everyone else; it appears only for the group's moderator.
        .contextMenu {
            if viewModel.canModerate {
                moderationMenu(for: message)
            }
        }
    }

    /// N02's four actions, minus the ones that would be a no-op on this message.
    ///
    /// `hide` is omitted on an already-hidden message: the log is append-only, so repeating it
    /// would add a second audit row that says nothing new.
    @ViewBuilder
    private func moderationMenu(for message: GroupMessage) -> some View {
        ForEach(availableActions(for: message)) { kind in
            Button(role: kind == .delete ? .destructive : nil) {
                moderationTarget = message
            } label: {
                Label(kind.title, systemImage: kind.symbolName)
            }
        }
    }

    private func availableActions(for message: GroupMessage) -> [ModerationActionKind] {
        let hidden = viewModel.isHidden(message)
        return ModerationActionKind.allCases.filter { !(hidden && $0 == .hide) }
    }

    /// Who hid the message, read from the log. `nil` when this screen has not folded a decision yet
    /// — a tombstone with no name is better than one naming the wrong moderator.
    private func moderationAuthor(for message: GroupMessage) -> String? {
        guard viewModel.isHidden(message) else { return nil }
        return viewModel.moderation?.moderator.displayName
    }

    /// When it was hidden, from the most recent hide or delete of this message.
    private func moderationDate(for message: GroupMessage) -> Date? {
        viewModel.auditLog
            .last { $0.messageId == message.id && ($0.kind == .hide || $0.kind == .delete) }?
            .at
    }

    private var inputBar: some View {
        HStack(spacing: Spacing.s3) {
            TextField(viewModel.placeholder, text: $viewModel.draft, axis: .vertical)
                .font(.sfCallout)
                .lineLimit(1...4)
                .padding(Spacing.s3)
                .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))

            Button {
                Task { await viewModel.send() }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.sfBody)
                    .foregroundStyle(viewModel.canSend ? ColorTokens.primary : ColorTokens.textTertiary)
                    .frame(minWidth: Layout.minTouchTarget, minHeight: Layout.minTouchTarget)
            }
            .disabled(!viewModel.canSend)
            .accessibilityLabel(viewModel.sendTitle)
        }
        .padding(Layout.screenMargin)
        .background(ColorTokens.surface)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}

// MARK: - Previews

#Preview("F16 Moderated chat") {
    NavigationStack {
        GroupChatView(
            groupId: "g1",
            store: InMemoryGroupStore(seededWith: [
                StudyGroup(
                    id: "g1",
                    name: "Database revision",
                    members: [GroupMember(name: "Sara Ali", isOwner: true)],
                    messages: [
                        GroupMessage(id: "m1", senderName: "Omar",
                                     text: "Anyone free at 6 for normalisation?"),
                        GroupMessage(id: "m2", senderName: "Ali",
                                     text: "Free answers in the pinned doc, DM me."),
                        GroupMessage(id: "m3", senderName: "Sara Ali",
                                     text: "Yes — I'll bring my cards."),
                    ]
                ),
            ]),
            me: "Sara Ali",
            moderator: GroupModerator(id: "admin-1", displayName: "Fatema Ghareeb"),
            viewerId: "admin-1",
            moderationStore: InMemoryChatModerationStore(seededWith: [
                "g1": [
                    ModerationAction(
                        kind: .hide,
                        messageId: "m2",
                        moderatorUid: "admin-1",
                        reason: .spam
                    ),
                ],
            ])
        )
    }
}

#Preview("I11 Group chat") {

    NavigationStack {
        GroupChatView(
            groupId: "g1",
            store: InMemoryGroupStore(seededWith: [
                StudyGroup(
                    id: "g1",
                    name: "Database revision",
                    members: [GroupMember(name: "Sara Ali", isOwner: true)],
                    messages: [
                        GroupMessage(senderName: "Omar", text: "Anyone free at 6 for normalisation?"),
                        GroupMessage(senderName: "Sara Ali", text: "Yes — I'll bring my cards."),
                    ]
                ),
            ]),
            me: "Sara Ali"
        )
    }
}