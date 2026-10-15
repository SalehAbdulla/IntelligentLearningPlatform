//
//  RecallQueue.swift
//  StudyForge
//
//  F17 — the cross-deck "due today" queue behind the Active Recall Space (docs/03 §O, O01).
//
//  WHY ONE QUEUE AND NOT ONE DECK AT A TIME
//  ----------------------------------------
//  F04 reviews a single deck: you choose the deck, then you see what that deck owes you. That is
//  the wrong shape for daily revision, because the question a student actually has is "what does
//  everything owe me today?", and answering it by opening six decks is how revision stops
//  happening. Anki's central idea is exactly this: one queue, assembled across every deck.
//
//  WHY THE LIMITS ARE APPLIED HERE AND NOT IN THE STORE
//  ---------------------------------------------------
//  `DeckStore` answers "what decks exist?". The daily ceilings are a property of ONE learner's
//  day, not of the decks, so they are applied while the queue is built and never written back.
//  That keeps the store dumb, the limits testable without a device, and a learner's ceilings
//  from being silently baked into their card data.
//
//  WHY LEARNING CARDS ARE NOT CAPPED
//  ---------------------------------
//  A card in a learning step is due within the sitting by definition. Counting it against the
//  review ceiling would mean a learner who answers "again" a few times silently runs out of
//  quota and stops being asked the thing they just failed, which is the opposite of the feature.
//

import Foundation

/// One card in the Recall Space, with the deck it came from and its derived state.
struct RecallQueueItem: Identifiable, Equatable, Sendable {

    /// The card's own id, so a queue never needs a composite key to be `Identifiable`.
    let id: String

    let deckId: String
    let deckTitle: String
    let card: Flashcard

    /// The state O01 counts and O02 chips.
    let state: RecallCardState

    /// The learning step the card sits at, when it is still learning. `nil` once graduated.
    let learningStep: Int?
}

/// A built queue: the ordered cards, plus the counters O01 shows before the learner starts.
struct RecallQueue: Equatable, Sendable {

    /// Learning cards first, then due reviews, then new cards — the order they are answered in.
    let items: [RecallQueueItem]

    /// How many cards of each state the queue holds, for O01's counters.
    let counts: [RecallCardState: Int]

    /// How many cards were left out because a daily ceiling was reached.
    ///
    /// Surfaced rather than hidden: "18 more due tomorrow" is information a learner can act on,
    /// and a queue that silently truncates teaches them not to trust the number.
    let deferredByLimit: Int

    var isEmpty: Bool { items.isEmpty }

    func count(of state: RecallCardState) -> Int { counts[state] ?? 0 }
}

/// Builds the Recall Space queue. A namespace of pure functions, like `SpacedRepetition`.
enum RecallQueueBuilder {

    /// Assembles the queue from every deck the learner has.
    ///
    /// - Parameters:
    ///   - decks: every deck; a deck with no due cards simply contributes nothing.
    ///   - settings: the learner's ceilings and learning steps.
    ///   - learningSteps: card id to zero-based learning step, for cards still in the steps.
    ///     Held outside `SpacedRepetitionState` on purpose: the steps are a property of the
    ///     sitting, and keeping them here means F17 never edits the SM-2 engine or `Flashcard`.
    ///   - now: the instant the queue is built, injected so a test can pin it.
    ///   - deckFilter: when set, only this deck contributes — O06's "scope the queue".
    static func build(
        decks: [Deck],
        settings: RecallSettings = .default,
        learningSteps: [String: Int] = [:],
        now: Date = .now,
        deckFilter: String? = nil
    ) -> RecallQueue {

        // A stable deck order, so the same store always produces the same queue. `DeckStore.all()`
        // already returns most-recently-updated first, but sorting by title here makes the queue
        // independent of that contract.
        let scoped = decks
            .filter { deckFilter == nil || $0.id == deckFilter }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }

        var learning: [RecallQueueItem] = []
        var reviews: [RecallQueueItem] = []
        var newCards: [RecallQueueItem] = []

        for deck in scoped {
            for card in deck.cards {
                let step = learningSteps[card.id]
                let isLearning = step != nil
                let state = settings.state(for: card.sr, isLearning: isLearning)

                // A card is only ever in the queue because it is DUE. `isDue` is the scheduler's
                // own rule, not a second copy of it.
                guard card.sr.isDue(now: now) || isLearning else { continue }

                let item = RecallQueueItem(
                    id: card.id,
                    deckId: deck.id,
                    deckTitle: deck.title,
                    card: card,
                    state: state,
                    learningStep: step
                )

                switch state {
                case .learning: learning.append(item)
                case .new: newCards.append(item)
                case .young, .mature: reviews.append(item)
                }
            }
        }

        // Reviews are oldest-due-first, which is the scheduler's own priority order.
        reviews.sort { $0.card.sr.dueAt < $1.card.sr.dueAt }

        let admittedReviews = Array(reviews.prefix(settings.maxReviewsPerDay))
        let admittedNew = Array(newCards.prefix(settings.newCardsPerDay))
        let deferred = (reviews.count - admittedReviews.count) + (newCards.count - admittedNew.count)

        let items = learning + admittedReviews + admittedNew

        var counts: [RecallCardState: Int] = [:]
        for item in items { counts[item.state, default: 0] += 1 }

        return RecallQueue(items: items, counts: counts, deferredByLimit: deferred)
    }

    // TODO(M5 · F17): Build the O01 Recall Space screen on top of this queue — the due-today
    // total, the four state counters and the Start action — and the O02/O03 session screens on
    // top of `RecallLearning.outcome`. Add the localisation keys in the same commit.
    // Done when: the Recall Space opens from the Decks list, gathers cards from more than one
    // deck, and a test drives a full session through the learning steps to graduation.
}
