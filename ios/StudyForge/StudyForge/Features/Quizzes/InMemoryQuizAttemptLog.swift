import Foundation

actor InMemoryQuizAttemptLog: QuizAttemptLog {

    private var stored: [QuizAttemptRecord]
    private var failure: QuizError?

    init(seededWith records: [QuizAttemptRecord] = []) {
        self.stored = records
    }

    func records(forQuiz quizId: String) async throws -> [QuizAttemptRecord] {
        try failIfForced()
        return stored
            .filter { $0.quizId == quizId }
            .sorted { $0.completedAt > $1.completedAt }
    }

    func record(id: String) async throws -> QuizAttemptRecord? {
        try failIfForced()
        return stored.first { $0.id == id }
    }

    func save(_ record: QuizAttemptRecord) async throws {
        try failIfForced()
        stored.removeAll { $0.id == record.id }
        stored.append(record)
    }

    func removeRecords(forQuiz quizId: String) async throws {
        try failIfForced()
        stored.removeAll { $0.quizId == quizId }
    }

    func forceFailure(_ error: QuizError?) {
        failure = error
    }

    private func failIfForced() throws {
        if let failure { throw failure }
    }
}
