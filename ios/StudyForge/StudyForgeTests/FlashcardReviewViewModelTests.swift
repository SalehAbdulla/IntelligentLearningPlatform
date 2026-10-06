//
//  FlashcardReviewViewModelTests.swift
//  StudyForgeTests
//
//  Tests for the review session: rating a card, counting progress, and handing back to SM-2.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Flashcard review (F04)")
@MainActor
struct FlashcardReviewViewModelTests {

    private func card(id: String) -> Flashcard {
        Flashcard(
            id: id,
            front: "Question \(id)",
            back: "Answer \(id)",
            provenance: AIProvenance(materialId: "m", pageNumbers: [1], confidence: .high)
        )
    }

    private func deck(cards: [Flashcard]) -> Deck {
        Deck(id: "d1", title: "Deck", cards: cards)
    }

    @Test("A fresh deck opens a session over its new cards")
    func freshDeckIsReviewing() {
        let viewModel = FlashcardReviewViewModel(
            deck: deck(cards: [card(id: "c1"), card(id: "c2")]),
            store: InMemoryDeckStore()
        )
        #expect(viewModel.phase == .reviewing)
        #expect(viewModel.cards.count == 2)
    }

    @Test("A deck with nothing due shows the empty state")
    func nothingDueIsEmpty() {
        let future = SpacedRepetitionState(
            interval: 30,
            dueAt: .now.addingTimeInterval(86_400 * 30),
            reps: 3
        )
        let futureCard = Flashcard(
            front: "mastered", back: "answer",
            provenance: AIProvenance(materialId: "m", pageNumbers: [], confidence: .high),
            sr: future
        )
        let viewModel = FlashcardReviewViewModel(deck: deck(cards: [futureCard]), store: InMemoryDeckStore())
        #expect(viewModel.phase == .empty)
    }

    @Test("Reveal flips the card to its answer")
    func reveal() {
        let viewModel = FlashcardReviewViewModel(deck: deck(cards: [card(id: "c1")]), store: InMemoryDeckStore())
        #expect(viewModel.isShowingAnswer == false)
        viewModel.reveal()
        #expect(viewModel.isShowingAnswer)
    }

    @Test("Rating a new card as good schedules it for tomorrow")
    func goodRatingSchedules() async throws {
        let store = InMemoryDeckStore()
        try await store.add(deck(cards: [card(id: "c1"), card(id: "c2")]))
        let viewModel = FlashcardReviewViewModel(deck: deck(cards: [card(id: "c1"), card(id: "c2")]), store: store)

        await viewModel.rate(.good)

        #expect(viewModel.reviewedCount == 1)
        #expect(viewModel.correctCount == 1)
        let saved = try await store.deck(id: "d1")
        #expect(saved?.cards.first(where: { $0.id == "c1" })?.sr.interval == 1)
    }

    @Test("Rating as again is a lapse, not a correct answer")
    func againRatingLapses() async throws {
        let store = InMemoryDeckStore()
        try await store.add(deck(cards: [card(id: "c1")]))
        let viewModel = FlashcardReviewViewModel(deck: deck(cards: [card(id: "c1")]), store: store)

        await viewModel.rate(.again)

        #expect(viewModel.correctCount == 0)
        #expect(viewModel.reviewedCount == 1)
        #expect(viewModel.phase == .summary)

        let saved = try await store.deck(id: "d1")
        let rated = saved?.cards.first(where: { $0.id == "c1" })
        #expect(rated?.sr.lapses == 1)
        #expect(rated?.sr.interval == 0)
    }

    @Test("Accuracy is correct answers over answers given")
    func accuracy() async {
        let viewModel = FlashcardReviewViewModel(
            deck: deck(cards: [card(id: "c1"), card(id: "c2"), card(id: "c3")]),
            store: InMemoryDeckStore()
        )

        await viewModel.rate(.good)
        await viewModel.rate(.again)

        #expect(viewModel.accuracyPercent == 50)
    }

    @Test("Keep going re-picks up lapsed cards")
    func keepGoingPicksUpLapses() async {
        let viewModel = FlashcardReviewViewModel(
            deck: deck(cards: [card(id: "c1"), card(id: "c2")]),
            store: InMemoryDeckStore()
        )

        await viewModel.rate(.good)   // c1 → due tomorrow
        await viewModel.rate(.again)  // c2 → lapse, due now
        #expect(viewModel.phase == .summary)

        viewModel.keepGoing()

        #expect(viewModel.phase == .reviewing)
        #expect(viewModel.cards.map(\.id) == ["c2"], "only the lapsed card is due again")
    }

    @Test("Interval labels map days to a human unit")
    func intervalLabels() {
        #expect(FlashcardReviewViewModel.intervalLabel(days: 0) == L10n.flashcardIntervalAgain.string)
        #expect(FlashcardReviewViewModel.intervalLabel(days: 1) == L10n.flashcardIntervalDays.string(1))
        #expect(FlashcardReviewViewModel.intervalLabel(days: 13) == L10n.flashcardIntervalDays.string(13))
        #expect(FlashcardReviewViewModel.intervalLabel(days: 30) == L10n.flashcardIntervalMonths.string(1))
        #expect(FlashcardReviewViewModel.intervalLabel(days: 65) == L10n.flashcardIntervalMonths.string(2))
    }

    @Test("The interval label predicts what each rating would do")
    func intervalLabelPredictsRating() {
        let viewModel = FlashcardReviewViewModel(deck: deck(cards: [card(id: "c1")]), store: InMemoryDeckStore())
        #expect(viewModel.intervalLabel(for: .good) == L10n.flashcardIntervalDays.string(1))
        #expect(viewModel.intervalLabel(for: .again) == L10n.flashcardIntervalAgain.string)
    }
}
