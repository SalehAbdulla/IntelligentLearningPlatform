//
//  NotificationsInboxView.swift
//  StudyForge
//
//  M01 — `128_Notifications_Inbox_{M1}` (docs/03 §M, P0). The inbox, grouped by day, with type icons,
//  unread dots and swipe-to-mark-read.
//

import SwiftUI

// Accessibility: each row is one element whose value carries "unread", with the type icon and the unread
// dot hidden as decorative, and the empty state is a single statement.

struct NotificationsInboxView: View {

    @State private var viewModel: NotificationsInboxViewModel

    init(store: any NotificationStore, plans: any StudyPlanStore) {
        _viewModel = State(initialValue: NotificationsInboxViewModel(store: store, plans: plans))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
                    .padding(Layout.screenMargin)
            } else if viewModel.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.hasUnread {
                ToolbarItem(placement: .primaryAction) {
                    Button(viewModel.markAllReadTitle) {
                        Task { await viewModel.markAllRead() }
                    }
                }
            }
        }
        .task { await viewModel.load() }
    }

    private var list: some View {
        List {
            ForEach(viewModel.sections) { section in
                Section(section.title) {
                    ForEach(section.items) { notification in
                        row(notification)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func row(_ notification: StudyNotification) -> some View {
        HStack(alignment: .top, spacing: Spacing.s3) {
            Image(systemName: notification.kind.symbolName)
                .font(.sfBody)
                .foregroundStyle(ColorTokens.primary)
                .frame(minWidth: Spacing.s6, alignment: .leading)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.s1) {
                HStack(spacing: Spacing.s2) {
                    Text(notification.title)
                        .font(.sfBodyEmph)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .lineLimit(2)

                    // The dot is decorative; the row's accessibility value carries "unread" instead,
                    // so VoiceOver does not announce a shape.
                    if !notification.isRead {
                        Circle()
                            .fill(ColorTokens.primary)
                            .frame(width: Spacing.s2, height: Spacing.s2)
                            .accessibilityHidden(true)
                    }
                }

                Text(notification.body)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(notification.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textTertiary)
            }

            Spacer(minLength: Spacing.s2)
        }
        .padding(.vertical, Spacing.s2)
        .opacity(notification.isRead ? 0.6 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(notification.title)
        .accessibilityValue(
            notification.isRead ? notification.body : "\(viewModel.unreadTitle(1)). \(notification.body)"
        )
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task { await viewModel.delete(notification) }
            } label: {
                Label(L10n.commonDelete.string, systemImage: "trash")
            }

            if !notification.isRead {
                Button {
                    Task { await viewModel.markRead(notification) }
                } label: {
                    Label(L10n.notificationMarkRead.string, systemImage: "envelope.open")
                }
                .tint(ColorTokens.primary)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(viewModel.emptyTitle)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)
            Text(viewModel.emptyBody)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Layout.screenMargin)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Previews

#Preview("M01 Notifications inbox") {
    NavigationStack {
        NotificationsInboxView(
            store: InMemoryNotificationStore(seededWith: [
                StudyNotification(
                    kind: .studyReminder,
                    title: "Databases — normalisation",
                    body: "18:00 — 45 min. Open your plan to start.",
                    target: .plan
                ),
                StudyNotification(
                    kind: .achievement,
                    title: "Five-day streak",
                    body: "You have studied every day this week.",
                    target: .progress,
                    isRead: true,
                    createdAt: .now.addingTimeInterval(-86_400)
                ),
            ]),
            plans: InMemoryStudyPlanStore()
        )
    }
}