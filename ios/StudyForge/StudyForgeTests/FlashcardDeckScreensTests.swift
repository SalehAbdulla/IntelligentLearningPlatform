import Foundation
import Testing
@testable import StudyForge

@Suite("Flashcard deck screens (F04)")
@MainActor
struct FlashcardDeckScreensTests {

    private func card(
        id: String,
        front: String? = nil,
        sr: SpacedRepetitionState = SpacedRepetitionState()
    ) -> Flashcard {
        Flashcard(
            id: id,
            front: front ?? "Question \(id)",
            back: "Answer \(id)",
            provenance: AIProvenance(materialId: "m", pageNumbers: [1], confidence: .high),
            sr: sr
        )
    }

    private func scheduled(days: Int, reps: Int = 2) -> SpacedRepetitionState {
        SpacedRepetitionState(
            interval: days,
            dueAt: .now.addingTimeInterval(Double(days) * 86_400),
            reps: reps
        )
    }

    @Test("The decks list loads every deck and totals what is due")
    func decksHomeTotalsDue() async throws {
        let store = InMemoryDeckStore(seededWith: [
            Deck(id: "a", title: "A", cards: [card(id: "a1"), card(id: "a2")]),
            Deck(id: "b", title: "B", cards: [card(id: "b1"), card(id: "b2", sr: scheduled(days: 6))])
        ])
        let viewModel = DecksHomeViewModel(store: store)

        await viewModel.load()

        #expect(viewModel.hasLoaded)
        #expect(viewModel.decks.count == 2)
        #expect(viewModel.totalDue() == 3)
        #expect(viewModel.mostDueDeck()?.id == "a")
    }

    @Test("An empty store shows the empty state, not an error")
    func decksHomeEmpty() async {
        let viewModel = DecksHomeViewModel(store: InMemoryDeckStore())

        await viewModel.load()

        #expect(viewModel.isEmpty)
        #expect(viewModel.error == nil)
        #expect(viewModel.mostDueDeck() == nil)
    }

    @Test("Deleting a deck removes it from the list and the store")
    func decksHomeDelete() async throws {
        let store = InMemoryDeckStore(seededWith: [Deck(id: "a", title: "A", cards: [card(id: "a1")])])
        let viewModel = DecksHomeViewModel(store: store)
        await viewModel.load()

        await viewModel.delete(viewModel.decks[0])

        #expect(viewModel.decks.isEmpty)
        #expect(try await store.all().isEmpty)
    }

    @Test("The deck detail counts due, new, learning and mastered cards")
    func overviewCounters() async {
        let store = InMemoryDeckStore(seededWith: [
            Deck(id: "d", title: "Deck", cards: [
                card(id: "new"),
                card(id: "learning", sr: scheduled(days: 6)),
                card(id: "mastered", sr: scheduled(days: 40, reps: 5))
            ])
        ])
        let viewModel = DeckOverviewViewModel(deckId: "d", store: store)

        await viewModel.load()

        #expect(viewModel.dueCount == 1)
        #expect(viewModel.newCount == 1)
        #expect(viewModel.learningCount == 1)
        #expect(viewModel.masteredCount == 1)
        #expect(viewModel.canStudy)
    }

    @Test("A deck that no longer exists is reported as missing")
    func overviewMissing() async {
        let viewModel = DeckOverviewViewModel(deckId: "gone", store: InMemoryDeckStore())

        await viewModel.load()

        #expect(viewModel.isMissing)
        #expect(viewModel.deck == nil)
    }

    @Test("Renaming trims the title and ignores a blank one")
    func overviewRename() async throws {
        let store = InMemoryDeckStore(seededWith: [Deck(id: "d", title: "Old", cards: [card(id: "c1")])])
        let viewModel = DeckOverviewViewModel(deckId: "d", store: store)
        await viewModel.load()

        await viewModel.rename(to: "   ")
        #expect(viewModel.deck?.title == "Old")

        await viewModel.rename(to: "  New name  ")
        #expect(viewModel.deck?.title == "New name")
        #expect(try await store.deck(id: "d")?.title == "New name")
    }

    @Test("A long deck title is cut to the limit")
    func overviewRenameLimit() async {
        let store = InMemoryDeckStore(seededWith: [Deck(id: "d", title: "Old", cards: [])])
        let viewModel = DeckOverviewViewModel(deckId: "d", store: store)
        await viewModel.load()

        await viewModel.rename(to: String(repeating: "a", count: 200))

        #expect(viewModel.deck?.title.count == FlashcardLimits.deckTitleMaxCharacters)
    }

    @Test("Adding, editing and deleting a card persists each change")
    func overviewCardEditing() async throws {
        let store = InMemoryDeckStore(seededWith: [Deck(id: "d", title: "Deck", cards: [card(id: "c1")])])
        let viewModel = DeckOverviewViewModel(deckId: "d", store: store)
        await viewModel.load()

        await viewModel.addCard(front: "  Front  ", back: "Back")
        #expect(viewModel.cards.count == 2)
        #expect(viewModel.cards.last?.front == "Front")
        #expect(viewModel.cards.last?.aiDrafted == false)

        await viewModel.updateCard(id: "c1", front: "Edited", back: "Answer")
        #expect(viewModel.cards.first?.front == "Edited")

        await viewModel.updateCard(id: "c1", front: " ", back: "Answer")
        #expect(viewModel.cards.first?.front == "Edited")

        await viewModel.deleteCard(id: "c1")
        let saved = try await store.deck(id: "d")
        #expect(saved?.cards.count == 1)
        #expect(saved?.cards.contains { $0.id == "c1" } == false)
    }

    @Test("A blank card is never added")
    func overviewBlankCard() async {
        let store = InMemoryDeckStore(seededWith: [Deck(id: "d", title: "Deck", cards: [])])
        let viewModel = DeckOverviewViewModel(deckId: "d", store: store)
        await viewModel.load()

        await viewModel.addCard(front: "", back: "Back")
        await viewModel.addCard(front: "Front", back: "   ")

        #expect(viewModel.cards.isEmpty)
    }

    @Test("Deleting the deck marks it deleted")
    func overviewDeleteDeck() async throws {
        let store = InMemoryDeckStore(seededWith: [Deck(id: "d", title: "Deck", cards: [])])
        let viewModel = DeckOverviewViewModel(deckId: "d", store: store)
        await viewModel.load()

        await viewModel.deleteDeck()

        #expect(viewModel.isDeleted)
        #expect(try await store.deck(id: "d") == nil)
    }

    @Test("Nothing due shows when the next card is due")
    func overviewCaughtUp() async {
        let store = InMemoryDeckStore(seededWith: [
            Deck(id: "d", title: "Deck", cards: [card(id: "c1", sr: scheduled(days: 3))])
        ])
        let viewModel = DeckOverviewViewModel(deckId: "d", store: store)

        await viewModel.load()

        #expect(viewModel.canStudy == false)
        #expect(viewModel.caughtUpText != nil)
    }

    @Test("Mastery grows with each card's interval up to a month")
    func masteryShare() {
        let deck = Deck(title: "Deck", cards: [
            card(id: "new"),
            card(id: "half", sr: scheduled(days: 15)),
            card(id: "full", sr: scheduled(days: 90, reps: 6))
        ])

        #expect(deck.masteryPercent == 50)
        #expect(Deck(title: "Empty").masteryPercent == 0)
    }

    @Test("The last review date is worked back from the due date")
    func lastReviewed() {
        let reviewedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let due = Calendar.current.date(byAdding: .day, value: 6, to: reviewedAt) ?? reviewedAt
        let deck = Deck(title: "Deck", cards: [
            card(id: "new"),
            card(id: "seen", sr: SpacedRepetitionState(interval: 6, dueAt: due, reps: 2))
        ])

        #expect(deck.lastReviewedAt == reviewedAt)
        #expect(Deck(title: "Fresh", cards: [card(id: "new")]).lastReviewedAt == nil)
    }

    @Test("The next due date ignores cards that are already due")
    func nextDue() {
        let now = Date.now
        let soon = now.addingTimeInterval(3_600)
        let later = now.addingTimeInterval(86_400)
        let deck = Deck(title: "Deck", cards: [
            card(id: "due"),
            card(id: "later", sr: SpacedRepetitionState(interval: 1, dueAt: later, reps: 1)),
            card(id: "soon", sr: SpacedRepetitionState(interval: 1, dueAt: soon, reps: 1))
        ])

        #expect(deck.nextDueDate(after: now) == soon)
    }

    @Test("Card mastery follows the scheduling state")
    func cardMastery() {
        #expect(CardMastery(SpacedRepetitionState()) == .new)
        #expect(CardMastery(scheduled(days: 6)) == .learning)
        #expect(CardMastery(SpacedRepetitionState(interval: 0, reps: 0, lapses: 1)) == .learning)
        #expect(CardMastery(scheduled(days: 30, reps: 4)) == .mastered)
    }

    @Test("Questions that differ only in case and punctuation count as the same")
    func normalisedText() {
        #expect(FlashcardText.normalized("What is a Leaf?") == FlashcardText.normalized("what is a leaf"))
        #expect(FlashcardText.normalized("What is a leaf?") != FlashcardText.normalized("What is a root?"))
    }

    @Test("An answer splits into a headline and an explanation on its first line break")
    func answerParts() {
        let split = FlashcardAnswer("O(log n)\nEach comparison halves the tree.")
        #expect(split.headline == "O(log n)")
        #expect(split.detail == "Each comparison halves the tree.")
        #expect(split.isShort)

        let single = FlashcardAnswer("A node with no children.")
        #expect(single.headline == "A node with no children.")
        #expect(single.detail == nil)
    }

    @Test("Easy, Medium and Hard map onto the generator's difficulty levels")
    func difficultyLevels() {
        #expect(FlashcardDifficulty.levels == [.recall, .mixed, .understanding])
        #expect(FlashcardDifficulty.levels.count == FlashcardDifficulty.allCases.count)
    }
}
