import Foundation

enum QuizScoreTone: Equatable {
    case strong
    case fair
    case weak

    init(percent: Int) {
        if percent >= 80 {
            self = .strong
        } else if percent >= 60 {
            self = .fair
        } else {
            self = .weak
        }
    }
}

enum QuizOutcome: Equatable {
    case correct
    case partial
    case incorrect
    case skipped
}

struct QuizTopicResult: Identifiable, Equatable, Sendable {
    let topic: String
    let earned: Double
    let total: Int

    var id: String { topic }
    var fraction: Double { total == 0 ? 0 : earned / Double(total) }
    var percent: Int { Int((fraction * 100).rounded()) }
    var isWeak: Bool { fraction < QuizInsights.weakThreshold }
}

enum QuizInsights {

    static let weakThreshold = 0.6
    static let missedTopicLimit = 3

    static func points(_ response: QuizResponse?, credit: QuizCredit?) -> Double {
        if let credit { return credit.points }
        return response?.isCorrect == true ? 1 : 0
    }

    static func outcome(_ response: QuizResponse?, credit: QuizCredit?) -> QuizOutcome {
        guard let response, response.selectedOptionIndex != nil else { return .skipped }
        switch credit {
        case .some(.half): return .partial
        case .some(.full): return .correct
        case .some(.zero): return .incorrect
        case nil: return response.isCorrect ? .correct : .incorrect
        }
    }

    static func topicResults(
        questions: [QuizQuestion],
        responses: [String: QuizResponse],
        credits: [String: QuizCredit]
    ) -> [QuizTopicResult] {
        var order: [String] = []
        var earned: [String: Double] = [:]
        var totals: [String: Int] = [:]
        for question in questions {
            if totals[question.topic] == nil { order.append(question.topic) }
            totals[question.topic, default: 0] += 1
            earned[question.topic, default: 0] += points(responses[question.id], credit: credits[question.id])
        }
        return order.map { QuizTopicResult(topic: $0, earned: earned[$0] ?? 0, total: totals[$0] ?? 0) }
    }

    static func weakestTopic(_ results: [QuizTopicResult]) -> QuizTopicResult? {
        results.filter(\.isWeak).min { $0.fraction < $1.fraction }
    }

    static func scoreText(earned: Double, total: Int) -> String {
        let value = earned.rounded() == earned ? Int(earned).formatted() : earned.formatted(.number.precision(.fractionLength(1)))
        return QuizCopy.score(value, total)
    }

    static func percent(earned: Double, total: Int) -> Int {
        total == 0 ? 0 : Int((earned / Double(total) * 100).rounded())
    }

    static func durationText(_ seconds: Int) -> String {
        let clamped = max(0, seconds)
        let minutes = clamped / 60
        let remainder = clamped % 60
        return minutes == 0 ? QuizCopy.seconds(remainder) : QuizCopy.duration(minutes, remainder)
    }

    static func clockText(_ seconds: Int) -> String {
        let clamped = max(0, seconds)
        return String(format: "%02d:%02d", clamped / 60, clamped % 60)
    }
}

struct QuizResult: Equatable {
    let quiz: Quiz
    let attempt: QuizAttempt
    let record: QuizAttemptRecord?

    var questions: [QuizQuestion] {
        let included = Set(record?.questionIds ?? attempt.responses.map(\.questionId))
        return quiz.questions.filter { included.contains($0.id) }
    }

    var responses: [String: QuizResponse] {
        Dictionary(attempt.responses.map { ($0.questionId, $0) }, uniquingKeysWith: { first, _ in first })
    }

    var credits: [String: QuizCredit] { record?.credits ?? [:] }

    var total: Int { questions.count }

    var earned: Double {
        let responses = responses
        let credits = credits
        return questions.reduce(0) { $0 + QuizInsights.points(responses[$1.id], credit: credits[$1.id]) }
    }

    var percent: Int { QuizInsights.percent(earned: earned, total: total) }
    var scoreText: String { QuizInsights.scoreText(earned: earned, total: total) }
    var tone: QuizScoreTone { QuizScoreTone(percent: percent) }

    var topics: [QuizTopicResult] {
        QuizInsights.topicResults(questions: questions, responses: responses, credits: credits)
    }

    var weakestTopic: QuizTopicResult? { QuizInsights.weakestTopic(topics) }

    var weakQuestions: [QuizQuestion] {
        let weak = Set(topics.filter(\.isWeak).map(\.topic))
        return questions.filter { weak.contains($0.topic) }
    }

    var missedTopics: [String] {
        var seen = Set<String>()
        var missed: [String] = []
        for question in questions where outcome(for: question) != .correct {
            if seen.insert(question.topic).inserted { missed.append(question.topic) }
        }
        return Array(missed.prefix(QuizInsights.missedTopicLimit))
    }

    var durationText: String? { record.map { QuizInsights.durationText($0.durationSeconds) } }
    var timedOut: Bool { record?.timedOut ?? false }

    func outcome(for question: QuizQuestion) -> QuizOutcome {
        QuizInsights.outcome(responses[question.id], credit: credits[question.id])
    }

    func response(for question: QuizQuestion) -> QuizResponse? {
        responses[question.id]
    }

    func typedAnswer(for question: QuizQuestion) -> String? {
        record?.typedAnswers[question.id]
    }

    func isFlagged(_ question: QuizQuestion) -> Bool {
        record?.flaggedQuestionIds.contains(question.id) ?? false
    }

    func yourAnswer(for question: QuizQuestion) -> String? {
        if QuizQuestionKind(question) == .shortAnswer { return typedAnswer(for: question) }
        guard let index = response(for: question)?.selectedOptionIndex, question.options.indices.contains(index) else { return nil }
        return question.options[index]
    }

    func correctAnswer(for question: QuizQuestion) -> String {
        question.options.indices.contains(question.correctOptionIndex) ? question.options[question.correctOptionIndex] : ""
    }
}
