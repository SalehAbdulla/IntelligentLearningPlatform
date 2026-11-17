import Foundation

struct QuizSummaryRow: Identifiable, Equatable {
    let quiz: Quiz
    let latest: QuizResult?
    let hasDraft: Bool

    var id: String { quiz.id }
    var attemptCount: Int { quiz.attempts.count }
    var missedTopics: [String] { latest?.missedTopics ?? [] }
    var lastActivity: Date { quiz.latestAttempt?.createdAt ?? quiz.createdAt }
    var questionCount: Int { quiz.questions.count }
}

@MainActor
@Observable
final class QuizzesHomeViewModel {

    private(set) var rows: [QuizSummaryRow] = []
    private(set) var hasLoaded = false
    private(set) var error: AppError? = nil

    private let store: any QuizStore
    private let log: any QuizAttemptLog
    private let drafts: any QuizDraftStore

    init(
        store: any QuizStore,
        log: any QuizAttemptLog = InMemoryQuizAttemptLog(),
        drafts: any QuizDraftStore = InMemoryQuizDraftStore()
    ) {
        self.store = store
        self.log = log
        self.drafts = drafts
    }

    var isEmpty: Bool { hasLoaded && rows.isEmpty && error == nil }

    func load() async {
        do {
            let quizzes = try await store.all()
            let draftIds = await drafts.draftQuizIds()
            var built: [QuizSummaryRow] = []
            for quiz in quizzes {
                var latest: QuizResult?
                if let attempt = quiz.latestAttempt {
                    let record = try? await log.record(id: attempt.id)
                    latest = QuizResult(quiz: quiz, attempt: attempt, record: record)
                }
                built.append(QuizSummaryRow(quiz: quiz, latest: latest, hasDraft: draftIds.contains(quiz.id)))
            }
            rows = built.sorted { $0.lastActivity > $1.lastActivity }
            error = nil
        } catch {
            self.error = AppError.from(error)
        }
        hasLoaded = true
    }

    func delete(_ quiz: Quiz) async {
        do {
            try await store.delete(id: quiz.id)
            try? await log.removeRecords(forQuiz: quiz.id)
            await drafts.clear(quizId: quiz.id)
            rows.removeAll { $0.id == quiz.id }
        } catch {
            self.error = AppError.from(error)
        }
    }

    func quiz(id: String) async -> Quiz? {
        try? await store.quiz(id: id)
    }
}
