import Foundation
import Testing
@testable import StudyForge

@Suite("Flashcard review stats (F04)")
struct FlashcardReviewStatsTests {

    private let calendar = Calendar(identifier: .gregorian)
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: now) ?? now
    }

    private func review(
        card: String = "c1",
        rating: ReviewRating = .good,
        tags: [String] = [],
        at date: Date
    ) -> FlashcardReviewEntry {
        FlashcardReviewEntry(deckId: "d1", cardId: card, rating: rating, intervalDays: 1, tags: tags, reviewedAt: date)
    }

    @Test("No reviews means no streak")
    func emptyStreak() {
        #expect(FlashcardReviewStats.streak([], now: now, calendar: calendar) == 0)
    }

    @Test("Consecutive days ending today count as a streak")
    func streakEndingToday() {
        let entries = [review(at: day(0)), review(at: day(-1)), review(at: day(-2))]
        #expect(FlashcardReviewStats.streak(entries, now: now, calendar: calendar) == 3)
    }

    @Test("A streak still counts when the last review was yesterday")
    func streakEndingYesterday() {
        let entries = [review(at: day(-1)), review(at: day(-2))]
        #expect(FlashcardReviewStats.streak(entries, now: now, calendar: calendar) == 2)
    }

    @Test("A missed day breaks the streak")
    func gapBreaksStreak() {
        let entries = [review(at: day(0)), review(at: day(-2)), review(at: day(-3))]
        #expect(FlashcardReviewStats.streak(entries, now: now, calendar: calendar) == 1)
    }

    @Test("Nothing since the day before yesterday means no streak")
    func staleStreak() {
        let entries = [review(at: day(-2)), review(at: day(-3))]
        #expect(FlashcardReviewStats.streak(entries, now: now, calendar: calendar) == 0)
    }

    @Test("Several reviews on one day count once")
    func sameDayCountsOnce() {
        let entries = [review(at: day(0)), review(at: day(0).addingTimeInterval(-30))]
        #expect(FlashcardReviewStats.streak(entries, now: now, calendar: calendar) == 1)
        #expect(FlashcardReviewStats.reviewedToday(entries, now: now, calendar: calendar) == 2)
    }

    @Test("Topic mastery uses each card's latest rating")
    func topicUsesLatestRating() {
        let entries = [
            review(card: "c1", rating: .again, tags: ["avl"], at: day(-1)),
            review(card: "c1", rating: .easy, tags: ["avl"], at: day(0)),
            review(card: "c2", rating: .hard, tags: ["avl"], at: day(0))
        ]
        let topics = FlashcardReviewStats.topicMastery(entries)
        #expect(topics.count == 1)
        #expect(topics.first?.topic == "avl")
        #expect(topics.first?.cards == 2)
        #expect(topics.first?.reviews == 3)
        #expect(topics.first?.percent == 75)
    }

    @Test("The flag tag is never a topic")
    func flagIsNotATopic() {
        let entries = [review(tags: [FlashcardLimits.flagTag, "graphs"], at: day(0))]
        #expect(FlashcardReviewStats.topicMastery(entries).map(\.topic) == ["graphs"])
    }

    @Test("Weakest topics come first and are marked weak")
    func weakestFirst() {
        let entries = [
            review(card: "c1", rating: .easy, tags: ["sorting"], at: day(0)),
            review(card: "c2", rating: .again, tags: ["heaps"], at: day(0))
        ]
        let topics = FlashcardReviewStats.topicMastery(entries)
        #expect(topics.map(\.topic) == ["heaps", "sorting"])
        #expect(topics.first?.isWeak == true)
        #expect(topics.last?.isWeak == false)
    }
}
