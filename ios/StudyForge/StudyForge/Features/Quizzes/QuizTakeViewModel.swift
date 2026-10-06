//
//  QuizTakeViewModel.swift
//  StudyForge
//
//  Presentation logic for F04–F09 — taking a quiz: answer with immediate feedback, then a scorecard
//  with a per-topic breakdown and answer review.
//
//  WHY IMMEDIATE FEEDBACK
//  ----------------------
//  The design shows correctness after every question (F05/F06) rather than grading at the end,
//  because the point is learning, not measurement. The scorecard still totals it all up.
//

import Foundation

@MainActor
@Observable
final class QuizTakeViewModel {

    enum Phase: Equatable {
        case question
        case feedback
        case scorecard
    }

    private(set) var quiz: Quiz
    private(set) var currentIndex = 0
    private(set) var phase: Phase = .question
    private(set) var selectedOption: Int?
    private(set) var responses: [QuizResponse] = []
    private(set) var error: AppError?

    /// Questions the student flagged for another look. An in-session aid, not persisted: a flag
    /// describes how the student felt while answering, and an attempt is the record of what they
    /// answered, not how they felt about it.
    private(set) var flaggedQuestionIds: Set<String> = []

    /// Seconds left on a timed quiz, or `nil` when the quiz is untimed. Seeded from the quiz so
    /// every attempt is governed by the same clock.
    private(set) var remainingSeconds: Int?

    /// True while the student has asked to submit but has not confirmed.
    private(set) var isConfirmingSubmit = false

    private let store: any QuizStore

    init(quiz: Quiz, store: any QuizStore) {
        self.quiz = quiz
        self.store = store
        self.phase = quiz.questions.isEmpty ? .scorecard : .question
        self.remainingSeconds = quiz.timerMinutes.map { $0 * 60 }
    }

    // MARK: Derived

    var currentQuestion: QuizQuestion? {
        quiz.questions.indices.contains(currentIndex) ? quiz.questions[currentIndex] : nil
    }

    var progress: String { L10n.quizProgress.string(currentIndex + 1, quiz.questions.count) }

    /// The correctness of the answer just given, shown during feedback.
    var lastResponseIsCorrect: Bool? { responses.last?.isCorrect }

    // MARK: Scorecard

    var correctCount: Int { responses.filter(\.isCorrect).count }
    var totalCount: Int { responses.count }
    var scorePercent: Int {
        totalCount == 0 ? 0 : Int((Double(correctCount) / Double(totalCount) * 100).rounded())
    }

    var scoreText: String { L10n.quizScore.string(correctCount, totalCount) }

    /// Correct answers grouped by topic, for the scorecard's performance bars.
    var topicScores: [QuizTopicScore] {
        let grouped = Dictionary(grouping: quiz.questions, by: { $0.topic })
        return grouped.map { (topic, questions) in
            let ids = Set(questions.map(\.id))
            let relevant = responses.filter { ids.contains($0.questionId) }
            return QuizTopicScore(
                topic: topic,
                correct: relevant.filter(\.isCorrect).count,
                total: relevant.count
            )
        }
        .sorted { $0.topic < $1.topic }
    }

    func response(for question: QuizQuestion) -> QuizResponse? {
        responses.first { $0.questionId == question.id }
    }

    // MARK: Copy

    var takeTitle: String { L10n.quizTakeTitle.string }
    var correctTitle: String { L10n.quizCorrect.string }
    var incorrectTitle: String { L10n.quizIncorrect.string }
    var explanationTitle: String { L10n.quizExplanation.string }
    var scorecardTitle: String { L10n.quizScorecardTitle.string }
    var topicHeading: String { L10n.quizTopicHeading.string }
    var reviewAnswersTitle: String { L10n.quizReviewAnswers.string }
    var yourAnswerTitle: String { L10n.quizYourAnswer.string }
    var correctAnswerTitle: String { L10n.quizCorrectAnswer.string }
    var submitTitle: String { L10n.quizSubmit.string }
    var submitConfirmTitle: String { L10n.quizSubmitConfirmTitle.string }
    var flagTitle: String { L10n.quizFlag.string }
    var unflagTitle: String { L10n.quizUnflag.string }

    /// The submit-confirmation message: how much of the quiz has been answered.
    var submitConfirmBody: String {
        L10n.quizSubmitConfirmBody.string(responses.count, quiz.questions.count)
    }

    // MARK: Timer and flags

    var isTimed: Bool { remainingSeconds != nil }

    /// The clock as `m:ss`, or `nil` when the quiz is untimed.
    var timeRemainingText: String? {
        guard let remainingSeconds else { return nil }
        let clamped = max(0, remainingSeconds)
        return String(format: "%d:%02d", clamped / 60, clamped % 60)
    }

    /// The clock phrased for the student, or `nil` when untimed.
    var timeRemainingLabel: String? {
        timeRemainingText.map { L10n.quizTimeRemaining.string($0) }
    }

    func isFlagged(_ question: QuizQuestion) -> Bool { flaggedQuestionIds.contains(question.id) }

    func flagTitle(for question: QuizQuestion) -> String {
        isFlagged(question) ? unflagTitle : flagTitle
    }

    func toggleFlag(for question: QuizQuestion) {
        if flaggedQuestionIds.contains(question.id) {
            flaggedQuestionIds.remove(question.id)
        } else {
            flaggedQuestionIds.insert(question.id)
        }
    }

    func citationLabel(for question: QuizQuestion) -> String {
        question.provenance.pageNumbers.isEmpty ? L10n.quizSource.string : question.provenance.citationLabel
    }

    // MARK: Actions

    func select(_ option: Int) {
        guard phase == .question, let question = currentQuestion else { return }
        selectedOption = option
        responses.append(
            QuizResponse(
                questionId: question.id,
                selectedOptionIndex: option,
                isCorrect: option == question.correctOptionIndex
            )
        )
        phase = .feedback
    }

    /// Advances to the next question, or asks to submit once the last one is answered.
    ///
    /// The last "Next" opens the confirmation rather than submitting outright, so the design's
    /// submit-confirm is honoured: finishing the questions is not the same as being ready to hand
    /// the quiz in.
    func next() async {
        guard phase == .feedback else { return }
        if currentIndex + 1 >= quiz.questions.count {
            requestSubmit()
        } else {
            currentIndex += 1
            selectedOption = nil
            phase = .question
        }
    }

    /// Opens the submit confirmation.
    func requestSubmit() {
        guard phase != .scorecard else { return }
        isConfirmingSubmit = true
    }

    func cancelSubmit() { isConfirmingSubmit = false }

    /// Confirms and submits.
    func confirmSubmit() async {
        isConfirmingSubmit = false
        await submit()
    }

    /// One second of the clock.
    ///
    /// When it reaches zero the attempt is submitted rather than discarded — a student who ran out
    /// of time keeps the answers they gave, which is the only outcome that does not punish them for
    /// the clock.
    func tick() async {
        guard let remaining = remainingSeconds, phase != .scorecard else { return }
        if remaining <= 1 {
            remainingSeconds = 0
            await submit()
        } else {
            remainingSeconds = remaining - 1
        }
    }

    /// Persists the attempt and moves to the scorecard.
    ///
    /// Idempotent on purpose: a timer reaching zero and a confirmed submit can race, and only one
    /// attempt may ever be recorded.
    func submit() async {
        guard phase != .scorecard else { return }
        isConfirmingSubmit = false
        quiz.attempts.insert(QuizAttempt(responses: responses), at: 0)
        do {
            try await store.add(quiz)
        } catch {
            self.error = AppError.from(error)
        }
        phase = .scorecard
    }
}
