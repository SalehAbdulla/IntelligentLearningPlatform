import Foundation

actor FileQuizAttemptLog: QuizAttemptLog {

    static let shared = FileQuizAttemptLog()

    private let fileURL: URL
    private var cache: [QuizAttemptRecord]?

    init(directory: URL? = nil) {
        let base = directory ?? Self.defaultDirectory
        self.fileURL = base.appendingPathComponent("quiz-attempts.json")
    }

    func records(forQuiz quizId: String) async throws -> [QuizAttemptRecord] {
        try load()
            .filter { $0.quizId == quizId }
            .sorted { $0.completedAt > $1.completedAt }
    }

    func record(id: String) async throws -> QuizAttemptRecord? {
        try load().first { $0.id == id }
    }

    func save(_ record: QuizAttemptRecord) async throws {
        var current = try load()
        current.removeAll { $0.id == record.id }
        current.append(record)
        try persist(current)
    }

    func removeRecords(forQuiz quizId: String) async throws {
        var current = try load()
        current.removeAll { $0.quizId == quizId }
        try persist(current)
    }

    private func load() throws -> [QuizAttemptRecord] {
        if let cache { return cache }
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            cache = []
            return []
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([QuizAttemptRecord].self, from: data)
            cache = decoded
            return decoded
        } catch {
            throw QuizError.storageFailed
        }
    }

    private func persist(_ records: [QuizAttemptRecord]) throws {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(records)
            try data.write(to: fileURL, options: .atomic)
            cache = records
        } catch {
            throw QuizError.storageFailed
        }
    }

    private static var defaultDirectory: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first
            .map { $0.appendingPathComponent("StudyForge", isDirectory: true) }
            ?? FileManager.default.temporaryDirectory
    }
}
