import Foundation

struct FlashcardTopicMastery: Identifiable, Equatable, Sendable {
    let topic: String
    let score: Double
    let cards: Int
    let reviews: Int
    let lastReviewedAt: Date

    var id: String { topic }
    var percent: Int { Int((score * 100).rounded()) }
    var isWeak: Bool { score < FlashcardReviewStats.weakTopicThreshold }
}

enum FlashcardReviewStats {

    static let weakTopicThreshold = 0.6

    static func weight(_ rating: ReviewRating) -> Double {
        switch rating {
        case .again: 0
        case .hard: 0.5
        case .good: 0.8
        case .easy: 1
        }
    }

    static func topicMastery(_ entries: [FlashcardReviewEntry]) -> [FlashcardTopicMastery] {
        var byTopic: [String: [FlashcardReviewEntry]] = [:]
        for entry in entries {
            for tag in Set(entry.tags) where tag != FlashcardLimits.flagTag {
                byTopic[tag, default: []].append(entry)
            }
        }
        let topics = byTopic.map { element -> FlashcardTopicMastery in
            let topic = element.key
            let reviews = element.value
            let latestPerCard = Dictionary(grouping: reviews, by: { $0.cardId })
                .compactMap { pair in pair.value.max(by: { $0.reviewedAt < $1.reviewedAt }) }
            let total = latestPerCard.reduce(0.0) { sum, review in sum + weight(review.rating) }
            return FlashcardTopicMastery(
                topic: topic,
                score: latestPerCard.isEmpty ? 0 : total / Double(latestPerCard.count),
                cards: latestPerCard.count,
                reviews: reviews.count,
                lastReviewedAt: reviews.map(\.reviewedAt).max() ?? .distantPast
            )
        }
        return topics.sorted { lhs, rhs in
            lhs.score == rhs.score ? lhs.topic < rhs.topic : lhs.score < rhs.score
        }
    }

    static func streak(
        _ entries: [FlashcardReviewEntry],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        let days = Set(entries.map { calendar.startOfDay(for: $0.reviewedAt) })
        guard !days.isEmpty else { return 0 }
        let today = calendar.startOfDay(for: now)
        var cursor = today
        if !days.contains(today) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  days.contains(yesterday) else { return 0 }
            cursor = yesterday
        }
        var count = 0
        while days.contains(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    static func reviewedToday(
        _ entries: [FlashcardReviewEntry],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        entries.filter { calendar.isDate($0.reviewedAt, inSameDayAs: now) }.count
    }
}
