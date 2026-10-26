//
//  RecallSessionViewModel.swift
//  StudyForge
//
//  Presentation logic for F17's sitting (docs/03 §O, O02 and O03): show a card, reveal it, rate it,
//  and let the learning steps decide whether it comes back before the learner leaves.
//
//  WHY THIS IS ITS OWN MODEL AND NOT `FlashcardReviewViewModel`
//  -----------------------------------------------------------
//  F04 reviews ONE deck and hands every rating straight to SM-2. A sitting in the Recall Space has
//  two schedulers: the learning steps answer "does this come back in a minute?", and
//  `SpacedRepetition` answers "when, in days?". Reusing F04's model would mean either growing the
//  steps inside M2's file or editing it, so F17 gets its own — as the brief requires
//  (docs/TODO-M5-fatema.md §F17: "F17 also gets its own `RecallSessionViewModel`").
//
//  THE RULE THAT KEEPS SM-2 THE SINGLE SOURCE OF TRUTH
//  --------------------------------------------------
//  A review is always rescheduled by `SpacedRepetition.nextState`, and a test asserts the resulting
//  state field for field against the engine's own output. Graduation is the one exception, and it is
//  not a second copy of the maths: when a card leaves the learning steps the LEARNER'S graduating
//  interval wins, so calling `nextState` there would produce 1 day from `reps == 1` and silently
//  overwrite the setting. The date is still computed by the engine's own `dueDate(days:from:)`.
//
//  WHY A CARD THAT STAYS IS MOVED, NOT DUPLICATED
//  ----------------------------------------------
//  `items` holds each card at most once, and the card at the front is the one on screen. Rating
//  "Again" moves that item to the back, so progress is simply `total - items.count` and it never
//  grows as a learner fails a card. Appending a copy instead would make the denominator drift and
//  the progress bar lie — the exact defect F04 avoids by ending the session on a lapse.
//
//  WHY THERE IS NO `close()`
//  -------------------------
//  Every rating is written through the deck store before the next card appears, exactly as F04
//  does, so dismissing mid-sitting loses nothing. A `close()` that only set `.summary` would be
//  dead code dressed as a feature.
//
//  WHY THERE IS NO COPY IN THIS FILE
//  --------------------------------
//  Every string a screen shows needs a case in `Core/Localisation/L10n.swift` AND an entry in both
//  `Localizable.strings` catalogues — `L10nTests` fails in both directions and
//  `tools/check-strings.py` checks English/Arabic parity. The `.strings` files are SHARED and in
//  F17's lane; `L10n.swift` is not, so the copy ships with O02/O03 in the commit that adds those
//  cases. Until then this model exposes data, numbers and states — never prose.
//

import Foundation

@MainActor
@Observable
final class RecallSessionViewModel {

    // MARK: State

    /// The sitting's lifecycle. A session does not load, so it has no `LoadState`: it is either
    /// being answered, finished, or was never worth starting.
    enum Phase: Equatable {
        case reviewing
        case summary
        case empty
    }

    /// What each rating button would do, in the units O03 prints under it.
    ///
    /// Two units rather than one because the steps are sub-day and SM-2 is in whole days; a single
    /// "interval" would have to fake one of them.
    struct RatingPreview: Equatable, Sendable {

        /// True when the card comes back inside this sitting.
        let staysInSteps: Bool

        /// The learning step it would return at, in minutes. `nil` once the card graduates.
        let stepMinutes: Int?

        /// The interval it would be scheduled at, in days. `nil` while it is still learning.
        let intervalDays: Int?
    }

    /// The cards not yet finished, in the order they are answered. The front item is on screen.
    private(set) var items: [RecallQueueItem]

    private(set) var isShowingAnswer = false
    private(set) var phase: Phase

    /// How many cards this sitting is counting. The denominator of O02's "7 / 20".
    ///
    /// Fixed at the start, and lowered only when the sitting itself shrinks — a card deleted
    /// elsewhere, or unseen cards deferred by a tightened ceiling. A card that comes back through the
    /// steps never changes it, which is what stops the progress bar moving backwards.
    private(set) var total: Int

    /// Every rating given, including repeat ratings of the same card. O03's summary counts answers,
    /// while `completedCount` counts cards.
    private(set) var answeredCount = 0

    /// Cards that left the learning steps during this sitting.
    private(set) var graduatedCount = 0

    /// Every "Again". Counted separately because it is the one honest signal of difficulty: a
    /// learner failing nothing is usually a learner being shown nothing new.
    private(set) var againCount = 0

    /// Cards dropped because a ceiling was tightened mid-sitting. Surfaced rather than hidden, for
    /// the same reason `RecallQueue.deferredByLimit` is: a queue that shrinks silently teaches the
    /// learner not to trust the number.
    private(set) var deferredCount = 0

    private(set) var error: AppError?

    /// Card id to zero-based learning step, for the cards still inside the steps.
    ///
    /// Held here and nowhere else: F17 never writes learning state onto `Flashcard` and never
    /// touches `SpacedRepetitionState`. The steps belong to the sitting, so they die with it.
    private(set) var learningSteps: [String: Int]

    /// The decks the sitting was built from, kept current as cards are rated, so a card that comes
    /// back through the steps is rescheduled from its own latest state rather than a stale copy.
    private var decks: [Deck]

    private let store: any DeckStore
    private var settings: RecallSettings

    /// The clock, injected so a test can pin "now" instead of waiting a day for an interval.
    private let now: @Sendable () -> Date

    // MARK: Init

    /// - Parameters:
    ///   - items: the queue to answer, as built by `RecallQueueBuilder`.
    ///   - decks: the same decks the queue was built from, so a rating can be written back.
    ///   - settings: the learner's steps and ceilings, held by value — a mid-sitting change arrives
    ///     through `update(settings:)` rather than mutating the caller's copy.
    ///   - learningSteps: the steps already in progress. Any item that arrives carrying a step of
    ///     its own seeds this, so a restored sitting cannot silently demote learning to reviews.
    init(
        items: [RecallQueueItem],
        decks: [Deck],
        store: any DeckStore,
        settings: RecallSettings = .default,
        learningSteps: [String: Int] = [:],
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.items = items
        self.decks = decks
        self.store = store
        self.settings = settings
        self.now = now
        self.total = items.count

        var seeded = learningSteps
        for item in items {
            if let step = item.learningStep, seeded[item.card.id] == nil {
                seeded[item.card.id] = step
            }
        }
        self.learningSteps = seeded

        self.phase = items.isEmpty ? .empty : .reviewing
    }

    // MARK: Derived

    /// The card on screen. `nil` once the sitting is over.
    var currentItem: RecallQueueItem? { items.first }

    var currentCard: Flashcard? { items.first?.card }

    /// The deck name O02 shows above the question.
    var deckTitle: String? { items.first?.deckTitle }

    /// The state chip O02 shows beside it.
    var stateChip: RecallCardState? { items.first?.state }

    /// The citation O03 prints under the answer, taken from provenance rather than from the model.
    var citationLabel: String? { items.first?.card.provenance.citationLabel }

    /// Cards finished: the ones that have left the sitting.
    var completedCount: Int { max(0, total - items.count) }

    /// Cards still to answer.
    var remainingCount: Int { items.count }

    /// 0…1. Zero for an empty sitting, so a progress bar never divides by zero.
    var progressFraction: Double {
        total == 0 ? 0 : Double(completedCount) / Double(total)
    }

    // MARK: Actions

    /// Flips the card to its answer. Idempotent, so a double tap cannot skip a card.
    func reveal() {
        isShowingAnswer = true
    }

    /// Answers the card on screen and moves the sitting on.
    ///
    /// The rating is one synchronous decision followed by one write, so the screen can never show a
    /// card whose scheduling state has not been decided yet.
    func rate(_ rating: ReviewRating) async {
        guard phase == .reviewing, let item = items.first else { return }

        let instant = now()
        let previous = item.card
        var card = previous
        var state = item.state
        var step = effectiveStep(for: item)
        var stays = false

        answeredCount += 1
        if rating == .again { againCount += 1 }

        if let currentStep = step {
            // Still learning, so the steps — not SM-2 — decide what happens next.
            switch RecallLearning.outcome(step: currentStep, rating: rating, settings: settings) {
            case .stay(let next):
                step = next
                state = .learning
                stays = true
            case .restart:
                step = RecallLearning.firstStep
                state = .learning
                stays = true
            case .graduate(let intervalDays):
                step = nil
                card.sr = Self.graduated(previous.sr, intervalDays: intervalDays, at: instant)
                state = settings.state(for: card.sr, isLearning: false)
                graduatedCount += 1
            }
        } else {
            // Graduated: the scheduler is the only thing allowed to set this card's interval.
            card.sr = SpacedRepetition.nextState(previous.sr, rating: rating, now: instant)

            if rating == .again {
                // A lapse re-enters the first step instead of disappearing until tomorrow. This is
                // the ONE place F17 deliberately differs from F04 (which ends the sitting and lets
                // "Keep going" pick the lapse up), and it is what makes the steps mean something in
                // a daily space: the thing just failed is the thing brought back.
                step = RecallLearning.firstStep
                state = .learning
                stays = true
            } else {
                state = settings.state(for: card.sr, isLearning: false)
            }
        }

        if let step {
            learningSteps[card.id] = step
        } else {
            learningSteps.removeValue(forKey: card.id)
        }

        items.removeFirst()
        if stays {
            items.append(
                RecallQueueItem(
                    id: item.id,
                    deckId: item.deckId,
                    deckTitle: item.deckTitle,
                    card: card,
                    state: state,
                    learningStep: step
                )
            )
        }

        isShowingAnswer = false
        settlePhase(completed: completedCount)

        // In memory first, then the store: a card returning through the steps must be rescheduled
        // from its own new state, and the write must not wait on the next card being drawn.
        updateDeck(item.deckId, with: card, at: instant)
        await persist(deckId: item.deckId)
    }

    /// What a rating would do to the card on screen, for the four buttons' interval hints.
    ///
    /// Returns `nil` only when there is no card to rate. The numbers are raw — formatting ("1m",
    /// "1d", "3mo") belongs to the view, which can localise it.
    func preview(for rating: ReviewRating) -> RatingPreview? {
        guard let item = items.first else { return nil }
        let card = item.card

        if let step = effectiveStep(for: item) {
            switch RecallLearning.outcome(step: step, rating: rating, settings: settings) {
            case .stay(let next):
                return RatingPreview(
                    staysInSteps: true,
                    stepMinutes: Self.minutes(at: next, in: settings),
                    intervalDays: nil
                )
            case .restart:
                return RatingPreview(
                    staysInSteps: true,
                    stepMinutes: Self.minutes(at: RecallLearning.firstStep, in: settings),
                    intervalDays: nil
                )
            case .graduate(let intervalDays):
                return RatingPreview(staysInSteps: false, stepMinutes: nil, intervalDays: intervalDays)
            }
        }

        let next = SpacedRepetition.nextState(card.sr, rating: rating, now: now())
        guard next.interval > 0 else {
            // A lapse: the card returns inside this sitting, at the first step.
            return RatingPreview(
                staysInSteps: true,
                stepMinutes: Self.minutes(at: RecallLearning.firstStep, in: settings),
                intervalDays: nil
            )
        }
        return RatingPreview(staysInSteps: false, stepMinutes: nil, intervalDays: next.interval)
    }

    /// Applies new limits or steps to the cards not yet answered — O04 is reachable mid-sitting.
    ///
    /// Cards already answered are never taken away, because that would discard work done. What a
    /// tightened ceiling does take away is cards the learner has not seen: those are added to
    /// `deferredCount`, so the screen can say how many moved to tomorrow instead of the queue
    /// quietly shrinking.
    func update(settings newSettings: RecallSettings) {
        settings = newSettings

        let completed = completedCount
        let shownCardID = items.first?.id
        var newAdmitted = 0
        var reviewsAdmitted = 0
        var kept: [RecallQueueItem] = []
        var dropped = 0

        for item in items {
            switch item.state {
            case .learning:
                kept.append(item)
            case .new:
                if newAdmitted < newSettings.newCardsPerDay {
                    newAdmitted += 1
                    kept.append(item)
                } else {
                    dropped += 1
                    learningSteps.removeValue(forKey: item.card.id)
                }
            case .young, .mature:
                if reviewsAdmitted < newSettings.maxReviewsPerDay {
                    reviewsAdmitted += 1
                    kept.append(item)
                } else {
                    dropped += 1
                }
            }
        }

        items = kept
        total = completed + kept.count
        deferredCount += dropped
        // Only hide the answer if the card on screen changed: a learner reading an answer who pops
        // into settings and comes back should find the answer still there.
        if items.first?.id != shownCardID { isShowingAnswer = false }
        settlePhase(completed: completed)
    }

    /// Reconciles the sitting with fresh decks.
    ///
    /// This is the "a card was deleted by another screen mid-sitting" edge case, and also how a
    /// renamed deck reaches O02's title. Cards that still exist are re-read so their chip cannot go
    /// stale; cards that vanished are dropped and no longer counted in `total`.
    func refresh(decks freshDecks: [Deck]) {
        var present: [String: (deckId: String, title: String, card: Flashcard)] = [:]
        for deck in freshDecks {
            for card in deck.cards {
                present[card.id] = (deckId: deck.id, title: deck.title, card: card)
            }
        }

        let completed = completedCount
        let shownCardID = items.first?.id
        items = items.compactMap { item in
            guard let match = present[item.card.id] else {
                learningSteps.removeValue(forKey: item.card.id)
                return nil
            }
            let step = learningSteps[item.card.id]
            return RecallQueueItem(
                id: item.id,
                deckId: match.deckId,
                deckTitle: match.title,
                card: match.card,
                state: settings.state(for: match.card.sr, isLearning: step != nil),
                learningStep: step
            )
        }
        decks = freshDecks
        total = completed + items.count
        // A deleted card must not hand its revealed answer to the card that takes its place.
        if items.first?.id != shownCardID { isShowingAnswer = false }
        settlePhase(completed: completed)
    }

    /// Keeps the phase honest after the queue shrinks. A sitting that never had a card is `.empty`;
    /// one that ran out after answering at least one is a `.summary`.
    private func settlePhase(completed: Int) {
        if items.isEmpty {
            phase = completed > 0 ? .summary : .empty
        } else if phase != .reviewing {
            phase = .reviewing
        }
    }

    // MARK: Scheduling

    /// The step the card is answered *from*.
    ///
    /// A card that has never been reviewed is at the first step even though nothing has stored a
    /// step for it yet — that is the whole point of a learning step: the first "Good" should buy ten
    /// minutes, not a day. Keeping the rule here rather than seeding `learningSteps` at init means a
    /// new card still counts as new for the daily ceiling and for `refresh`.
    private func effectiveStep(for item: RecallQueueItem) -> Int? {
        if let step = learningSteps[item.card.id] { return step }
        return item.state == .new ? RecallLearning.firstStep : nil
    }

    /// The SM-2 state a card graduates to.
    ///
    /// Deliberately NOT `SpacedRepetition.nextState` — see the header. Ease and lapse history are
    /// preserved, `reps` is raised to at least 1 so `RecallCardState` reads the card as graduated
    /// rather than new, and the date comes from the engine's own `dueDate(days:from:)`.
    private static func graduated(
        _ sr: SpacedRepetitionState,
        intervalDays: Int,
        at instant: Date
    ) -> SpacedRepetitionState {
        var next = sr
        next.interval = max(1, intervalDays)
        next.reps = max(1, sr.reps)
        next.dueAt = SpacedRepetition.dueDate(days: next.interval, from: instant)
        return next
    }

    /// The minutes for a step, tolerating a ladder that shrank mid-sitting.
    private static func minutes(at step: Int, in settings: RecallSettings) -> Int? {
        let steps = settings.learningStepMinutes
        if steps.indices.contains(step) { return steps[step] }
        return steps.first
    }

    // MARK: Persistence

    /// Writes a rated card back into the in-memory copy of its deck.
    private func updateDeck(_ deckId: String, with card: Flashcard, at instant: Date) {
        guard let deckIndex = decks.firstIndex(where: { $0.id == deckId }),
              let cardIndex = decks[deckIndex].cards.firstIndex(where: { $0.id == card.id })
        else { return }
        decks[deckIndex].cards[cardIndex] = card
        decks[deckIndex].updatedAt = instant
    }

    /// Writes the deck after every rating, so closing mid-sitting keeps the answers already given.
    ///
    /// The store is the local file, so this holds offline. A failure is surfaced rather than
    /// swallowed: the answer stays (the learner did answer it), but it is honestly not saved, which
    /// means the card is simply asked again next time rather than silently marked as learned.
    private func persist(deckId: String) async {
        guard let deck = decks.first(where: { $0.id == deckId }) else { return }
        do {
            try await store.add(deck)
        } catch {
            self.error = AppError.from(error)
        }
    }
}
