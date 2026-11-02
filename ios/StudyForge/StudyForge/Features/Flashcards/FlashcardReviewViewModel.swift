import Foundation

private struct FlashcardRatingRecord: Equatable {
    let index: Int
    let cardID: String
    let previous: SpacedRepetitionState
    let rating: ReviewRating
}

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
    private(set) var hardCount = 0
    private(set) var againCount = 0
    private(set) var easyCount = 0
    private(set) var isRating = false
    private(set) var error: AppError?

    private(set) var startedAt: Date
    private(set) var finishedAt: Date?
    private(set) var deck: Deck

    private var lastRating: FlashcardRatingRecord?
    private let store: any DeckStore

    init(deck: Deck, store: any DeckStore, now: Date = .now) {
        self.deck = deck
        self.store = store
        let due = deck.cards.filter { $0.sr.isDue(now: now) }
        self.cards = due
        self.phase = due.isEmpty ? .empty : .reviewing
        self.startedAt = now
    }

    var currentCard: Flashcard? {
        cards.indices.contains(currentIndex) ? cards[currentIndex] : nil
    }

    var progress: String { L10n.flashcardProgress.string(min(currentIndex + 1, cards.count), cards.count) }

    var progressLabel: String { FlashcardCopy.progress(min(currentIndex + 1, cards.count), cards.count) }

    var progressFraction: Double {
        cards.isEmpty ? 0 : Double(currentIndex) / Double(cards.count)
    }

    var goodCount: Int { correctCount - easyCount }

    var accuracy: Double {
        reviewedCount == 0 ? 0 : Double(correctCount + hardCount) / Double(reviewedCount)
    }

    var accuracyPercent: Int { Int((accuracy * 100).rounded()) }

    var citationLabel: String? {
        guard let card = currentCard, card.aiDrafted else { return nil }
        return card.provenance.pageNumbers.isEmpty ? L10n.flashcardSource.string : card.provenance.citationLabel
    }

    var isCurrentCardFlagged: Bool { currentCard?.isFlagged ?? false }

    var canUndo: Bool { lastRating != nil && !isRating && phase == .reviewing }

    var hasUnfinishedProgress: Bool { phase == .reviewing && reviewedCount > 0 }

    var dueNowCount: Int { deck.dueCount() }

    var nextReviewDate: Date? { deck.nextDueDate() }

    var sessionDuration: TimeInterval { (finishedAt ?? .now).timeIntervalSince(startedAt) }

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

    func intervalLabel(for rating: ReviewRating) -> String {
        guard let card = currentCard else { return "" }
        let next = SpacedRepetition.nextState(card.sr, rating: rating, now: .now)
        return Self.intervalLabel(days: next.interval)
    }

    static func intervalLabel(days: Int) -> String {
        if days <= 0 { return L10n.flashcardIntervalAgain.string }
        if days < 30 { return L10n.flashcardIntervalDays.string(days) }
        return L10n.flashcardIntervalMonths.string(days / 30)
    }

    func reveal() {
        guard currentCard != nil else { return }
        isShowingAnswer = true
    }

    func rate(_ rating: ReviewRating) async {
        guard !isRating, phase == .reviewing, let card = currentCard else { return }
        isRating = true
        defer { isRating = false }

        let now = Date.now
        let next = SpacedRepetition.nextState(card.sr, rating: rating, now: now)
        lastRating = FlashcardRatingRecord(index: currentIndex, cardID: card.id, previous: card.sr, rating: rating)
        apply(next, toCard: card.id)
        count(rating, by: 1)

        isShowingAnswer = false
        currentIndex += 1
        if currentIndex >= cards.count {
            finishedAt = now
            phase = .summary
        }

        await persist()
    }

    func undo() async {
        guard let entry = lastRating, !isRating else { return }
        isRating = true
        defer { isRating = false }

        lastRating = nil
        apply(entry.previous, toCard: entry.cardID)
        count(entry.rating, by: -1)
        currentIndex = entry.index
        isShowingAnswer = true
        finishedAt = nil
        phase = .reviewing

        await persist()
    }

    func toggleFlag() async {
        guard let card = currentCard else { return }
        var tags = card.tags
        if let index = tags.firstIndex(of: FlashcardLimits.flagTag) {
            tags.remove(at: index)
        } else {
            tags.append(FlashcardLimits.flagTag)
        }
        cards[currentIndex].tags = tags
        if let index = deck.cards.firstIndex(where: { $0.id == card.id }) {
            deck.cards[index].tags = tags
        }
        await persist()
    }

    func keepGoing() {
        let now = Date.now
        let due = deck.cards.filter { $0.sr.isDue(now: now) }
        cards = due
        currentIndex = 0
        isShowingAnswer = false
        reviewedCount = 0
        correctCount = 0
        hardCount = 0
        againCount = 0
        easyCount = 0
        lastRating = nil
        error = nil
        startedAt = now
        finishedAt = nil
        phase = due.isEmpty ? .empty : .reviewing
    }

    private func apply(_ state: SpacedRepetitionState, toCard id: String) {
        if let index = deck.cards.firstIndex(where: { $0.id == id }) {
            deck.cards[index].sr = state
        }
        if let index = cards.firstIndex(where: { $0.id == id }) {
            cards[index].sr = state
        }
    }

    private func count(_ rating: ReviewRating, by delta: Int) {
        reviewedCount += delta
        switch rating {
        case .again:
            againCount += delta
        case .hard:
            hardCount += delta
        case .good:
            correctCount += delta
        case .easy:
            correctCount += delta
            easyCount += delta
        }
    }

    private func persist() async {
        deck.updatedAt = .now
        do {
            try await store.add(deck)
            error = nil
        } catch {
            self.error = AppError.from(error)
        }
    }
}
