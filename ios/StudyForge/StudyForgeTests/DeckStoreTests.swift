//
//  DeckStoreTests.swift
//  StudyForgeTests
//
//  Tests for the flashcard models and their stores.
//
//  The load-bearing one is `codableRoundTrip`: a card's scheduling state IS its value, so a save
//  that dropped `sr` would silently erase every review the student had done.
//

import Foundation
import Testing
@testable import StudyForge

// MARK: - Model

@Suite("Flashcard model")
struct FlashcardModelTests {

    private func deck() -> Deck {
        Deck(
            id: "d1",
            title: "Normalisation",
            materialId: "m1",
            cards: [
                Flashcard(
                    id: "c1",
                    front: "What is 3NF?",
                    back: "No transitive dependencies.",
                    provenance: AIProvenance(materialId: "m1", pageNumbers: [18], confidence: .high),
                    sr: SpacedRepetitionState(ease: 2.5, interval: 6, dueAt: .now, reps: 2, lapses: 0)
                )
            ]
        )
    }

    @Test("A deck round-trips through JSON without losing its scheduling state")
    func codableRoundTrip() throws {
        let original = deck()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Deck.self, from: data)

        #expect(decoded == original)
        #expect(decoded.cards.first?.sr.interval == 6)
        #expect(decoded.cards.first?.sr.reps == 2)
    }

    @Test("Deck counters split cards into due, new, learning and mastered")
    func counters() {
        let now = Date()
        let deck = Deck(title: "Deck", cards: [
            // New: never reviewed.
            Flashcard(front: "new", back: "b", provenance: AIProvenance(materialId: "m", pageNumbers: [], confidence: .high),
                      sr: SpacedRepetitionState(dueAt: now, reps: 0)),
            // Learning: reviewed once, interval < 30.
            Flashcard(front: "learning", back: "b", provenance: AIProvenance(materialId: "m", pageNumbers: [], confidence: .high),
                      sr: SpacedRepetitionState(interval: 6, dueAt: now.addingTimeInterval(86_400), reps: 2)),
            // Mastered: interval >= 30.
            Flashcard(front: "mastered", back: "b", provenance: AIProvenance(materialId: "m", pageNumbers: [], confidence: .high),
                      sr: SpacedRepetitionState(interval: 30, dueAt: now.addingTimeInterval(86_400 * 30), reps: 3)),
        ])

        #expect(deck.newCount == 1)
        #expect(deck.learningCount == 1)
        #expect(deck.masteredCount == 1)
        #expect(deck.dueCount(now: now) == 1, "only the new card is due")
    }
}

// MARK: - Stores

@Suite("Deck store")
struct DeckStoreTests {

    private func deck(id: String, updatedAt: Date) -> Deck {
        Deck(id: id, title: "Deck", createdAt: .now, updatedAt: updatedAt)
    }

    @Test("The in-memory store returns decks most recently updated first")
    func inMemoryOrdersNewestFirst() async throws {
        let store = InMemoryDeckStore(seededWith: [
            deck(id: "old", updatedAt: .now.addingTimeInterval(-3600)),
            deck(id: "new", updatedAt: .now),
        ])
        #expect(try await store.all().map(\.id) == ["new", "old"])
    }

    @Test("The in-memory store adds, looks up and deletes")
    func inMemoryCRUD() async throws {
        let store = InMemoryDeckStore()
        let record = deck(id: "d1", updatedAt: .now)

        try await store.add(record)
        #expect(try await store.deck(id: "d1") == record)

        try await store.delete(id: "d1")
        #expect(try await store.deck(id: "d1") == nil)
    }

    @Test("The in-memory store surfaces a forced failure")
    func inMemoryFailureIsReported() async {
        let store = InMemoryDeckStore()
        await store.forceFailure(.storageFailed)
        await #expect(throws: DeckError.self) {
            try await store.all()
        }
    }

    @Test("The file store persists decks across instances")
    func fileStorePersists() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("deck-tests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        try await FileDeckStore(directory: directory).add(deck(id: "d1", updatedAt: .now))
        #expect(try await FileDeckStore(directory: directory).deck(id: "d1")?.id == "d1")
    }

    @Test("Deck store failures map to the app's single user-facing error")
    func errorMapsToAppError() {
        #expect(DeckError.storageFailed.asAppError == AppError.server(reference: "deck-store-failed"))
    }
}
