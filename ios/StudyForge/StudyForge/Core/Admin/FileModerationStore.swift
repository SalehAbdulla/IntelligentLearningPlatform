//
//  FileModerationStore.swift
//  StudyForge
//
//  The on-device store for the moderation queue: one JSON file in Application Support.
//
//  WHY A FILE AND NOT FIRESTORE, YET
//  ---------------------------------
//  docs/05 section 2.1 defines `reports/{id}` as admin-only, and a real queue is a server query this
//  device cannot make on another person's behalf. The file is the stand-in that keeps K04 demonstrable
//  before a backend exists; the protocol is the seam the real query swaps in behind.
//

import Foundation

actor FileModerationStore: ModerationStore {

    private let fileURL: URL

    /// Read once per launch, like the other file stores.
    private var cache: [ContentReport]?

    /// - Parameter directory: where to keep the file. Injected so a test can point at a temporary
    ///   directory rather than the real Application Support folder.
    init(directory: URL? = nil) {
        let base = directory ?? Self.defaultDirectory
        self.fileURL = base.appendingPathComponent("moderation.json")
    }

    // MARK: ModerationStore

    func reports() async throws -> [ContentReport] {
        try load().sorted { $0.reportedAt > $1.reportedAt }
    }

    func report(id: String) async throws -> ContentReport? {
        try load().first { $0.id == id }
    }

    func save(_ report: ContentReport) async throws {
        var reports = try load()
        if let index = reports.firstIndex(where: { $0.id == report.id }) {
            reports[index] = report
        } else {
            reports.append(report)
        }
        try persist(reports)
    }

    // MARK: Storage

    private func load() throws -> [ContentReport] {
        if let cache { return cache }
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            cache = []
            return []
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([ContentReport].self, from: data)
            cache = decoded
            return decoded
        } catch {
            throw AdminError.storageFailed
        }
    }

    private func persist(_ reports: [ContentReport]) throws {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(reports)
            try data.write(to: fileURL, options: .atomic)
            cache = reports
        } catch {
            throw AdminError.storageFailed
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
