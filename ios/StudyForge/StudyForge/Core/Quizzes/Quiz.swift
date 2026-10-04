//
//  Quiz.swift
//  StudyForge
//
//  A generated quiz, its questions, and the attempts a student has made at it.
//
//  WHY ATTEMPTS LIVE ON THE QUIZ
//  -----------------------------
//  The quizzes list shows the latest score, and the scorecard is always "the attempt I just made".
//  Keeping attempts beside their questions means one read renders both, which is the read pattern
//  the brief's analytics story (docs/05 §2.3) depends on — and the store seam hides a future split
//  into `quizAttempts` subdocuments.
//

import Foundation

/// A quiz generated from one material.
struct Quiz: Identifiable, Equatable, Sendable, Codable {

    let id: String
    var title: String
    let materialId: String?
    let questionType: QuizQuestionType
    var questions: [QuizQuestion]

    /// The countdown the student chose when the quiz was generated, in minutes, or `nil` when the
    /// quiz is untimed.
    ///
    /// Recorded ON THE QUIZ rather than in the taking session, for the same reason the questions
    /// are: a timed quiz is timed on every attempt, not only the first, so a retake cannot quietly
    /// drop the clock the student set.
    let timerMinutes: Int?

    /// Attempts, most recent first.
    var attempts: [QuizAttempt]

    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        title: String,
        materialId: String? = nil,
        questionType: QuizQuestionType,
        questions: [QuizQuestion],
        timerMinutes: Int? = nil,
        attempts: [QuizAttempt] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.materialId = materialId
        self.questionType = questionType
        self.questions = questions
        self.timerMinutes = timerMinutes
        self.attempts = attempts
        self.createdAt = createdAt
    }

    /// Whether the quiz runs against a clock.
    var isTimed: Bool { timerMinutes != nil }

    /// The most recent attempt, when one exists.
    var latestAttempt: QuizAttempt? { attempts.first }
}

/// One generated question. Options are always four, with exactly one correct.
struct QuizQuestion: Identifiable, Equatable, Sendable, Codable {

    let id: String
    var stem: String
    var options: [String]
    var correctOptionIndex: Int
    var explanation: String
    var topic: String

    /// Where the question came from. The feedback panel cites it.
    var provenance: AIProvenance

    init(
        id: String = UUID().uuidString,
        stem: String,
        options: [String],
        correctOptionIndex: Int,
        explanation: String,
        topic: String,
        provenance: AIProvenance
    ) {
        self.id = id
        self.stem = stem
        self.options = options
        self.correctOptionIndex = correctOptionIndex
        self.explanation = explanation
        self.topic = topic
        self.provenance = provenance
    }
}

/// One student response within an attempt.
struct QuizResponse: Identifiable, Equatable, Sendable, Codable {
    let questionId: String

    /// `nil` means the question was skipped — kept optional for the day skipping is added.
    var selectedOptionIndex: Int?

    var isCorrect: Bool

    var id: String { questionId }
}

/// One completed (or partially completed) run through a quiz.
struct QuizAttempt: Identifiable, Equatable, Sendable, Codable {

    let id: String
    var responses: [QuizResponse]
    let createdAt: Date

    init(id: String = UUID().uuidString, responses: [QuizResponse] = [], createdAt: Date = .now) {
        self.id = id
        self.responses = responses
        self.createdAt = createdAt
    }

    var correctCount: Int { responses.filter(\.isCorrect).count }
    var totalCount: Int { responses.count }
    var scoreFraction: Double { totalCount == 0 ? 0 : Double(correctCount) / Double(totalCount) }
    var scorePercent: Int { Int((scoreFraction * 100).rounded()) }
}

/// A per-topic slice of an attempt, for the scorecard's performance bars.
struct QuizTopicScore: Equatable, Sendable {
    let topic: String
    let correct: Int
    let total: Int

    var fraction: Double { total == 0 ? 0 : Double(correct) / Double(total) }
    var percent: Int { Int((fraction * 100).rounded()) }
}
