import Foundation
import Testing
@testable import StudyForge

@Suite("Quizzes home and attempt history (F05)")
@MainActor
struct QuizzesHomeViewModelTests {

    private func question(_ id: String, topic: String) -> QuizQuestion {
        QuizQuestion(
            id: id,
            stem: "Question \(id)",
            options: ["Right", "Wrong 1", "Wrong 2", "Wrong 3"],
            correctOptionIndex: 0,
            explanation: "Explained.",
            topic: topic,
            provenance: AIProvenance(materialId: "m", pageNumbers: [1], confidence: .high)
        )
    }

    private func attempt(_ id: String, correct: [Bool], at seconds: TimeInterval) -> QuizAttempt {
        QuizAttempt(
            id: id,
            responses: correct.enumerated().map { index, isCorrect in
                QuizResponse(questionId: "q\(index + 1)", selectedOptionIndex: isCorrect ? 0 : 1, isCorrect: isCorrect)
            },
            createdAt: Date(timeIntervalSince1970: seconds)
        )
    }

    private func quiz(_ id: String, attempts: [QuizAttempt] = [], createdAt seconds: TimeInterval = 0) -> Quiz {
        Quiz(
            id: id,
            title: "Quiz \(id)",
            questionType: .multipleChoice,
            questions: [question("q1", topic: "AVL"), question("q2", topic: "Traversal"), question("q3", topic: "AVL")],
            attempts: attempts,
            createdAt: Date(timeIntervalSince1970: seconds)
        )
    }

    @Test("Quizzes are listed by most recent activity with their latest score")
    func listsByActivity() async {
        let old = quiz("old", attempts: [attempt("a1", correct: [true, true, true], at: 50)], createdAt: 10)
        let fresh = quiz("fresh", createdAt: 100)
        let viewModel = QuizzesHomeViewModel(store: InMemoryQuizStore(seededWith: [old, fresh]))

        await viewModel.load()

        #expect(viewModel.rows.map(\.id) == ["fresh", "old"])
        #expect(viewModel.rows[0].latest == nil)
        #expect(viewModel.rows[1].latest?.percent == 100)
    }

    @Test("Missed topics come from the latest attempt")
    func missedTopics() async {
        let taken = quiz("t", attempts: [
            attempt("a2", correct: [false, false, true], at: 20),
            attempt("a1", correct: [true, true, true], at: 10)
        ])
        let viewModel = QuizzesHomeViewModel(store: InMemoryQuizStore(seededWith: [taken]))

        await viewModel.load()

        #expect(viewModel.rows.first?.missedTopics == ["AVL", "Traversal"])
        #expect(viewModel.rows.first?.attemptCount == 2)
    }

    @Test("The latest score uses half credit from the attempt log")
    func usesLogCredit() async {
        let taken = quiz("t", attempts: [attempt("a1", correct: [true, false, false], at: 10)])
        let log = InMemoryQuizAttemptLog(seededWith: [
            QuizAttemptRecord(id: "a1", quizId: "t", questionIds: ["q1", "q2", "q3"], durationSeconds: 60, credits: ["q2": .half])
        ])
        let viewModel = QuizzesHomeViewModel(store: InMemoryQuizStore(seededWith: [taken]), log: log)

        await viewModel.load()

        #expect(viewModel.rows.first?.latest?.earned == 1.5)
    }

    @Test("A quiz with a saved draft is marked to resume")
    func draftMarked() async throws {
        let drafts = InMemoryQuizDraftStore()
        try await drafts.save(QuizDraft(
            quizId: "t",
            questionIds: ["q1", "q2", "q3"],
            responses: [],
            typedAnswers: [:],
            credits: [:],
            flaggedQuestionIds: [],
            currentIndex: 0,
            deadline: nil,
            elapsedSeconds: 0,
            savedAt: .now
        ))
        let viewModel = QuizzesHomeViewModel(store: InMemoryQuizStore(seededWith: [quiz("t")]), drafts: drafts)

        await viewModel.load()

        #expect(viewModel.rows.first?.hasDraft == true)
    }

    @Test("An empty store shows the empty state")
    func emptyState() async {
        let viewModel = QuizzesHomeViewModel(store: InMemoryQuizStore())

        await viewModel.load()

        #expect(viewModel.isEmpty)
    }

    @Test("A failed load is shown as an error, not as empty")
    func loadFailure() async {
        let store = InMemoryQuizStore()
        await store.forceFailure(.storageFailed)
        let viewModel = QuizzesHomeViewModel(store: store)

        await viewModel.load()

        #expect(viewModel.error != nil)
        #expect(!viewModel.isEmpty)
    }

    @Test("Deleting a quiz removes its records and draft too")
    func deleteCleansUp() async throws {
        let store = InMemoryQuizStore(seededWith: [quiz("t", attempts: [attempt("a1", correct: [true, true, true], at: 1)])])
        let log = InMemoryQuizAttemptLog(seededWith: [
            QuizAttemptRecord(id: "a1", quizId: "t", questionIds: ["q1"], durationSeconds: 5)
        ])
        let viewModel = QuizzesHomeViewModel(store: store, log: log)
        await viewModel.load()

        await viewModel.delete(viewModel.rows[0].quiz)

        #expect(viewModel.rows.isEmpty)
        #expect(try await store.all().isEmpty)
        #expect(try await log.records(forQuiz: "t").isEmpty)
    }

    @Test("The history numbers attempts and charts the newest six oldest first")
    func attemptHistory() async {
        let attempts = (0..<8).map { attempt("a\($0)", correct: [true, $0 % 2 == 0, false], at: TimeInterval(100 - $0)) }
        let taken = quiz("t", attempts: attempts)
        let viewModel = QuizAttemptsViewModel(quiz: taken, store: InMemoryQuizStore(seededWith: [taken]))

        await viewModel.load()

        #expect(viewModel.attempts.map(\.number) == [8, 7, 6, 5, 4, 3, 2, 1])
        #expect(viewModel.chartPoints.map(\.number) == [3, 4, 5, 6, 7, 8])
        #expect(viewModel.latest?.attempt.id == "a0")
        #expect(!viewModel.hasShortAnswers)
    }
}
