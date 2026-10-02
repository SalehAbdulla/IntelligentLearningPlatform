//
//  Flashcard.swift
//  StudyForge
//
//  One reviewable card in a deck, plus the citation that says where it came from.
//
//  WHY THE CARD CARRIES ITS OWN SCHEDULING STATE
//  ---------------------------------------------
//  A card is the only thing the review loop mutates: rating it rewrites its ease, interval and
//  due date. Keeping `sr` on the card (rather than in a parallel review log) means one write
//  persists a rating, which is what makes "the student closed mid-session" recoverable.
//
//  PROVENANCE IS NOT GENERATED
//  ---------------------------
//  Exactly as with summaries: the model writes the front and back; WE attach `provenance`. The
//  citation chip on the review back face comes from `AIProvenance`, never from the model.
//

import Foundation

/// What shape a card takes. Only `qa` is generated today; the others arrive with the card-type
/// selector in a later pass, but the stored vocabulary already matches docs/05 §3.
enum CardType: String, Sendable, CaseIterable, Codable {
    case qa
    case cloze
    case imageOcclusion
    case reversible
}

/// A single flashcard.
struct Flashcard: Identifiable, Equatable, Sendable, Codable {

    let id: String
    var front: String
    var back: String
    var cardType: CardType
    var tags: [String]

    /// Where the card's content came from. The review back face cites it.
    var provenance: AIProvenance

    /// True when the card was produced by the AI pipeline rather than typed by hand.
    var aiDrafted: Bool

    /// The spaced-repetition state the scheduler reads and rewrites.
    var sr: SpacedRepetitionState

    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        front: String,
        back: String,
        cardType: CardType = .qa,
        tags: [String] = [],
        provenance: AIProvenance,
        aiDrafted: Bool = true,
        sr: SpacedRepetitionState = SpacedRepetitionState(),
        createdAt: Date = .now
    ) {
        self.id = id
        self.front = front
        self.back = back
        self.cardType = cardType
        self.tags = tags
        self.provenance = provenance
        self.aiDrafted = aiDrafted
        self.sr = sr
        self.createdAt = createdAt
    }
}
