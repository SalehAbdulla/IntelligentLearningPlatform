//
//  FileRecallSettingsStore.swift
//  StudyForge
//
//  The on-device store for F17's options: one JSON file in Application Support.
//
//  WHY A FILE AND NOT USERDEFAULTS
//  -------------------------------
//  These values are the learner's study configuration, not a UI preference: losing them mid-term
//  silently changes how many cards they see a day. A file can be backed up, inspected and — the
//  point here — round-tripped in a test without a device, exactly as `FileDeckStore` does.
//  Firestore's `recallSettings/{uid}` document is what a future sync swaps in behind the protocol.
//
//  `actor`, because it owns mutable state (the cached document) and file IO must not run on the
//  main actor.
//

import Foundation

actor FileRecallSettingsStore: RecallSettingsStore {

    private let fileURL: URL

    /// The settings once read. `nil` until then, so the file is touched at most once per launch.
    private var cache: RecallSettings?

    /// - Parameter directory: where to keep the file. Injected so a test can point at a temporary
    ///   directory rather than the real Application Support folder.
    init(directory: URL? = nil) {
        let base = directory ?? Self.defaultDirectory
        self.fileURL = base.appendingPathComponent("recallSettings.json")
    }

    // MARK: RecallSettingsStore

    func settings() async throws -> RecallSettings {
        if let cache { return cache }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            // First run: no document is a normal state, and the learner sees Anki's defaults.
            cache = RecallSettings.default
            return RecallSettings.default
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode(RecallSettings.self, from: data)
            cache = decoded
            return decoded
        } catch {
            // Deliberately NOT a silent reset to `.default`: quietly replacing a learner's
            // ceilings because a file was truncated would look like the app ignoring their
            // choices. A corrupt document is surfaced so the screen can say so.
            throw RecallSettingsError.storageFailed
        }
    }

    func save(_ settings: RecallSettings) async throws {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(settings)
            try data.write(to: fileURL, options: .atomic)
            cache = settings
        } catch {
            throw RecallSettingsError.storageFailed
        }
    }

    // MARK: Storage

    /// Application Support, with a fallback.
    private static var defaultDirectory: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first
            .map { $0.appendingPathComponent("StudyForge", isDirectory: true) }
            ?? FileManager.default.temporaryDirectory
    }
}
