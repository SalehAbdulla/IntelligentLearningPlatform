//
//  InMemoryNotificationStore.swift
//  StudyForge
//
//  A `NotificationStore` that keeps everything in memory — previews and tests.
//
//  A REAL conformance rather than a stub, mirroring `InMemoryFolderStore`, so a screen driven by it
//  behaves exactly as it does against the file store.
//

import Foundation

actor InMemoryNotificationStore: NotificationStore {

    private var notifications: [StudyNotification]
    private var storedPreferences: NotificationPreferences

    /// When set, every call fails with it until cleared.
    private var failure: NotificationError?

    init(
        seededWith notifications: [StudyNotification] = [],
        preferences: NotificationPreferences = .default
    ) {
        self.notifications = notifications
        self.storedPreferences = preferences
    }

    // MARK: NotificationStore

    func all() async throws -> [StudyNotification] {
        try failIfForced()
        return notifications.sorted { $0.createdAt > $1.createdAt }
    }

    func add(_ notification: StudyNotification) async throws {
        try failIfForced()
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index] = notification
        } else {
            notifications.append(notification)
        }
    }

    func markRead(id: String) async throws {
        try failIfForced()
        guard let index = notifications.firstIndex(where: { $0.id == id }) else { return }
        notifications[index].isRead = true
    }

    func markAllRead() async throws {
        try failIfForced()
        for index in notifications.indices {
            notifications[index].isRead = true
        }
    }

    func delete(id: String) async throws {
        try failIfForced()
        notifications.removeAll { $0.id == id }
    }

    func preferences() async throws -> NotificationPreferences {
        try failIfForced()
        return storedPreferences
    }

    func savePreferences(_ preferences: NotificationPreferences) async throws {
        try failIfForced()
        storedPreferences = preferences
    }

    // MARK: Test and preview controls

    /// Forces every call to fail with `error`. Pass `nil` to restore success.
    func forceFailure(_ error: NotificationError?) {
        failure = error
    }

    private func failIfForced() throws {
        if let failure { throw failure }
    }
}