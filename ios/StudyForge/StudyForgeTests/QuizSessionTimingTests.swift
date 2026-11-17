import Foundation
import Testing
@testable import StudyForge

@Suite("Quiz session timing, resume and revision (F05)")
@MainActor
struct QuizSessionTimingTests {

    private func question(_ id: String, topic: String = "Traversal") -> QuizQuestion {
        QuizQuestion(
            id: id,
            stem: "Question \(id)",
            options: ["Right", "Wrong 1", "Wrong 2", "Wrong 3"],
            correctOptionIndex: 0,
            explanation: "Explained.",
            topic: topic,
            provenance: AIProvenance(materialId: "m", pageNumbers: [], confidence: .low)
        )
    }

    private func quiz(timer: Int? = 1) -> Quiz {
        Quiz(
            id: "quiz",
            title: "Trees quiz 1",
            questionType: .multipleChoice,
            questions: [question("q1"), question("q2", topic: "Balancing"), question("q3", topic: "Balancing")],
            timerMinutes: timer
        )
    }

    @Test("A timed quiz counts down from its minutes")
    func countsDown() async {
        let clock = QuizTestClock()
        let viewModel = QuizSessionViewModel(quiz: quiz(), store: InMemoryQuizStore(), clock: { clock.now })

        #expect(viewModel.isTimed)
        #expect(viewModel.timeText == "01:00")
        #expect(viewModel.isRunningLow)

        clock.advance(28)
        await viewModel.tick()
        #expect(viewModel.remainingSeconds == 32)
        #expect(viewModel.timeText == "00:32")
    }

    @Test("When time runs out the quiz submits itself")
    func autoSubmits() async throws {
        let clock = QuizTestClock()
        let store = InMemoryQuizStore()
        let log = InMemoryQuizAttemptLog()
        let viewModel = QuizSessionViewModel(quiz: quiz(), store: store, log: log, clock: { clock.now })
        viewModel.select(0)

        clock.advance(61)
        await viewModel.tick()

        #expect(viewModel.phase == .finished)
        #expect(viewModel.timedOut)
        #expect(viewModel.remainingSeconds == 0)
        #expect(try await log.records(forQuiz: "quiz").first?.timedOut == true)
        #expect(try await store.quiz(id: "quiz")?.attempts.count == 1)
    }

    @Test("Time keeps running while the app is in the background")
    func backgroundCountsAgainstTime() async {
        let clock = QuizTestClock()
        let drafts = InMemoryQuizDraftStore()
        let first = QuizSessionViewModel(quiz: quiz(), store: InMemoryQuizStore(), drafts: drafts, clock: { clock.now })
        first.select(0)
        await first.pause()

        clock.advance(90)
        let resumed = QuizSessionViewModel(quiz: quiz(), store: InMemoryQuizStore(), drafts: drafts, clock: { clock.now })
        await resumed.resume()

        #expect(resumed.phase == .finished)
        #expect(resumed.timedOut)
    }

    @Test("Leaving and coming back resumes the same answers and question")
    func resumesDraft() async {
        let clock = QuizTestClock()
        let drafts = InMemoryQuizDraftStore()
        let first = QuizSessionViewModel(quiz: quiz(timer: nil), store: InMemoryQuizStore(), drafts: drafts, clock: { clock.now })
        first.select(2)
        await first.next()
        first.toggleFlag()
        clock.advance(40)
        await first.pause()

        let resumed = QuizSessionViewModel(quiz: quiz(timer: nil), store: InMemoryQuizStore(), drafts: drafts, clock: { clock.now })
        await resumed.resume()

        #expect(resumed.currentIndex == 1)
        #expect(resumed.phase == .answering)
        #expect(resumed.responses["q1"]?.selectedOptionIndex == 2)
        #expect(resumed.isFlagged(resumed.questions[1]))
        clock.advance(20)
        #expect(resumed.elapsedSeconds == 60)
    }

    @Test("Submitting clears the saved draft")
    func submitClearsDraft() async {
        let drafts = InMemoryQuizDraftStore()
        let viewModel = QuizSessionViewModel(quiz: quiz(timer: nil), store: InMemoryQuizStore(), drafts: drafts)
        viewModel.select(0)
        await viewModel.pause()
        #expect(await drafts.draft(forQuiz: "quiz") != nil)

        await viewModel.requestSubmit()
        await viewModel.confirmSubmit()

        #expect(await drafts.draft(forQuiz: "quiz") == nil)
    }

    @Test("A weak-topics retake only asks the weak questions and ignores the full draft")
    func weakRetake() async {
        let full = quiz(timer: nil)
        let drafts = InMemoryQuizDraftStore()
        let first = QuizSessionViewModel(quiz: full, store: InMemoryQuizStore(), drafts: drafts)
        first.select(1)
        await first.pause()

        let weak = Array(full.questions.suffix(2))
        let retake = QuizSessionViewModel(quiz: full, questions: weak, store: InMemoryQuizStore(), drafts: drafts)
        await retake.resume()

        #expect(retake.isWeakTopicRetake)
        #expect(retake.questions.map(\.id) == ["q2", "q3"])
        #expect(retake.responses.isEmpty)
    }

    @Test("A wrong answer can be added to the revision plan once")
    func addsToRevisionPlan() async throws {
        let plans = InMemoryStudyPlanStore()
        let viewModel = QuizSessionViewModel(quiz: quiz(timer: nil), store: InMemoryQuizStore(), plans: plans)
        viewModel.select(1)
        #expect(viewModel.canAddToPlan)

        await viewModel.addToRevisionPlan()
        await viewModel.addToRevisionPlan()

        let stored = try await plans.all()
        #expect(stored.count == 1)
        #expect(stored.first?.sessions.map(\.subject) == [QuizCopy.revisionSubject("Traversal")])
        #expect(viewModel.isInRevisionPlan(viewModel.questions[0]))
    }

    @Test("Revision sessions join the newest existing plan")
    func joinsExistingPlan() async throws {
        let existing = StudyPlan(
            input: StudyPlanInput(subjects: ["Trees"], weeklyHours: 4, intensity: .balanced),
            sessions: []
        )
        let plans = InMemoryStudyPlanStore(seededWith: [existing])
        let viewModel = QuizSessionViewModel(quiz: quiz(timer: nil), store: InMemoryQuizStore(), plans: plans)
        viewModel.select(1)

        await viewModel.addToRevisionPlan()

        let stored = try await plans.all()
        #expect(stored.count == 1)
        #expect(stored.first?.id == existing.id)
        #expect(stored.first?.sessions.count == 1)
    }

    @Test("Low-confidence questions are flagged and cite the source when there is no page")
    func lowConfidence() {
        let viewModel = QuizSessionViewModel(quiz: quiz(timer: nil), store: InMemoryQuizStore())
        let first = viewModel.questions[0]

        #expect(viewModel.isLowConfidence(first))
        #expect(viewModel.citationLabel(for: first) == QuizCopy.source)
        #expect(!viewModel.canAddToPlan)
    }

    @Test("A failed save still shows the scorecard with an error")
    func saveFailure() async {
        let store = InMemoryQuizStore()
        await store.forceFailure(.storageFailed)
        let viewModel = QuizSessionViewModel(quiz: quiz(timer: nil), store: store)

        await viewModel.requestSubmit()
        await viewModel.confirmSubmit()

        #expect(viewModel.phase == .finished)
        #expect(viewModel.result != nil)
        #expect(viewModel.error != nil)
    }
}
