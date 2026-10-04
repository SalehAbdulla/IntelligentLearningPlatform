//
//  FileNotificationStore.swift
//  StudyForge
//
//  The on-device store for the inbox and the notification choices: two JSON files in Application
//  Support.
//
//  WHY TWO FILES AND NOT ONE
//  ------------------------
//  The inbox is a list that grows and gets trimmed; the choices are a single small record. Keeping
//  them apart means rewriting the inbox never touches the choices, so a crash mid-write cannot lose a
//  student's settings.
//

import Foundation

actor FileNotificationStore: NotificationStore {

    private let inboxURL: URL
    private let preferencesURL: URL

    /// Read once per launch, like the other file stores.
    private var inboxCache: [StudyNotification]?
    private var preferencesCache: NotificationPreferences?

    /// - Parameter directory: where to keep the files. Injected so a test can point at a temporary
    ///   directory rather than the real Application Support folder.
    init(directory: URL? = nil) {
        let base = directory ?? Self.defaultDirectory
        self.inboxURL = base.appendingPathComponent("notifications.json")
        self.preferencesURL = base.appendingPathComponent("notification-prefs.json")
    }

    // MARK: NotificationStore

    func all() async throws -> [StudyNotification] {
        try loadInbox().sorted { $0.createdAt > $1.createdAt }
    }

    func add(_ notification: StudyNotification) async throws {
        var notifications = try loadInbox()
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index] = notification
        } else {
            notifications.append(notification)
        }
        try persistInbox(notifications)
    }

    func markRead(id: String) async throws {
        var notifications = try loadInbox()
        guard let index = notifications.firstIndex(where: { $0.id == id }) else { return }
        notifications[index].isRead = true
        try persistInbox(notifications)
    }

    func markAllRead() async throws {
        var notifications = try loadInbox()
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        try persistInbox(notifications)
    }

    func delete(id: String) async throws {
        var notifications = try loadInbox()
        notifications.removeAll { $0.id == id }
        try persistInbox(notifications)
    }

    func preferences() async throws -> NotificationPreferences {
        if let preferencesCache { return preferencesCache }
        guard FileManager.default.fileExists(atPath: preferencesURL.path) else {
            preferencesCache = .default
            return .default
        }
        do {
            let data = try Data(contentsOf: preferencesURL)
            let decoded = try JSONDecoder().decode(NotificationPreferences.self, from: data)
            preferencesCache = decoded
            return decoded
        } catch {
            throw NotificationError.storageFailed
        }
    }

    func savePreferences(_ preferences: NotificationPreferences) async throws {
        do {
            try FileManager.default.createDirectory(
                at: preferencesURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(preferences)
            try data.write(to: preferencesURL, options: .atomic)
            preferencesCache = preferences
        } catch {
            throw NotificationError.storageFailed
        }
    }

    // MARK: Storage

    private func loadInbox() throws -> [StudyNotification] {
        if let inboxCache { return inboxCache }

        guard FileManager.default.fileExists(atPath: inboxURL.path) else {
            inboxCache = []
            return []
        }
        do {
            let data = try Data(contentsOf: inboxURL)
            let decoded = try JSONDecoder().decode([StudyNotification].self, from: data)
            inboxCache = decoded
            return decoded
        } catch {
            throw NotificationError.storageFailed
        }
    }

    private func persistInbox(_ notifications: [StudyNotification]) throws {
        do {
            try FileManager.default.createDirectory(
                at: inboxURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(notifications)
            try data.write(to: inboxURL, options: .atomic)
            inboxCache = notifications
        } catch {
            throw NotificationError.storageFailed
        }
    }

    /// Application Support, with a fallback.
    private static var defaultDirectory: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first
            .map { $0.appendingPathComponent("StudyForge", isDirectory: true) }
            ?? FileManager.default.temporaryDirectory
    }
}