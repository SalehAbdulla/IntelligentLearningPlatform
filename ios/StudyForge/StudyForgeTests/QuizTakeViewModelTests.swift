//
//  QuizTakeViewModelTests.swift
//  StudyForgeTests
//
//  Tests for taking a quiz: answering with immediate feedback, and the scorecard totals.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Quiz take (F05)")
@MainActor
struct QuizTakeViewModelTests {

    private func question(id: String, topic: String = "normalisation") -> QuizQuestion {
        QuizQuestion(
            id: id,
            stem: "Question \(id)",
            options: ["Correct", "Wrong 1", "Wrong 2", "Wrong 3"],
            correctOptionIndex: 0,
            explanation: "Because the material says so.",
            topic: topic,
            provenance: AIProvenance(materialId: "m", pageNumbers: [1], confidence: .high)
        )
    }

    private func quiz() -> Quiz {
        Quiz(
            title: "Quiz",
            questionType: .multipleChoice,
            questions: [question(id: "q1"), question(id: "q2")]
        )
    }

    @Test("Selecting an answer shows immediate feedback")
    func selectShowsFeedback() {
        let viewModel = QuizTakeViewModel(quiz: quiz(), store: InMemoryQuizStore())

        #expect(viewModel.phase == .question)
        viewModel.select(0)
        #expect(viewModel.phase == .feedback)
        #expect(viewModel.lastResponseIsCorrect == true)
        #expect(viewModel.responses.count == 1)
    }

    @Test("Next advances to the following question")
    func nextAdvances() async {
        let viewModel = QuizTakeViewModel(quiz: quiz(), store: InMemoryQuizStore())

        viewModel.select(0)
        await viewModel.next()

        #expect(viewModel.currentIndex == 1)
        #expect(viewModel.phase == .question)
    }

    @Test("Answering the last question asks to submit, then submits on confirmation")
    func submitTotalsScore() async throws {
        let store = InMemoryQuizStore()
        try await store.add(quiz())
        let viewModel = QuizTakeViewModel(quiz: quiz(), store: store)

        viewModel.select(0)   // correct
        await viewModel.next()
        viewModel.select(1)   // wrong
        await viewModel.next() // asks to submit

        #expect(viewModel.isConfirmingSubmit, "finishing the last question opens the confirmation")
        #expect(viewModel.phase == .feedback)

        await viewModel.confirmSubmit()

        #expect(viewModel.phase == .scorecard)
        #expect(viewModel.correctCount == 1)
        #expect(viewModel.totalCount == 2)
        #expect(viewModel.scorePercent == 50)

        let saved = try await store.quiz(id: viewModel.quiz.id)
        #expect(saved?.attempts.count == 1)
    }

    @Test("Cancelling the submit confirmation returns to the questions")
    func cancelSubmitKeepsTaking() async {
        let viewModel = QuizTakeViewModel(quiz: quiz(), store: InMemoryQuizStore())

        viewModel.select(0)
        await viewModel.next()
        viewModel.select(0)
        await viewModel.next()

        #expect(viewModel.isConfirmingSubmit)
        viewModel.cancelSubmit()

        #expect(viewModel.isConfirmingSubmit == false)
        #expect(viewModel.phase == .feedback)
    }

    @Test("Flagging a question toggles, and the flag is per question")
    func flaggingToggles() {
        let viewModel = QuizTakeViewModel(quiz: quiz(), store: InMemoryQuizStore())
        let first = viewModel.quiz.questions[0]
        let second = viewModel.quiz.questions[1]

        #expect(viewModel.isFlagged(first) == false)
        viewModel.toggleFlag(for: first)
        #expect(viewModel.isFlagged(first))
        #expect(viewModel.isFlagged(second) == false)
        #expect(viewModel.flagTitle(for: first) == L10n.quizUnflag.string)
        #expect(viewModel.flagTitle(for: second) == L10n.quizFlag.string)

        viewModel.toggleFlag(for: first)
        #expect(viewModel.isFlagged(first) == false)
    }

    @Test("A timed quiz counts down and submits itself when the clock runs out")
    func timerCountsDownAndSubmits() async throws {
        let store = InMemoryQuizStore()
        let timed = Quiz(
            title: "Quiz",
            questionType: .multipleChoice,
            questions: [question(id: "q1")],
            timerMinutes: 1
        )
        try await store.add(timed)
        let viewModel = QuizTakeViewModel(quiz: timed, store: store)

        #expect(viewModel.isTimed)
        #expect(viewModel.remainingSeconds == 60)
        #expect(viewModel.timeRemainingText == "1:00")

        viewModel.select(0)
        await viewModel.tick()
        #expect(viewModel.remainingSeconds == 59)
        #expect(viewModel.timeRemainingText == "0:59")

        // Tick the clock down to zero.
        for _ in 0..<60 { await viewModel.tick() }

        #expect(viewModel.phase == .scorecard)
        #expect(try await store.quiz(id: timed.id)?.attempts.count == 1)
    }

    @Test("An untimed quiz has no clock and does not tick")
    func untimedQuizHasNoClock() async {
        let viewModel = QuizTakeViewModel(quiz: quiz(), store: InMemoryQuizStore())

        #expect(viewModel.isTimed == false)
        #expect(viewModel.timeRemainingText == nil)
        #expect(viewModel.timeRemainingLabel == nil)

        await viewModel.tick()
        #expect(viewModel.remainingSeconds == nil)
    }

    @Test("Topic scores group correct answers by topic")
    func topicScores() async {
        let twoTopics = Quiz(
            title: "Quiz",
            questionType: .multipleChoice,
            questions: [question(id: "q1", topic: "a"), question(id: "q2", topic: "b")]
        )
        let viewModel = QuizTakeViewModel(quiz: twoTopics, store: InMemoryQuizStore())

        viewModel.select(0)   // topic "a" correct
        await viewModel.next()
        viewModel.select(1)   // topic "b" wrong
        await viewModel.next()

        let topics = viewModel.topicScores
        #expect(topics.count == 2)
        #expect(topics.first { $0.topic == "a" }?.correct == 1)
        #expect(topics.first { $0.topic == "b" }?.correct == 0)
    }

    @Test("Every string comes from the catalogue")
    func copyIsLocalised() {
        let viewModel = QuizTakeViewModel(quiz: quiz(), store: InMemoryQuizStore())

        #expect(viewModel.takeTitle == L10n.quizTakeTitle.string)
        #expect(viewModel.correctTitle == L10n.quizCorrect.string)
        #expect(viewModel.incorrectTitle == L10n.quizIncorrect.string)
        #expect(viewModel.explanationTitle == L10n.quizExplanation.string)
        #expect(viewModel.scorecardTitle == L10n.quizScorecardTitle.string)
        #expect(viewModel.topicHeading == L10n.quizTopicHeading.string)
        #expect(viewModel.reviewAnswersTitle == L10n.quizReviewAnswers.string)
    }
}
