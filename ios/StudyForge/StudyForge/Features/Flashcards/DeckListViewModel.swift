//
//  DeckListViewModel.swift
//  StudyForge
//
//  Presentation logic for E01 — the student's decks, read from the local store.
//
//  WHY THE LIST IS A `LoadState`
//  -----------------------------
//  Loading, empty and failed are states a screen has to design, exactly as the library does. The
//  deck list shares that shape so the loading and failure affordances come for free.
//

import Foundation

@MainActor
@Observable
final class DeckListViewModel {

    private(set) var state: LoadState<[Deck]> = .idle

    private let store: any DeckStore

    init(store: any DeckStore) {
        self.store = store
    }

    // MARK: Derived

    var decks: [Deck] { state.value ?? [] }
    var isEmpty: Bool { if case .empty = state { return true }; return false }
    var isLoading: Bool { state.isLoading }
    var error: AppError? { if case .failed(let error) = state { return error }; return nil }

    // MARK: Copy

    var title: String { L10n.deckTitle.string }
    var emptyTitle: String { L10n.deckEmptyTitle.string }
    var emptyBody: String { L10n.deckEmptyBody.string }

    // MARK: Actions

    func load() async {
        state = .loading
        do {
            let decks = try await store.all()
            state = decks.isEmpty ? .empty : .loaded(decks)
        } catch {
            state = .failed(AppError.from(error))
        }
    }

    func delete(_ deck: Deck) async {
        do {
            try await store.delete(id: deck.id)
            await load()
        } catch {
            state = .failed(AppError.from(error))
        }
    }
}
