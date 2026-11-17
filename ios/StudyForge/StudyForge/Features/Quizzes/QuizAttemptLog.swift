import Foundation

struct QuizAttemptRecord: Identifiable, Equatable, Sendable, Codable {
    let id: String
    let quizId: String
    var questionIds: [String]
    var durationSeconds: Int
    var flaggedQuestionIds: [String]
    var typedAnswers: [String: String]
    var credits: [String: QuizCredit]
    var timedOut: Bool
    let completedAt: Date

    init(
        id: String,
        quizId: String,
        questionIds: [String],
        durationSeconds: Int,
        flaggedQuestionIds: [String] = [],
        typedAnswers: [String: String] = [:],
        credits: [String: QuizCredit] = [:],
        timedOut: Bool = false,
        completedAt: Date = .now
    ) {
        self.id = id
        self.quizId = quizId
        self.questionIds = questionIds
        self.durationSeconds = durationSeconds
        self.flaggedQuestionIds = flaggedQuestionIds
        self.typedAnswers = typedAnswers
        self.credits = credits
        self.timedOut = timedOut
        self.completedAt = completedAt
    }
}

protocol QuizAttemptLog: Sendable {
    func records(forQuiz quizId: String) async throws -> [QuizAttemptRecord]
    func record(id: String) async throws -> QuizAttemptRecord?
    func save(_ record: QuizAttemptRecord) async throws
    func removeRecords(forQuiz quizId: String) async throws
}
