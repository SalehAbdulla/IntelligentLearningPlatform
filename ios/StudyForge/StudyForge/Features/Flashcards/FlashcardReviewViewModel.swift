import Foundation

private struct FlashcardRatingRecord: Equatable {
    let index: Int
    let cardID: String
    let previous: SpacedRepetitionState
    let rating: ReviewRating
    let entryID: String
}

@MainActor
@Observable
final class FlashcardReviewViewModel {

    enum Phase: Equatable {
        case reviewing
        case summary
        case empty
    }

    enum Mode: Equatable {
        case due
        case ahead
    }

    static let aheadLimit = 20

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
    private(set) var streakDays = 0
    private(set) var mode: Mode

    private var lastRating: FlashcardRatingRecord?
    private let store: any DeckStore
    private let log: any FlashcardReviewLog

    init(
        deck: Deck,
        store: any DeckStore,
        log: any FlashcardReviewLog = InMemoryFlashcardReviewLog(),
        mode: Mode = .due,
        now: Date = .now
    ) {
        self.deck = deck
        self.store = store
        self.log = log
        self.mode = mode
        let queue = Self.queue(for: deck, mode: mode, now: now)
        self.cards = queue
        self.phase = queue.isEmpty ? .empty : .reviewing
        self.startedAt = now
    }

    static func queue(for deck: Deck, mode: Mode, now: Date = .now) -> [Flashcard] {
        switch mode {
        case .due:
            return deck.cards.filter { $0.sr.isDue(now: now) }
        case .ahead:
            return Array(deck.cards.sorted { $0.sr.dueAt < $1.sr.dueAt }.prefix(aheadLimit))
        }
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

    var presentation: FlashcardPresentation? { currentCard.map(FlashcardPresentation.init) }
    var isStudyingAhead: Bool { mode == .ahead }
    var canStudyAhead: Bool { !deck.cards.isEmpty }
    var totalCards: Int { deck.cards.count }
    var lastSavedAt: Date { deck.updatedAt }
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
        let entry = FlashcardReviewEntry(
            deckId: deck.id,
            cardId: card.id,
            rating: rating,
            intervalDays: next.interval,
            tags: card.tags.filter { $0 != FlashcardLimits.flagTag },
            reviewedAt: now
        )
        lastRating = FlashcardRatingRecord(
            index: currentIndex,
            cardID: card.id,
            previous: card.sr,
            rating: rating,
            entryID: entry.id
        )
        apply(next, toCard: card.id)
        count(rating, by: 1)

        isShowingAnswer = false
        currentIndex += 1
        if currentIndex >= cards.count {
            finishedAt = now
            phase = .summary
        }

        await persist()
        await record(entry)
        if phase == .summary {
            await refreshStreak(now: now)
        }
    }

    func refreshStreak(now: Date = .now) async {
        let entries = (try? await log.entries()) ?? []
        streakDays = FlashcardReviewStats.streak(entries, now: now)
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
        do {
            try await log.remove(id: entry.entryID)
        } catch {
            self.error = AppError.from(error)
        }
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
        mode = .due
        restart(now: .now)
    }

    func studyAhead() {
        guard canStudyAhead else { return }
        mode = .ahead
        restart(now: .now)
    }

    private func restart(now: Date) {
        let queue = Self.queue(for: deck, mode: mode, now: now)
        cards = queue
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
        phase = queue.isEmpty ? .empty : .reviewing
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

    private func record(_ entry: FlashcardReviewEntry) async {
        do {
            try await log.append(entry)
        } catch {
            self.error = AppError.from(error)
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
