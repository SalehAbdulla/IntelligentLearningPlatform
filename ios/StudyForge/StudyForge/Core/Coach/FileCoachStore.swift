//
//  FileCoachStore.swift
//  StudyForge
//
//  The on-device store for coach conversations and ratings: one JSON file in Application Support.
//
//  NOTE ON THE RATE-DERIVED VECTORS
//  --------------------------------
//  The retrieval index is deliberately NOT persisted here. Vectors are derived from the student's
//  material, and docs/05 §2 keeps them on-device while the chunks sync; rebuilding them from the
//  library at launch is cheap and cannot go stale against a material the student has since edited.
//

import Foundation

actor FileCoachStore: CoachStore {

    /// The persisted shape: conversations and their ratings in one file — see `CoachStore` for why.
    private struct Database: Codable {
        var threads: [String: CoachThread] = [:]
        var feedback: [AnswerFeedback] = []
    }

    private let fileURL: URL

    /// The database once read. `nil` until then, so the file is touched at most once per launch.
    private var cache: Database?

    /// - Parameter directory: where to keep the file. Injected so a test can point at a temporary
    ///   directory rather than the real Application Support folder.
    init(directory: URL? = nil) {
        let base = directory ?? Self.defaultDirectory
        self.fileURL = base.appendingPathComponent("coach.json")
    }

    // MARK: CoachStore

    func threads() async throws -> [CoachThread] {
        try load().threads.values.sorted { $0.updatedAt > $1.updatedAt }
    }

    func thread(id: String) async throws -> CoachThread? {
        try load().threads[id]
    }

    func upsert(_ thread: CoachThread) async throws {
        var database = try load()
        database.threads[thread.id] = thread
        try persist(database)
    }

    func deleteThread(id: String) async throws {
        var database = try load()
        database.threads[id] = nil
        database.feedback.removeAll { $0.threadId == id }
        try persist(database)
    }

    func feedback() async throws -> [AnswerFeedback] {
        try load().feedback.sorted { $0.createdAt > $1.createdAt }
    }

    func record(_ feedback: AnswerFeedback) async throws {
        var database = try load()
        database.feedback.removeAll { $0.messageId == feedback.messageId }
        database.feedback.append(feedback)
        try persist(database)
    }

    // MARK: Storage

    private func load() throws -> Database {
        if let cache { return cache }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            let empty = Database()
            cache = empty
            return empty
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode(Database.self, from: data)
            cache = decoded
            return decoded
        } catch {
            throw CoachStoreError.storageFailed
        }
    }

    private func persist(_ database: Database) throws {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(database)
            try data.write(to: fileURL, options: .atomic)
            cache = database
        } catch {
            throw CoachStoreError.storageFailed
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
