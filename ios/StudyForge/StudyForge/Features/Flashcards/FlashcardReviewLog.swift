import Foundation

struct FlashcardReviewEntry: Identifiable, Equatable, Sendable, Codable {
    let id: String
    let deckId: String
    let cardId: String
    let rating: ReviewRating
    let intervalDays: Int
    let tags: [String]
    let reviewedAt: Date

    init(
        id: String = UUID().uuidString,
        deckId: String,
        cardId: String,
        rating: ReviewRating,
        intervalDays: Int,
        tags: [String] = [],
        reviewedAt: Date = .now
    ) {
        self.id = id
        self.deckId = deckId
        self.cardId = cardId
        self.rating = rating
        self.intervalDays = intervalDays
        self.tags = tags
        self.reviewedAt = reviewedAt
    }
}

protocol FlashcardReviewLog: Sendable {
    func entries() async throws -> [FlashcardReviewEntry]
    func append(_ entry: FlashcardReviewEntry) async throws
    func remove(id: String) async throws
}
