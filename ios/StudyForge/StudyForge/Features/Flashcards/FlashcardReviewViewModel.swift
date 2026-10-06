//
//  FlashcardReviewViewModel.swift
//  StudyForge
//
//  Presentation logic for E05–E07 — a review session: flip a card, rate it, and let SM-2 write
//  the next due date.
//
//  WHY "AGAIN" DOES NOT RE-QUEUE
//  -----------------------------
//  A lapsed card gets `interval = 0` and `dueAt = now` — it is immediately due again. So instead
//  of re-queueing it within this pass, the session ends and "Keep going" starts a fresh pass over
//  the cards that are due now, which includes every lapse. That is the SM-2 behaviour, and it
//  keeps the progress counter honest ("7 of 20") rather than growing as cards lapse.
//

import Foundation

@MainActor
@Observable
final class FlashcardReviewViewModel {

    enum Phase: Equatable {
        case reviewing
        case summary
        case empty
    }

    private(set) var cards: [Flashcard]
    private(set) var currentIndex = 0
    private(set) var isShowingAnswer = false
    private(set) var phase: Phase

    private(set) var reviewedCount = 0
    private(set) var correctCount = 0
    private(set) var error: AppError?

    private var deck: Deck
    private let store: any DeckStore

    init(deck: Deck, store: any DeckStore) {
        self.deck = deck
        self.store = store
        let due = deck.cards.filter { $0.sr.isDue() }
        self.cards = due
        self.phase = due.isEmpty ? .empty : .reviewing
    }

    // MARK: Derived

    var currentCard: Flashcard? {
        cards.indices.contains(currentIndex) ? cards[currentIndex] : nil
    }

    var progress: String { L10n.flashcardProgress.string(currentIndex + 1, cards.count) }

    /// 0…1. Zero when nothing has been answered, so the summary never divides by zero.
    var accuracy: Double {
        reviewedCount == 0 ? 0 : Double(correctCount) / Double(reviewedCount)
    }

    var accuracyPercent: Int { Int((accuracy * 100).rounded()) }

    var citationLabel: String? {
        guard let card = currentCard else { return nil }
        return card.provenance.pageNumbers.isEmpty ? L10n.flashcardSource.string : card.provenance.citationLabel
    }

    // MARK: Copy

    var title: String { L10n.flashcardReviewTitle.string }
    var tapToReveal: String { L10n.flashcardTapToReveal.string }
    var sessionTitle: String { L10n.flashcardSessionTitle.string }
    var reviewedLabel: String { L10n.flashcardSessionReviewed.string }
    var accuracyLabel: String { L10n.flashcardSessionAccuracy.string }
    var doneTitle: String { L10n.flashcardSessionDone.string }
    var keepGoingTitle: String { L10n.flashcardSessionKeepGoing.string }
    var emptyTitle: String { L10n.flashcardEmptyTitle.string }
    var emptyBody: String { L10n.flashcardEmptyBody.string }

    func ratingTitle(_ rating: ReviewRating) -> String {
        switch rating {
        case .again: L10n.flashcardRatingAgain.string
        case .hard: L10n.flashcardRatingHard.string
        case .good: L10n.flashcardRatingGood.string
        case .easy: L10n.flashcardRatingEasy.string
        }
    }

    /// The interval a rating WOULD produce, shown under each button before the student commits.
    func intervalLabel(for rating: ReviewRating) -> String {
        guard let card = currentCard else { return "" }
        let next = SpacedRepetition.nextState(card.sr, rating: rating, now: .now)
        return Self.intervalLabel(days: next.interval)
    }

    /// Formats a day interval as "<1m", "1d", "13d", "2mo", etc. — the copy the rating buttons show.
    static func intervalLabel(days: Int) -> String {
        if days <= 0 { return L10n.flashcardIntervalAgain.string }
        if days < 30 { return L10n.flashcardIntervalDays.string(days) }
        return L10n.flashcardIntervalMonths.string(days / 30)
    }

    // MARK: Actions

    func reveal() {
        isShowingAnswer = true
    }

    func rate(_ rating: ReviewRating) async {
        guard let card = currentCard else { return }

        let next = SpacedRepetition.nextState(card.sr, rating: rating, now: .now)
        if let index = deck.cards.firstIndex(where: { $0.id == card.id }) {
            deck.cards[index].sr = next
        }

        reviewedCount += 1
        if rating != .again { correctCount += 1 }
        // TODO(M2 · F04): Track "Hard" separately from "correct". In SM-2 a "Hard" grade is a
        // success, but it is not the same as "Good"/"Easy", so the session summary should show it
        // distinctly rather than folding it into correctCount.
        // Done when: a hardCount is exposed, shown on the summary, and a test asserts "Hard"
        // increments hardCount and not correctCount.

        isShowingAnswer = false
        currentIndex += 1

        // Persist after every rating, so "closed mid-session" keeps the progress it has already made.
        deck.updatedAt = .now
        do {
            try await store.add(deck)
        } catch {
            self.error = AppError.from(error)
        }

        if currentIndex >= cards.count {
            phase = .summary
        }
    }

    /// Starts a fresh pass over the cards that are due now (which includes every lapse).
    func keepGoing() {
        let due = deck.cards.filter { $0.sr.isDue() }
        cards = due
        currentIndex = 0
        isShowingAnswer = false
        reviewedCount = 0
        correctCount = 0
        error = nil
        phase = due.isEmpty ? .empty : .reviewing
    }
}
