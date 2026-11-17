import Foundation

struct QuizAttemptSummary: Identifiable, Equatable {
    let number: Int
    let result: QuizResult

    var id: String { result.attempt.id }
    var date: Date { result.attempt.createdAt }
}

@MainActor
@Observable
final class QuizAttemptsViewModel {

    static let chartLimit = 6

    private(set) var quiz: Quiz
    private(set) var attempts: [QuizAttemptSummary] = []
    private(set) var hasLoaded = false
    private(set) var error: AppError? = nil

    private let store: any QuizStore
    private let log: any QuizAttemptLog

    init(quiz: Quiz, store: any QuizStore, log: any QuizAttemptLog = InMemoryQuizAttemptLog()) {
        self.quiz = quiz
        self.store = store
        self.log = log
    }

    var chartPoints: [QuizAttemptSummary] {
        Array(attempts.prefix(Self.chartLimit).reversed())
    }

    var hasShortAnswers: Bool {
        quiz.questions.contains { QuizQuestionKind($0) == .shortAnswer }
    }

    var latest: QuizResult? { attempts.first?.result }

    func load() async {
        do {
            if let fresh = try await store.quiz(id: quiz.id) {
                quiz = fresh
            }
            let records = try await log.records(forQuiz: quiz.id)
            let byId = Dictionary(records.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            let total = quiz.attempts.count
            attempts = quiz.attempts.enumerated().map { index, attempt in
                QuizAttemptSummary(
                    number: total - index,
                    result: QuizResult(quiz: quiz, attempt: attempt, record: byId[attempt.id])
                )
            }
            error = nil
        } catch {
            self.error = AppError.from(error)
        }
        hasLoaded = true
    }
}
