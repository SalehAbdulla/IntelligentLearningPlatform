//
//  FileSummaryStore.swift
//  StudyForge
//
//  The on-device store for saved summaries: one JSON file in Application Support.
//
//  WHY A FILE AND NOT FIRESTORE
//  ----------------------------
//  A summary is derived from material that never leaves the device, so its durable home is the
//  device too. Firestore's `summaries/{id}` collection exists in the data model for the day the
//  "only summaries sync" promise goes live — this file is the local half that keeps that change
//  a swap of the store, not a rewrite of every screen.
//
//  `actor`, for two reasons: it owns mutable state (the loaded summaries), and file IO must not
//  run on the main actor.
//

import Foundation

actor FileSummaryStore: SummaryStore {

    private let fileURL: URL

    /// The summaries once read. `nil` until then, so the file is touched at most once per launch.
    private var cache: [Summary]?

    /// - Parameter directory: where to keep the file. Injected so a test can point at a temporary
    ///   directory rather than the real Application Support folder.
    init(directory: URL? = nil) {
        let base = directory ?? Self.defaultDirectory
        self.fileURL = base.appendingPathComponent("summaries.json")
    }

    // MARK: SummaryStore

    func all() async throws -> [Summary] {
        try load().sorted { $0.createdAt > $1.createdAt }
    }

    func summary(id: String) async throws -> Summary? {
        try load().first { $0.id == id }
    }

    func add(_ summary: Summary) async throws {
        var summaries = try load()
        if let index = summaries.firstIndex(where: { $0.id == summary.id }) {
            summaries[index] = summary
        } else {
            summaries.append(summary)
        }
        try persist(summaries)
    }

    func delete(id: String) async throws {
        var summaries = try load()
        summaries.removeAll { $0.id == id }
        try persist(summaries)
    }

    // MARK: Storage

    private func load() throws -> [Summary] {
        if let cache { return cache }

        // No file is not a failure: it is a student who has not saved a summary yet.
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            cache = []
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([Summary].self, from: data)
            cache = decoded
            return decoded
        } catch {
            throw SummaryError.storageFailed
        }
    }

    private func persist(_ summaries: [Summary]) throws {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(summaries)
            // `.atomic`: an interrupted write must not leave a half-written file behind.
            try data.write(to: fileURL, options: .atomic)
            cache = summaries
        } catch {
            throw SummaryError.storageFailed
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
