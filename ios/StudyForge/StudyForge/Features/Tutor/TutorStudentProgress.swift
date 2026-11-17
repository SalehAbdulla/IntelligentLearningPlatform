import Foundation

struct TutorTopicProgress: Identifiable, Equatable, Sendable {
    let topic: String
    let fraction: Double

    var id: String { topic }
    var percent: Int { Int((min(max(fraction, 0), 1) * 100).rounded()) }
}

enum TutorActivityKind: String, Equatable, Sendable {
    case quiz
    case flashcards

    var symbolName: String {
        switch self {
        case .quiz: "checklist"
        case .flashcards: "rectangle.stack"
        }
    }
}

struct TutorActivity: Identifiable, Equatable, Sendable {
    let id: String
    let kind: TutorActivityKind
    let title: String
    let date: Date
    let percent: Int
    let durationSeconds: Int?
}

struct TutorStudentProgress: Equatable, Sendable {
    let topics: [TutorTopicProgress]
    let activity: [TutorActivity]

    var isEmpty: Bool { topics.isEmpty && activity.isEmpty }
}

protocol TutorStudentProgressSource: Sendable {
    func progress(forStudent uid: String) async -> TutorStudentProgress?
}

struct NoSharedProgressSource: TutorStudentProgressSource {
    func progress(forStudent uid: String) async -> TutorStudentProgress? { nil }
}

struct LocalStudentProgressSource: TutorStudentProgressSource {

    static let activityLimit = 5
    static let topicLimit = 6

    let ownerUid: String
    let quizzes: any QuizStore
    let quizLog: any QuizAttemptLog
    let reviewLog: any FlashcardReviewLog

    func progress(forStudent uid: String) async -> TutorStudentProgress? {
        guard uid == ownerUid else { return nil }

        var topicTotals: [String: (sum: Double, count: Int)] = [:]
        var activity: [TutorActivity] = []

        let quizList = (try? await quizzes.all()) ?? []
        for quiz in quizList {
            guard let attempt = quiz.latestAttempt else { continue }
            let record = try? await quizLog.record(id: attempt.id)
            let result = QuizResult(quiz: quiz, attempt: attempt, record: record)
            for topic in result.topics {
                let current = topicTotals[topic.topic] ?? (0, 0)
                topicTotals[topic.topic] = (current.sum + topic.fraction, current.count + 1)
            }
            activity.append(TutorActivity(
                id: attempt.id,
                kind: .quiz,
                title: TutorStudioCopy.quizActivity(quiz.title, result.scoreText),
                date: attempt.createdAt,
                percent: result.percent,
                durationSeconds: record?.durationSeconds
            ))
        }

        let entries = (try? await reviewLog.entries()) ?? []
        for mastery in FlashcardReviewStats.topicMastery(entries) {
            let current = topicTotals[mastery.topic] ?? (0, 0)
            topicTotals[mastery.topic] = (current.sum + mastery.score, current.count + 1)
        }

        let byDay = Dictionary(grouping: entries) { Calendar.current.startOfDay(for: $0.reviewedAt) }
        for (day, dayEntries) in byDay {
            let recalled = dayEntries.filter { $0.rating == .good || $0.rating == .easy }.count
            let percent = Int((Double(recalled) / Double(max(dayEntries.count, 1)) * 100).rounded())
            activity.append(TutorActivity(
                id: "cards-\(day.timeIntervalSince1970)",
                kind: .flashcards,
                title: TutorStudioCopy.cardsActivity(dayEntries.count),
                date: dayEntries.map(\.reviewedAt).max() ?? day,
                percent: percent,
                durationSeconds: nil
            ))
        }

        let topics = topicTotals
            .map { TutorTopicProgress(topic: $0.key, fraction: $0.value.sum / Double(max($0.value.count, 1))) }
            .sorted { $0.fraction < $1.fraction }
            .prefix(Self.topicLimit)

        let progress = TutorStudentProgress(
            topics: Array(topics),
            activity: Array(activity.sorted { $0.date > $1.date }.prefix(Self.activityLimit))
        )
        return progress.isEmpty ? nil : progress
    }
}
