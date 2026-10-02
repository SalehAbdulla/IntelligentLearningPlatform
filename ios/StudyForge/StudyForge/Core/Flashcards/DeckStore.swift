//
//  DeckStore.swift
//  StudyForge
//
//  Where the student's decks are kept, and the seam that hides WHERE.
//
//  LOCAL-FIRST, FOR THE SAME REASON MATERIALS AND SUMMARIES ARE
//  ------------------------------------------------------------
//  A deck is derived from material that already lives on the device, and reviewing it must work in
//  aeroplane mode. So the durable home is a local file, and this protocol is the only place that
//  knows that. A screen asks for decks and never learns where they came from.
//
//  WHY `async`
//  -----------
//  File IO must not run on the main actor, and a future Firestore half absorbs the change without
//  touching a caller.
//

import Foundation

/// Reads and writes the student's decks.
protocol DeckStore: Sendable {

    /// Every deck, most recently updated first.
    func all() async throws -> [Deck]

    /// One deck, or `nil` when nothing is stored under that id.
    func deck(id: String) async throws -> Deck?

    /// Stores a deck, replacing any existing one with the same id. This is also how a review
    /// session persists a rating: it rewrites the deck with the updated card scheduling state.
    func add(_ deck: Deck) async throws

    /// Removes a deck. Removing one that is already gone is not an error.
    func delete(id: String) async throws
}

/// Failures from the deck layer, in the app's own vocabulary.
enum DeckError: Error, Equatable {

    /// The local store could not be read or written.
    case storageFailed

    /// Maps to the app's single user-facing error type.
    var asAppError: AppError {
        switch self {
        case .storageFailed:
            .server(reference: "deck-store-failed")
        }
    }
}
