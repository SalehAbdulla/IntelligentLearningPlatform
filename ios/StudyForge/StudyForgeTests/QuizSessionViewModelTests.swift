import Foundation
import Testing
@testable import StudyForge

@MainActor
final class QuizTestClock {
    var now = Date(timeIntervalSince1970: 1_000_000)

    func advance(_ seconds: TimeInterval) {
        now = now.addingTimeInterval(seconds)
    }
}

@Suite("Quiz session (F05)")
@MainActor
struct QuizSessionViewModelTests {

    private func question(_ id: String, topic: String = "Traversal", options: [String] = ["Right", "Wrong 1", "Wrong 2", "Wrong 3"]) -> QuizQuestion {
        QuizQuestion(
            id: id,
            stem: "Question \(id)",
            options: options,
            correctOptionIndex: 0,
            explanation: "Explained on page 4.",
            topic: topic,
            provenance: AIProvenance(materialId: "m", pageNumbers: [4], confidence: .high)
        )
    }

    private func quiz(timer: Int? = nil, questions: [QuizQuestion]? = nil) -> Quiz {
        Quiz(
            id: "quiz",
            title: "Trees quiz 1",
            questionType: .mixed,
            questions: questions ?? [
                question("q1"),
                question("q2", topic: "Balancing"),
                question("q3", topic: "Basics", options: ["Rotations"])
            ],
            timerMinutes: timer
        )
    }

    private func session(
        _ quiz: Quiz,
        questions: [QuizQuestion]? = nil,
        store: InMemoryQuizStore = InMemoryQuizStore(),
        log: InMemoryQuizAttemptLog = InMemoryQuizAttemptLog(),
        drafts: InMemoryQuizDraftStore = InMemoryQuizDraftStore(),
        plans: (any StudyPlanStore)? = nil,
        clock: QuizTestClock = QuizTestClock()
    ) -> QuizSessionViewModel {
        QuizSessionViewModel(
            quiz: quiz,
            questions: questions,
            store: store,
            log: log,
            drafts: drafts,
            plans: plans,
            clock: { clock.now }
        )
    }

    @Test("A session opens on the first question")
    func opensOnFirst() {
        let viewModel = session(quiz())

        #expect(viewModel.phase == .answering)
        #expect(viewModel.currentQuestion?.id == "q1")
        #expect(viewModel.progressText == QuizCopy.progress(1, 3))
        #expect(!viewModel.isTimed)
        #expect(!viewModel.canCheck)
    }

    @Test("Choosing an option waits for Next before marking it")
    func chooseThenCheck() {
        let viewModel = session(quiz())

        viewModel.choose(2)
        #expect(viewModel.phase == .answering)
        #expect(viewModel.pendingOption == 2)
        #expect(viewModel.canCheck)

        viewModel.choose(0)
        viewModel.check()

        #expect(viewModel.phase == .feedback)
        #expect(viewModel.currentOutcome == .correct)
        #expect(viewModel.currentResponse?.selectedOptionIndex == 0)
    }

    @Test("A wrong option is marked incorrect with the right answer kept")
    func wrongAnswer() {
        let viewModel = session(quiz())

        viewModel.select(3)

        #expect(viewModel.currentOutcome == .incorrect)
        #expect(viewModel.currentResponse?.isCorrect == false)
        #expect(viewModel.answeredCount == 1)
    }

    @Test("A typed short answer is marked with full, half or no credit")
    func typedAnswer() async {
        let viewModel = session(quiz())
        viewModel.go(to: 2)
        #expect(viewModel.currentKind == .shortAnswer)

        viewModel.draftAnswer = "   "
        #expect(!viewModel.canCheck)

        viewModel.draftAnswer = "rotations"
        viewModel.check()

        #expect(viewModel.phase == .feedback)
        #expect(viewModel.currentCredit == .full)
        #expect(viewModel.typedAnswers["q3"] == "rotations")
        #expect(viewModel.currentOutcome == .correct)
    }

    @Test("Skipping moves on and leaves the question unanswered")
    func skipLeavesUnanswered() async {
        let viewModel = session(quiz())

        await viewModel.skip()

        #expect(viewModel.currentIndex == 1)
        #expect(viewModel.unansweredNumbers == [1, 2, 3])
    }

    @Test("Next moves to the following question")
    func nextAdvances() async {
        let viewModel = session(quiz())
        viewModel.select(0)

        await viewModel.next()

        #expect(viewModel.currentIndex == 1)
        #expect(viewModel.phase == .answering)
        #expect(viewModel.pendingOption == nil)
    }

    @Test("Flags can be set and cleared")
    func flags() {
        let viewModel = session(quiz())
        let first = viewModel.questions[0]

        viewModel.toggleFlag()
        #expect(viewModel.isFlagged(first))
        viewModel.toggleFlag()
        #expect(!viewModel.isFlagged(first))
    }

    @Test("Submitting with gaps asks first and can jump to the first gap")
    func submitAsksWithGaps() async {
        let viewModel = session(quiz())
        viewModel.select(0)
        await viewModel.next()

        await viewModel.requestSubmit()
        #expect(viewModel.isConfirmingSubmit)
        #expect(viewModel.unansweredNumbers == [2, 3])

        viewModel.reviewUnanswered()
        #expect(!viewModel.isConfirmingSubmit)
        #expect(viewModel.currentIndex == 1)
        #expect(viewModel.phase == .answering)
    }

    @Test("Answering every question finishes without asking")
    func finishesWhenComplete() async throws {
        let store = InMemoryQuizStore()
        let log = InMemoryQuizAttemptLog()
        let viewModel = session(quiz(), store: store, log: log)

        viewModel.select(0)
        await viewModel.next()
        viewModel.select(1)
        await viewModel.next()
        viewModel.draftAnswer = "rotate"
        viewModel.check()
        await viewModel.next()

        #expect(viewModel.phase == .finished)
        #expect(!viewModel.isConfirmingSubmit)
        let result = try #require(viewModel.result)
        #expect(result.total == 3)
        #expect(result.earned == 1)
        #expect(try await store.quiz(id: "quiz")?.attempts.count == 1)
        #expect(try await log.records(forQuiz: "quiz").first?.typedAnswers["q3"] == "rotate")
    }

    @Test("Confirming a submit with gaps records the gaps as skipped")
    func confirmRecordsSkips() async throws {
        let store = InMemoryQuizStore()
        let viewModel = session(quiz(), store: store)
        viewModel.select(0)

        await viewModel.requestSubmit()
        await viewModel.confirmSubmit()

        let attempt = try #require(try await store.quiz(id: "quiz")?.latestAttempt)
        #expect(attempt.responses.map(\.questionId) == ["q1", "q2", "q3"])
        #expect(attempt.responses.map(\.selectedOptionIndex) == [0, nil, nil])
        #expect(viewModel.result?.outcome(for: viewModel.questions[1]) == .skipped)
    }

    @Test("The record keeps the time taken and the flags")
    func recordKeepsTimeAndFlags() async throws {
        let clock = QuizTestClock()
        let log = InMemoryQuizAttemptLog()
        let viewModel = session(quiz(), log: log, clock: clock)
        viewModel.toggleFlag()
        clock.advance(125)

        await viewModel.requestSubmit()
        await viewModel.confirmSubmit()

        let record = try #require(try await log.records(forQuiz: "quiz").first)
        #expect(record.durationSeconds == 125)
        #expect(record.flaggedQuestionIds == ["q1"])
        #expect(record.questionIds == ["q1", "q2", "q3"])
        #expect(!record.timedOut)
    }
}
