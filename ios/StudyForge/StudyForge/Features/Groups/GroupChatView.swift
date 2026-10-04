//
//  GroupChatView.swift
//  StudyForge
//
//  I11 — `91_GroupSpace_Chat_{M4}` (docs/03 §I, P1). The group's message list with sender avatars and
//  an input bar.
//

import SwiftUI

struct GroupChatView: View {

    @State private var viewModel: GroupChatViewModel

    init(groupId: String, store: any GroupStore, me: String) {
        _viewModel = State(initialValue: GroupChatViewModel(groupId: groupId, store: store, me: me))
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
    }

    private var conversation: some View {
        VStack(spacing: 0) {
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
                    // A sent message should be visible without the student scrolling for it.
                    if let last = viewModel.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            inputBar
        }
    }

    private func messageRow(_ message: GroupMessage) -> some View {
        HStack(alignment: .top, spacing: Spacing.s3) {
            if viewModel.isMine(message) { Spacer(minLength: Spacing.s10) }

            if !viewModel.isMine(message) {
                Image(systemName: "person.circle.fill")
                    .font(.sfTitleM)
                    .foregroundStyle(ColorTokens.primary)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: Spacing.s1) {
                if !viewModel.isMine(message) {
                    Text(message.senderName)
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
                Text(message.text)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(message.sentAt.formatted(date: .omitted, time: .shortened))
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textTertiary)
            }
            .padding(Spacing.s3)
            .background(
                viewModel.isMine(message) ? ColorTokens.primaryContainer : ColorTokens.surfaceVariant,
                in: .rect(cornerRadius: Radius.m)
            )

            if !viewModel.isMine(message) { Spacer(minLength: Spacing.s10) }
        }
        .id(message.id)
        .accessibilityElement(children: .combine)
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