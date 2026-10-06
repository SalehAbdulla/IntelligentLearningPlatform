//
//  AIGenerationModels.swift
//  StudyForge
//
//  The STRUCTURED OUTPUT contracts for every AI artefact.
//
//  WHY STRUCTURED OUTPUT, NOT PROSE
//  --------------------------------
//  Asking a model for "20 flashcards" and parsing the reply is how student
//  projects fail. We instead declare the shape and let the framework guarantee
//  it: `@Generable` types are filled by the model with strong structural
//  guarantees, so a flashcard always has a front, a back and a difficulty.
//
//  This is the single most important API assumption in the whole AI layer, which
//  is exactly why the S0 spike exists to prove it compiles and runs.
//
//  PROVENANCE IS NOT GENERATED
//  ---------------------------
//  The model produces content; WE attach the citation. `sourceChunkIds` and
//  `pageNumbers` are written by our extraction pipeline, never by the model —
//  otherwise the citation could be hallucinated too, defeating its purpose.
//

import Foundation
import FoundationModels

// MARK: - Provenance (ours, not the model's)

/// How confident we are in a generated artefact, derived from the extraction
/// quality of its source rather than from the model's own opinion.
enum AIConfidence: String, Sendable, Equatable, CaseIterable, Codable {
    case high
    case medium
    case low

    /// Low-confidence items are visibly flagged in the UI and land in the tutor
    /// review queue first (docs/05 §8, academic integrity).
    var isReviewRecommended: Bool { self != .high }
}

/// Where an artefact came from. The basis of the "tap to see the source" feature
/// that distinguishes grounded generation from confident guessing.
struct AIProvenance: Sendable, Equatable, Codable {
    let materialId: String
    /// Page numbers in the source material, 1-based.
    let pageNumbers: [Int]
    let confidence: AIConfidence

    /// A short chip label, e.g. "p.12" or "pp.12–14".
    var citationLabel: String {
        guard let first = pageNumbers.min() else { return "source" }
        guard let last = pageNumbers.max(), last != first else { return "p.\(first)" }
        return "pp.\(first)–\(last)"
    }
}

// MARK: - Summary

/// A grounded summary of one material.
@Generable
struct AISummary: Sendable, Equatable {

    @Guide(description: "A single-sentence takeaway a student could read on a bus. No preamble.")
    var tldr: String

    @Guide(description: "Between 3 and 7 key points, each one sentence, each a claim made by the source material.")
    var keyPoints: [String]

    @Guide(description: "Technical terms from the material that a student might need to look up, with a one-line definition.")
    var glossary: [AIGlossaryTerm]
}

@Generable
struct AIGlossaryTerm: Sendable, Equatable {

    @Guide(description: "The term exactly as it appears in the source material.")
    var term: String

    @Guide(description: "A one-line definition, using only wording the source supports.")
    var definition: String
}

// MARK: - Flashcards

/// A single generated flashcard.
@Generable
struct AIFlashcard: Sendable, Equatable {

    @Guide(description: "The question side. A question, a term to define, or a cloze prompt with one gap.")
    var front: String

    @Guide(description: "The answer side. One or two sentences, using only facts stated in the source material.")
    var back: String

    @Guide(description: "Recall difficulty: 1 = simple fact, 2 = understanding, 3 = applying the idea.")
    var difficulty: Int
}

// MARK: - Quiz questions

/// A single generated quiz question.
@Generable
struct AIQuizQuestion: Sendable, Equatable {

    @Guide(description: "The question stem. Must be answerable from the source material alone.")
    var stem: String

    @Guide(description: "Exactly four answer options. Exactly one is correct.")
    var options: [String]

    @Guide(description: "Zero-based index into options for the correct answer.")
    var correctOptionIndex: Int

    @Guide(description: "Why the correct answer is correct, in one or two sentences, citing the source.")
    var explanation: String

    @Guide(description: "The single topic this question tests, e.g. 'third normal form'. Used to build the weakness radar.")
    var topic: String
}

// MARK: - Study path (advanced feature F15)

/// One step in an adaptive study path. Ordered by the planner, not the model's
/// prose — so the sequence is inspectable and testable.
@Generable
struct AIStudyStep: Sendable, Equatable {

    @Guide(description: "A short imperative instruction, e.g. 'Review the normalisation flashcards'.")
    var instruction: String

    @Guide(description: "Kind of activity: read, flashcards, quiz, or review.")
    var activity: String

    @Guide(description: "Estimated minutes for this step, between 5 and 45.")
    var estimatedMinutes: Int

    @Guide(description: "The topic this step targets, matching a topic from the weakness radar.")
    var topic: String
}

// MARK: - Coach answers (advanced feature F15)

/// One retrieved passage handed to the model, with the id it must cite.
///
/// NOT `@Generable`: this is prompt INPUT. Only the answer is model output, and marking input as
/// generable would invite the model to invent the evidence it is supposed to be reading.
struct AICoachChunk: Sendable, Equatable {
    let id: String
    let materialId: String
    let text: String
    let page: Int?
}

/// A grounded question: the query plus ONLY the passages retrieval selected.
struct AICoachPrompt: Sendable, Equatable {
    let question: String

    /// The retrieved passages. Nothing else may be used to answer — this is what "grounded" means.
    let chunks: [AICoachChunk]

    /// How to explain it (H03's depth control).
    let depth: String

    let language: OutputLanguage
}

/// The model's grounded reply.
///
/// `citedChunkIds` is validated against the chunks we supplied — the model may only cite what it
/// was given. An invented id is dropped, which is what makes the citation ENFORCED rather than
/// decorative (docs/02 §5, technique 2).
@Generable
struct AICoachAnswer: Sendable, Equatable {

    @Guide(description: "The answer, using only facts stated in the provided passages. Never introduce outside knowledge. If the passages do not answer the question, say so plainly.")
    var answer: String

    @Guide(description: "The ids of the provided passages that support the answer. Cite only ids that were given to you.")
    var citedChunkIds: [String]
}
