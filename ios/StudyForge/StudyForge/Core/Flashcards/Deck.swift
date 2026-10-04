//
//  Deck.swift
//  StudyForge
//
//  A named set of flashcards, generated from one material.
//
//  WHY THE CARDS LIVE ON THE DECK
//  ------------------------------
//  Firestore splits them (`decks/{id}/cards/{id}`) for the 1 MiB document limit, but the local,
//  on-device store has no such limit and a review session always needs the whole deck at once. So
//  a `Deck` owns its `cards` here, and the store seam is what hides that from a future split into
//  subcollections.
//

import Foundation

/// A deck of flashcards.
struct Deck: Identifiable, Equatable, Sendable, Codable {

    let id: String
    var title: String

    /// The material the cards were generated from, when they were. `nil` for a hand-built deck.
    var materialId: String?

    var cards: [Flashcard]

    let createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        title: String,
        materialId: String? = nil,
        cards: [Flashcard] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.materialId = materialId
        self.cards = cards
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// How many cards are due now: never reviewed, or their due date has passed.
    func dueCount(now: Date = .now) -> Int {
        cards.filter { $0.sr.isDue(now: now) }.count
    }

    /// How many cards have never been reviewed.
    var newCount: Int { cards.filter { $0.sr.reps == 0 && $0.sr.lapses == 0 }.count }

    /// How many cards are in the learning phase (started, not yet an interval of a month).
    var learningCount: Int {
        cards.filter { $0.sr.reps > 0 && $0.sr.interval < 30 }.count
    }

    /// How many cards are well established (interval of a month or more).
    var masteredCount: Int { cards.filter { $0.sr.interval >= 30 }.count }
}
