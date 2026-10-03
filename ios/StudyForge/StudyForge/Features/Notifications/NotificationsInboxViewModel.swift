//
//  NotificationsInboxViewModel.swift
//  StudyForge
//
//  Presentation logic for M01 (`128_Notifications_Inbox_{M1}`) — the inbox, grouped by day.
//
//  WHY IT SYNCS THE PLAN BEFORE IT READS
//  -------------------------------------
//  Opening the inbox is the one moment the student is asking "what should I be reminded of?", so it
//  is where the plan's reminders are folded in. The planner's ids are stable (see
//  `NotificationReminderPlanner`), so syncing is idempotent: the same session can be folded in on
//  every open and still produce one row.
//
//  WHY THE SECTIONS ARE BUILT HERE
//  -------------------------------
//  "Today / Yesterday / Earlier" is a presentation decision, and putting it in the view would mean a
//  `DateFormatter` in a view body whose output no test can check. Here it is one function with one
//  answer.
//

import Foundation

/// One day-group of the inbox.
struct NotificationSection: Identifiable, Equatable {
    let id: String
    let title: String
    let items: [StudyNotification]
}

@MainActor
@Observable
final class NotificationsInboxViewModel {

    private(set) var state: LoadState<[StudyNotification]> = .idle
    private(set) var error: AppError?

    private let store: any NotificationStore
    private let plans: any StudyPlanStore

    init(store: any NotificationStore, plans: any StudyPlanStore) {
        self.store = store
        self.plans = plans
    }

    // MARK: Derived

    var notifications: [StudyNotification] { state.value ?? [] }
    var isEmpty: Bool { if case .empty = state { return true }; return false }
    var isLoading: Bool { state.isLoading }
    var unreadCount: Int { notifications.filter { !$0.isRead }.count }
    var hasUnread: Bool { unreadCount > 0 }

    /// The inbox grouped by day, newest group first and newest item first within it.
    var sections: [NotificationSection] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        var todayItems: [StudyNotification] = []
        var yesterdayItems: [StudyNotification] = []
        var earlierItems: [StudyNotification] = []

        for notification in notifications {
            let day = calendar.startOfDay(for: notification.createdAt)
            if day >= today {
                todayItems.append(notification)
            } else if day == yesterday {
                yesterdayItems.append(notification)
            } else {
                earlierItems.append(notification)
            }
        }

        return [
            NotificationSection(id: "today", title: todayTitle, items: todayItems),
            NotificationSection(id: "yesterday", title: yesterdayTitle, items: yesterdayItems),
            NotificationSection(id: "earlier", title: earlierTitle, items: earlierItems),
        ]
        .filter { !$0.items.isEmpty }
    }

    // MARK: Copy

    var title: String { L10n.notificationInboxTitle.string }
    var emptyTitle: String { L10n.notificationEmptyTitle.string }
    var emptyBody: String { L10n.notificationEmptyBody.string }
    var markAllReadTitle: String { L10n.notificationMarkAllRead.string }
    var todayTitle: String { L10n.notificationToday.string }
    var yesterdayTitle: String { L10n.notificationYesterday.string }
    var earlierTitle: String { L10n.notificationEarlier.string }

    func unreadTitle(_ count: Int) -> String { L10n.notificationUnread.string(count) }

    // MARK: Loading

    func load() async {
        state = .loading
        error = nil
        do {
            await syncPlanReminders()
            let all = try await store.all()
            state = all.isEmpty ? .empty : .loaded(all)
        } catch {
            state = .failed(AppError.from(error))
        }
    }

    /// Folds the plan's reminders into the inbox. Idempotent, because a reminder's id is derived from
    /// its session.
    private func syncPlanReminders() async {
        guard let plan = try? await plans.all().first else { return }
        guard let preferences = try? await store.preferences() else { return }
        for reminder in NotificationReminderPlanner.reminders(for: plan, preferences: preferences) {
            try? await store.add(reminder)
        }
    }

    // MARK: Actions

    func markRead(_ notification: StudyNotification) async {
        guard !notification.isRead else { return }
        do {
            try await store.markRead(id: notification.id)
            await reload()
        } catch {
            self.error = AppError.from(error)
        }
    }

    func markAllRead() async {
        do {
            try await store.markAllRead()
            await reload()
        } catch {
            self.error = AppError.from(error)
        }
    }

    func delete(_ notification: StudyNotification) async {
        do {
            try await store.delete(id: notification.id)
            await reload()
        } catch {
            self.error = AppError.from(error)
        }
    }

    /// Re-reads without re-syncing, so a read/delete does not fold the plan in again.
    private func reload() async {
        do {
            let all = try await store.all()
            state = all.isEmpty ? .empty : .loaded(all)
        } catch {
            self.error = AppError.from(error)
        }
    }
}