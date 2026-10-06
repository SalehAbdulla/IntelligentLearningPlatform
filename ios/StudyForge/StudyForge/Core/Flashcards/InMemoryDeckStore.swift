//
//  InMemoryDeckStore.swift
//  StudyForge
//
//  A `DeckStore` that keeps everything in memory — previews and tests.
//
//  A REAL conformance rather than a stub, mirroring `InMemoryMaterialStore`: a screen driven by it
//  behaves exactly as it does against the file store, and the `forceFailure` hook lets a test reach
//  the failed state without inventing an unwritable file.
//

import Foundation

actor InMemoryDeckStore: DeckStore {

    private var decks: [Deck]

    /// When set, every call fails with it until cleared.
    private var failure: DeckError?

    init(seededWith decks: [Deck] = []) {
        self.decks = decks
    }

    // MARK: DeckStore

    func all() async throws -> [Deck] {
        try failIfForced()
        return decks.sorted { $0.updatedAt > $1.updatedAt }
    }

    func deck(id: String) async throws -> Deck? {
        try failIfForced()
        return decks.first { $0.id == id }
    }

    func add(_ deck: Deck) async throws {
        try failIfForced()
        if let index = decks.firstIndex(where: { $0.id == deck.id }) {
            decks[index] = deck
        } else {
            decks.append(deck)
        }
    }

    func delete(id: String) async throws {
        try failIfForced()
        decks.removeAll { $0.id == id }
    }

    // MARK: Test and preview controls

    /// Forces every call to fail with `error`. Pass `nil` to restore success.
    func forceFailure(_ error: DeckError?) {
        failure = error
    }

    private func failIfForced() throws {
        if let failure { throw failure }
    }
}
