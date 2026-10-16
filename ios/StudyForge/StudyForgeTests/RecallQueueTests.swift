//
//  RecallQueueTests.swift
//  StudyForgeTests
//
//  Tests for F17's cross-deck queue — the one thing that makes the Recall Space different from
//  reviewing a single deck.
//
//  THE TEST THAT MATTERS MOST is `gathersCardsFromMoreThanOneDeck`: if the queue only ever saw
//  one deck it would still look correct on a single-deck account, and the feature would be a
//  duplicate of F04 rather than an Anki-style study space. The rest cover the ordering and the
//  daily ceilings, both of which are silent when wrong.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("F17 recall queue")
struct RecallQueueTests {

    private let now = Date(timeIntervalSince1970: 2_000_000)

    // MARK: Fixtures

    private func card(_ id: String, sr: SpacedRepetitionState) -> Flashcard {
        Flashcard(
            id: id,
            front: "front \(id)",
            back: "back \(id)",
            provenance: AIProvenance(materialId: "m", pageNumbers: [1], confidence: .high),
            sr: sr
        )
    }

    /// A card that has never been reviewed — Anki's "new".
    private func newCard(_ id: String) -> Flashcard {
        card(id, sr: SpacedRepetitionState(ease: 2.5, interval: 0, dueAt: now, reps: 0, lapses: 0))
    }

    /// A graduated card, due at `dueAt`, with the given interval in days.
    private func reviewCard(_ id: String, interval: Int, dueAt: Date) -> Flashcard {
        card(id, sr: SpacedRepetitionState(ease: 2.5, interval: interval, dueAt: dueAt,
                                           reps: 3, lapses: 0))
    }

    private func deck(_ id: String, _ title: String, _ cards: [Flashcard]) -> Deck {
        Deck(id: id, title: title, cards: cards)
    }

    // MARK: The headline behaviour

    @Test("The queue gathers due cards from MORE THAN ONE deck")
    func gathersCardsFromMoreThanOneDeck() {
        let decks = [
            deck("d1", "Chemistry", [newCard("c1"), newCard("c2")]),
            deck("d2", "Biology", [newCard("c3")])
        ]

        let queue = RecallQueueBuilder.build(decks: decks, now: now)

        #expect(queue.items.count == 3)
        #expect(Set(queue.items.map(\.deckId)) == ["d1", "d2"])
        #expect(queue.count(of: .new) == 3)
    }

    @Test("Cards that are not due are left out")
    func notDueCardsAreExcluded() {
        let later = now.addingTimeInterval(86_400)
        let decks = [
            deck("d1", "Chemistry", [
                newCard("due-now"),
                reviewCard("not-yet", interval: 6, dueAt: later)
            ])
        ]

        let queue = RecallQueueBuilder.build(decks: decks, now: now)

        #expect(queue.items.map(\.id) == ["due-now"])
    }

    // MARK: Ordering

    @Test("Learning cards come first, then reviews oldest-due-first, then new cards")
    func orderingIsLearningThenReviewsThenNew() {
        let early = now.addingTimeInterval(-7_200)
        let later = now.addingTimeInterval(-3_600)

        let decks = [
            deck("d1", "Mixed", [
                newCard("new-1"),
                reviewCard("review-late", interval: 6, dueAt: later),
                reviewCard("review-early", interval: 6, dueAt: early),
                newCard("learning-1")
            ])
        ]

        let queue = RecallQueueBuilder.build(
            decks: decks,
            learningSteps: ["learning-1": 1],
            now: now
        )

        #expect(queue.items.map(\.id) == ["learning-1", "review-early", "review-late", "new-1"])
    }

    @Test("A card inside the learning steps is reported as learning, with its step")
    func learningCardCarriesItsStep() {
        let decks = [deck("d1", "Chemistry", [newCard("c1")])]

        let queue = RecallQueueBuilder.build(decks: decks, learningSteps: ["c1": 1], now: now)

        #expect(queue.items.first?.state == .learning)
        #expect(queue.items.first?.learningStep == 1)
    }

    @Test("A graduated card past the maturity threshold is counted mature")
    func matureCardsAreCounted() {
        let decks = [
            deck("d1", "Chemistry", [
                reviewCard("young", interval: 6, dueAt: now),
                reviewCard("mature", interval: 40, dueAt: now)
            ])
        ]

        let queue = RecallQueueBuilder.build(decks: decks, now: now)

        #expect(queue.count(of: .young) == 1)
        #expect(queue.count(of: .mature) == 1)
    }

    // MARK: Daily ceilings

    @Test("New cards are capped at the learner's daily limit, and the remainder is reported")
    func newCardsAreCapped() {
        let cards = (1...5).map { newCard("c\($0)") }
        let decks = [deck("d1", "Chemistry", cards)]

        let queue = RecallQueueBuilder.build(
            decks: decks,
            settings: RecallSettings(newCardsPerDay: 2),
            now: now
        )

        #expect(queue.items.count == 2)
        #expect(queue.count(of: .new) == 2)
        #expect(queue.deferredByLimit == 3)
    }

    @Test("Reviews are capped at the learner's daily limit")
    func reviewsAreCapped() {
        let cards = (1...4).map { reviewCard("r\($0)", interval: 6, dueAt: now) }
        let decks = [deck("d1", "Chemistry", cards)]

        let queue = RecallQueueBuilder.build(
            decks: decks,
            settings: RecallSettings(maxReviewsPerDay: 1),
            now: now
        )

        #expect(queue.items.count == 1)
        #expect(queue.count(of: .young) == 1)
        #expect(queue.deferredByLimit == 3)
    }

    @Test("Learning cards are NOT capped, so a card you just failed always comes back")
    func learningCardsBypassTheCeiling() {
        // The learner has exhausted their review quota, but three cards are mid-learning-step.
        // Dropping them would mean the thing they just failed is never asked again today.
        let decks = [
            deck("d1", "Chemistry", (1...3).map { newCard("c\($0)") })
        ]

        let queue = RecallQueueBuilder.build(
            decks: decks,
            settings: RecallSettings(newCardsPerDay: 0, maxReviewsPerDay: 0),
            learningSteps: ["c1": 0, "c2": 1, "c3": 0],
            now: now
        )

        #expect(queue.items.count == 3)
        #expect(queue.count(of: .learning) == 3)
    }

    @Test("A zero ceiling yields an empty queue rather than a crash")
    func zeroCeilingsAreHonest() {
        let decks = [deck("d1", "Chemistry", [newCard("c1"), newCard("c2")])]

        let queue = RecallQueueBuilder.build(
            decks: decks,
            settings: RecallSettings(newCardsPerDay: 0, maxReviewsPerDay: 0),
            now: now
        )

        #expect(queue.isEmpty)
        #expect(queue.deferredByLimit == 2)
    }

    // MARK: Scoping

    @Test("A deck filter scopes the queue to that deck")
    func deckFilterScopesTheQueue() {
        let decks = [
            deck("d1", "Chemistry", [newCard("c1")]),
            deck("d2", "Biology", [newCard("c2")])
        ]

        let queue = RecallQueueBuilder.build(decks: decks, now: now, deckFilter: "d2")

        #expect(queue.items.map(\.id) == ["c2"])
        #expect(queue.count(of: .new) == 1)
    }

    @Test("An unknown deck filter yields an empty queue")
    func unknownFilterIsEmpty() {
        let decks = [deck("d1", "Chemistry", [newCard("c1")])]

        let queue = RecallQueueBuilder.build(decks: decks, now: now, deckFilter: "nope")

        #expect(queue.isEmpty)
        #expect(queue.deferredByLimit == 0)
    }

    @Test("No decks at all is an empty queue, not a failure")
    func noDecksIsEmpty() {
        let queue = RecallQueueBuilder.build(decks: [], now: now)
        #expect(queue.isEmpty)
        #expect(queue.counts.isEmpty)
    }
}
