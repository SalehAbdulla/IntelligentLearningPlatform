//
//  FileQuizStore.swift
//  StudyForge
//
//  The on-device store for quizzes: one JSON file in Application Support.
//
//  WHY A FILE AND NOT FIRESTORE
//  ----------------------------
//  Quizzes must be takeable offline, and they are derived from material that never leaves the
//  device. The file is the local half; Firestore's `quizzes/{id}` collection is what a future sync
//  swaps in behind this protocol.
//

import Foundation

actor FileQuizStore: QuizStore {

    private let fileURL: URL

    /// The quizzes once read. `nil` until then, so the file is touched at most once per launch.
    private var cache: [Quiz]?

    /// - Parameter directory: where to keep the file. Injected so a test can point at a temporary
    ///   directory rather than the real Application Support folder.
    init(directory: URL? = nil) {
        let base = directory ?? Self.defaultDirectory
        self.fileURL = base.appendingPathComponent("quizzes.json")
    }

    // MARK: QuizStore

    func all() async throws -> [Quiz] {
        try load().sorted { $0.createdAt > $1.createdAt }
    }

    func quiz(id: String) async throws -> Quiz? {
        try load().first { $0.id == id }
    }

    func add(_ quiz: Quiz) async throws {
        var quizzes = try load()
        if let index = quizzes.firstIndex(where: { $0.id == quiz.id }) {
            quizzes[index] = quiz
        } else {
            quizzes.append(quiz)
        }
        try persist(quizzes)
    }

    func delete(id: String) async throws {
        var quizzes = try load()
        quizzes.removeAll { $0.id == id }
        try persist(quizzes)
    }

    // MARK: Storage

    private func load() throws -> [Quiz] {
        if let cache { return cache }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            cache = []
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([Quiz].self, from: data)
            cache = decoded
            return decoded
        } catch {
            throw QuizError.storageFailed
        }
    }

    private func persist(_ quizzes: [Quiz]) throws {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(quizzes)
            try data.write(to: fileURL, options: .atomic)
            cache = quizzes
        } catch {
            throw QuizError.storageFailed
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
