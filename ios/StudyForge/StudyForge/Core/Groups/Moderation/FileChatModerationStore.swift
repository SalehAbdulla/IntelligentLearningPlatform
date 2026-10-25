//
//  FileChatModerationStore.swift
//  StudyForge
//
//  The on-device moderation log: one JSON file in Application Support.
//
//  WHY ONE FILE FOR EVERY GROUP
//  ----------------------------
//  The remote shape is `groups/{id}/moderation`, one collection per group. Locally the whole log is
//  a few kilobytes — a moderated message is a rare event — and keeping it in one document means one
//  atomic write per action instead of one file per group to create, prune and reconcile. The group
//  id stays as the key inside the file, so moving to per-group documents behind this protocol later
//  is a change to this file alone.
//
//  WHY A FILE AND NOT USERDEFAULTS
//  ------------------------------
//  A moderation decision is accountability evidence, not a UI preference: it has to survive
//  reinstalls long enough to be inspected, and it has to round-trip in a test without a device,
//  exactly as `FileDeckStore` and `FileRecallSettingsStore` do.
//
//  WHY A CORRUPT FILE IS NEVER REPLACED
//  -----------------------------------
//  An unreadable log could be read as "this group was never moderated", which is the one claim an
//  audit trail must never make by accident. So a decode failure is surfaced, and because `append`
//  reads before it writes, the broken file is left exactly as it was for a human to look at.
//
//  `actor`, because it owns mutable state (the cached log) and file IO must not run on the main
//  actor.
//

import Foundation

actor FileChatModerationStore: ChatModerationStore {

    private let fileURL: URL

    /// The log once read. `nil` until then, so the file is touched at most once per launch.
    private var cache: [String: [ModerationAction]]?

    /// - Parameter directory: where to keep the file. Injected so a test can point at a temporary
    ///   directory rather than the real Application Support folder.
    init(directory: URL? = nil) {
        let base = directory ?? Self.defaultDirectory
        self.fileURL = base.appendingPathComponent("chatModeration.json")
    }

    // MARK: ChatModerationStore

    func actions(for groupId: String) async throws -> [ModerationAction] {
        let stored = try load()
        return (stored[groupId] ?? []).sorted(by: ChatModerationState.isOlder)
    }

    func append(_ action: ModerationAction, to groupId: String) async throws {
        var stored = try load()

        var actions = stored[groupId] ?? []
        guard !actions.contains(where: { $0.id == action.id }) else {
            throw ChatModerationStoreError.duplicateAction
        }

        actions.append(action)
        stored[groupId] = actions
        try write(stored)
    }

    // MARK: Storage

    /// The whole log, read once and then cached.
    private func load() throws -> [String: [ModerationAction]] {
        if let cache { return cache }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            // No file yet: no group has been moderated on this device, which is the normal state
            // of a healthy chat and not a failure.
            cache = [:]
            return [:]
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([String: [ModerationAction]].self, from: data)
            cache = decoded
            return decoded
        } catch {
            throw ChatModerationStoreError.storageFailed
        }
    }

    private func write(_ stored: [String: [ModerationAction]]) throws {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            // Sorted keys so the file diffs cleanly when a reviewer inspects two states of it.
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(stored)
            try data.write(to: fileURL, options: .atomic)
            cache = stored
        } catch {
            throw ChatModerationStoreError.storageFailed
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
