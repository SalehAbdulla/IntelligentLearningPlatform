//
//  DeckDetailViewModel.swift
//  StudyForge
//
//  Presentation logic for E04 — one deck, reloaded from the store so the due/new/learning/mastered
//  counters reflect the last review session.
//
//  WHY RELOAD BY ID RATHER THAN HOLD THE DECK
//  ------------------------------------------
//  A review session rewrites the deck's card scheduling state. Holding a snapshot here would show
//  stale counters the moment the student returns, so the screen reads by id from the store — the
//  single source of truth — rather than carrying a value copy around.
//

import Foundation

@MainActor
@Observable
final class DeckDetailViewModel {

    private(set) var state: LoadState<Deck> = .idle

    private let deckId: String
    private let store: any DeckStore

    init(deckId: String, store: any DeckStore) {
        self.deckId = deckId
        self.store = store
    }

    // MARK: Derived

    var deck: Deck? { state.value }
    var cards: [Flashcard] { state.value?.cards ?? [] }
    var isLoading: Bool { state.isLoading }
    var error: AppError? { if case .failed(let error) = state { return error }; return nil }

    var dueCount: Int { deck?.dueCount() ?? 0 }
    var newCount: Int { deck?.newCount ?? 0 }
    var learningCount: Int { deck?.learningCount ?? 0 }
    var masteredCount: Int { deck?.masteredCount ?? 0 }

    // MARK: Copy

    var studyNowTitle: String { L10n.deckStudyNow.string }
    var cardsHeading: String { L10n.deckCardsHeading.string }
    var dueLabel: String { L10n.deckDueLabel.string }
    var newLabel: String { L10n.deckNewLabel.string }
    var learningLabel: String { L10n.deckLearningLabel.string }
    var masteredLabel: String { L10n.deckMasteredLabel.string }

    // MARK: Actions

    func load() async {
        state = .loading
        do {
            guard let deck = try await store.deck(id: deckId) else {
                state = .empty
                return
            }
            state = .loaded(deck)
        } catch {
            state = .failed(AppError.from(error))
        }
    }
}
