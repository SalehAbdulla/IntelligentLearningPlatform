import Foundation

actor InMemoryFlashcardReviewLog: FlashcardReviewLog {

    private var stored: [FlashcardReviewEntry]
    private var failure: DeckError?

    init(seededWith entries: [FlashcardReviewEntry] = []) {
        self.stored = entries
    }

    func entries() async throws -> [FlashcardReviewEntry] {
        try failIfForced()
        return stored.sorted { $0.reviewedAt < $1.reviewedAt }
    }

    func append(_ entry: FlashcardReviewEntry) async throws {
        try failIfForced()
        stored.removeAll { $0.id == entry.id }
        stored.append(entry)
    }

    func remove(id: String) async throws {
        try failIfForced()
        stored.removeAll { $0.id == id }
    }

    func forceFailure(_ error: DeckError?) {
        failure = error
    }

    private func failIfForced() throws {
        if let failure { throw failure }
    }
}
