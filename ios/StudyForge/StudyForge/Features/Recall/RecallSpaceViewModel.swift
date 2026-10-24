//
//  RecallSpaceViewModel.swift
//  StudyForge
//
//  Presentation logic for F17's Active Recall Space (docs/03 §O, O01): one queue assembled
//  across every deck, the state counters above it, and the scope filter beside it.
//
//  WHY THE QUEUE IS BUILT HERE AND NOT IN THE STORE
//  ------------------------------------------------
//  `RecallQueueBuilder` is a pure function over decks + settings + clock. The view model is the
//  only thing that knows all three, and rebuilding is cheap, so every scope change or settings
//  change is a rebuild rather than a second store read. That is also what makes "change your
//  daily limit mid-session" a one-line refresh instead of a relaunch.
//
//  WHY `queue` IS KEPT SEPARATE FROM `state`
//  -----------------------------------------
//  `LoadState` has an `.empty` case, and `.empty` by definition carries no value — but O01's
//  empty screen is not blank: it still says when the next card is due and how many cards were
//  deferred by today's ceiling. `queue` therefore always holds the most recent build, and
//  `state` answers only "loading, failed, or is there anything to do?".
//
//  WHY THERE IS NO COPY IN THIS FILE
//  ---------------------------------
//  Every string a screen shows needs a case in `Core/Localisation/L10n.swift` AND an entry in
//  both `Localizable.strings` catalogues — `L10nTests` fails in both directions and
//  `tools/check-strings.py` checks English/Arabic parity. The `.strings` files are SHARED and
//  in F17's lane; `L10n.swift` is not, so the copy ships with the views in the commit that adds
//  those cases. Until then this model exposes data and state, never prose.
//

import Foundation

@MainActor
@Observable
final class RecallSpaceViewModel {

    // MARK: State

    /// The screen's lifecycle: loading, failed, or — when nothing is due — empty.
    private(set) var state: LoadState<RecallQueue> = .idle

    /// The most recent build, kept even when `state` is `.empty`. See the header.
    private(set) var queue = RecallQueue(items: [], counts: [:], deferredByLimit: 0)

    /// Every deck the learner owns, unscoped. O06's filter is built from these.
    private(set) var decks: [Deck] = []

    /// The learner's ceilings and learning steps, as last read or saved.
    private(set) var settings = RecallSettings.default

    /// The deck O06 has scoped the queue to. `nil` means "every deck", which is the default.
    private(set) var deckFilter: String?

    /// Card id to zero-based learning step, for cards still inside the steps.
    ///
    /// Owned by the session (O02) and pushed in here, exactly as `RecallQueueBuilder` expects:
    /// F17 never writes learning state onto `Flashcard` or into the SM-2 engine.
    private(set) var learningSteps: [String: Int] = [:]

    private let deckStore: any DeckStore
    private let settingsStore: any RecallSettingsStore

    /// The clock, injected so a test can pin "today" instead of waiting for one.
    private let now: @Sendable () -> Date

    /// Whether a successful load has happened, so a scope change before the first load does not
    /// publish a queue built from no decks.
    private var hasLoaded = false

    init(
        deckStore: any DeckStore,
        settingsStore: any RecallSettingsStore,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.deckStore = deckStore
        self.settingsStore = settingsStore
        self.now = now
    }

    // MARK: Derived

    /// The cards to answer next, in order: learning, then reviews, then new.
    var items: [RecallQueueItem] { queue.items }

    /// The due-today total O01 shows above the Start action.
    var dueTotal: Int { queue.items.count }

    /// Cards left out because a daily ceiling was reached — "18 more due tomorrow".
    var deferredByLimit: Int { queue.deferredByLimit }

    /// True when the learner is genuinely all caught up.
    var isEmpty: Bool {
        if case .empty = state { return true }
        return false
    }

    var isLoading: Bool { state.isLoading }
    var error: AppError? { state.error }

    /// False for a learner with no cards at all, which is a different empty state from
    /// "everything reviewed": the first wants a prompt to build a deck, the second a due time.
    var hasAnyCards: Bool { decks.contains { !$0.cards.isEmpty } }

    /// The earliest future due date across every deck — O01's "next due" line when nothing is
    /// due. `nil` when nothing is scheduled at all.
    var nextDueAt: Date? {
        let reference = now()
        return decks
            .flatMap(\.cards)
            .map(\.sr.dueAt)
            .filter { $0 > reference }
            .min()
    }

    /// How many cards of one state the queue holds, for O01's four counters.
    func count(of cardState: RecallCardState) -> Int {
        queue.count(of: cardState)
    }

    // MARK: Loading

    /// Reads every deck and the learner's options together, then builds the queue.
    func load() async {
        state = .loading
        do {
            async let deckRead = deckStore.all()
            async let settingsRead = settingsStore.settings()
            let (loadedDecks, loadedSettings) = try await (deckRead, settingsRead)

            decks = loadedDecks
            settings = loadedSettings
            hasLoaded = true
            rebuild()
        } catch {
            // No queue is published from a half-read state: a screen showing yesterday's
            // counts beside today's error is worse than a screen showing the error alone.
            hasLoaded = false
            state = .failed(Self.appError(error))
        }
    }

    /// Re-reads everything — the pull-to-refresh path, and how a screen recovers from an error.
    func reload() async {
        await load()
    }

    // MARK: Scoping

    /// Scopes the queue to one deck, or back to every deck when `nil`. No store read: the decks
    /// are already in memory, so this is a rebuild rather than a round trip.
    func selectDeck(_ deckId: String?) {
        deckFilter = deckId
        guard hasLoaded else { return }
        rebuild()
    }

    // MARK: Session hand-off

    /// Records the learning steps the session currently holds. Called by O02 as cards enter and
    /// leave the steps, so the queue keeps putting a card the learner just failed back in front.
    func setLearningSteps(_ steps: [String: Int]) {
        learningSteps = steps
        guard hasLoaded else { return }
        rebuild()
    }

    // MARK: Settings

    /// Saves new options and rebuilds immediately, so a learner who sets "five new cards a day"
    /// sees the queue change while they are still on the settings screen.
    ///
    /// A failed save restores the previous values: showing a ceiling the app did not persist
    /// would make the next launch contradict the screen.
    func saveSettings(_ newSettings: RecallSettings) async {
        let previous = settings
        settings = newSettings

        do {
            try await settingsStore.save(newSettings)
            if hasLoaded { rebuild() }
        } catch {
            settings = previous
            state = .failed(Self.appError(error))
        }
    }

    // MARK: Building

    private func rebuild() {
        let built = RecallQueueBuilder.build(
            decks: decks,
            settings: settings,
            learningSteps: learningSteps,
            now: now(),
            deckFilter: deckFilter
        )
        queue = built
        state = built.isEmpty ? .empty : .loaded(built)
    }

    /// Maps a failure to the app's single user-facing error.
    ///
    /// `AppError.from` cannot learn `RecallSettingsError` without editing shared state-layer code,
    /// so the concrete case is handled here and everything else — `DeckError` included — still
    /// goes through `AppError.from`.
    private static func appError(_ error: Error) -> AppError {
        if let recallSettingsError = error as? RecallSettingsError {
            return recallSettingsError.asAppError
        }
        return AppError.from(error)
    }
}
