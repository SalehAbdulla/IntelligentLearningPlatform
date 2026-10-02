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

    private let store: any QuizStore

    init(quiz: Quiz, store: any QuizStore) {
        self.quiz = quiz
        self.store = store
        self.phase = quiz.questions.isEmpty ? .scorecard : .question
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

    /// Advances to the next question, or submits once the last one is answered.
    func next() async {
        guard phase == .feedback else { return }
        if currentIndex + 1 >= quiz.questions.count {
            await submit()
        } else {
            currentIndex += 1
            selectedOption = nil
            phase = .question
        }
    }

    private func submit() async {
        quiz.attempts.insert(QuizAttempt(responses: responses), at: 0)
        do {
            try await store.add(quiz)
        } catch {
            self.error = AppError.from(error)
        }
        phase = .scorecard
    }
}
