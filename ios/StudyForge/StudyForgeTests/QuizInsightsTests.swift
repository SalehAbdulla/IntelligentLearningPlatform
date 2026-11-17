import Foundation
import Testing
@testable import StudyForge

@Suite("Quiz results and topic insights (F05)")
struct QuizInsightsTests {

    private func question(_ id: String, topic: String, options: [String] = ["A", "B", "C", "D"]) -> QuizQuestion {
        QuizQuestion(
            id: id,
            stem: "Question \(id)",
            options: options,
            correctOptionIndex: 0,
            explanation: "Explained.",
            topic: topic,
            provenance: AIProvenance(materialId: "m", pageNumbers: [2], confidence: .high)
        )
    }

    private func response(_ id: String, _ option: Int?, correct: Bool) -> QuizResponse {
        QuizResponse(questionId: id, selectedOptionIndex: option, isCorrect: correct)
    }

    private var quiz: Quiz {
        Quiz(
            title: "Trees quiz 1",
            questionType: .mixed,
            questions: [
                question("q1", topic: "Traversal"),
                question("q2", topic: "Traversal"),
                question("q3", topic: "Balancing"),
                question("q4", topic: "Balancing", options: ["Rotations"]),
                question("q5", topic: "Basics")
            ]
        )
    }

    private var attempt: QuizAttempt {
        QuizAttempt(id: "a1", responses: [
            response("q1", 0, correct: true),
            response("q2", 0, correct: true),
            response("q3", 2, correct: false),
            response("q4", 0, correct: false),
            response("q5", nil, correct: false)
        ])
    }

    private var record: QuizAttemptRecord {
        QuizAttemptRecord(
            id: "a1",
            quizId: "quiz",
            questionIds: ["q1", "q2", "q3", "q4", "q5"],
            durationSeconds: 492,
            flaggedQuestionIds: ["q3"],
            typedAnswers: ["q4": "rotate"],
            credits: ["q4": .half],
            timedOut: true
        )
    }

    @Test("Half credit counts as half a mark in the score")
    func scoreWithHalfCredit() {
        let result = QuizResult(quiz: quiz, attempt: attempt, record: record)

        #expect(result.earned == 2.5)
        #expect(result.total == 5)
        #expect(result.percent == 50)
        #expect(result.scoreText == QuizCopy.score(2.5.formatted(.number.precision(.fractionLength(1))), 5))
        #expect(result.tone == .weak)
        #expect(result.timedOut)
    }

    @Test("Topics keep their order and show their share of marks")
    func topicResults() {
        let topics = QuizResult(quiz: quiz, attempt: attempt, record: record).topics

        #expect(topics.map(\.topic) == ["Traversal", "Balancing", "Basics"])
        #expect(topics.map(\.percent) == [100, 25, 0])
        #expect(topics.map(\.isWeak) == [false, true, true])
    }

    @Test("The weakest topic is the lowest weak one")
    func weakestTopic() {
        let result = QuizResult(quiz: quiz, attempt: attempt, record: record)

        #expect(result.weakestTopic?.topic == "Basics")
        #expect(result.weakQuestions.map(\.id) == ["q3", "q4", "q5"])
        #expect(result.missedTopics == ["Balancing", "Basics"])
    }

    @Test("Each answer has an outcome, including skips and half marks")
    func outcomes() {
        let result = QuizResult(quiz: quiz, attempt: attempt, record: record)
        let outcomes = result.questions.map { result.outcome(for: $0) }

        #expect(outcomes == [.correct, .correct, .incorrect, .partial, .skipped])
        #expect(result.yourAnswer(for: quiz.questions[3]) == "rotate")
        #expect(result.yourAnswer(for: quiz.questions[2]) == "C")
        #expect(result.correctAnswer(for: quiz.questions[2]) == "A")
        #expect(result.isFlagged(quiz.questions[2]))
    }

    @Test("A weak-topics retake only scores the questions it asked")
    func subsetAttempt() {
        let subset = QuizAttemptRecord(id: "a2", quizId: "quiz", questionIds: ["q3", "q5"], durationSeconds: 30)
        let partial = QuizAttempt(id: "a2", responses: [response("q3", 0, correct: true), response("q5", 0, correct: true)])
        let result = QuizResult(quiz: quiz, attempt: partial, record: subset)

        #expect(result.total == 2)
        #expect(result.percent == 100)
        #expect(result.weakestTopic == nil)
    }

    @Test("Without a record every response decides its own mark")
    func withoutRecord() {
        let result = QuizResult(quiz: quiz, attempt: attempt, record: nil)

        #expect(result.earned == 2)
        #expect(result.durationText == nil)
    }

    @Test("Durations, clocks and tones are formatted for the screens")
    func formatting() {
        #expect(QuizInsights.durationText(492) == QuizCopy.duration(8, 12))
        #expect(QuizInsights.durationText(45) == QuizCopy.seconds(45))
        #expect(QuizInsights.clockText(272) == "04:32")
        #expect(QuizInsights.clockText(-5) == "00:00")
        #expect(QuizScoreTone(percent: 80) == .strong)
        #expect(QuizScoreTone(percent: 60) == .fair)
        #expect(QuizScoreTone(percent: 59) == .weak)
    }
}
