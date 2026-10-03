//
//  Summary.swift
//  StudyForge
//
//  A saved AI summary of one material, plus the citation that proves where it came from.
//
//  WHY THE PROVENANCE IS THE AI LAYER'S TYPE, NOT A COPY
//  -----------------------------------------------------
//  `AIProvenance` is what the generation pipeline attaches to every artefact, and its
//  `citationLabel` is the one-tap "show me the source" affordance the accuracy story depends
//  on. Persisting it directly — rather than re-declaring the same three fields here — means a
//  saved summary and the generated value it came from can never disagree about a page number.
//  That is exactly the drift a duplicate struct would invite.
//
//  WHY `SummaryTerm` AND NOT `AIGlossaryTerm`
//  -----------------------------------------
//  `AIGlossaryTerm` is a `@Generable` type: its shape is the framework's output contract.
//  Persistence needs a plain `Codable` value, and the two are free to evolve separately, so the
//  stored type lives here and the view model maps the generated value onto it at save time.
//

import Foundation

/// A summary the student generated and chose to keep.
struct Summary: Identifiable, Equatable, Sendable, Codable {

    let id: String
    var title: String

    /// The settings the summary was produced with, so a re-open can re-state them honestly.
    let length: SummaryLength
    let style: SummaryStyle
    let language: OutputLanguage

    var tldr: String
    var keyPoints: [String]
    var glossary: [SummaryTerm]

    /// Where the content came from. Carries the material id, the page numbers and the
    /// confidence band, all of which the result screen cites rather than invents.
    let provenance: AIProvenance

    /// Which engine produced it, so the result screen can keep its privacy promise.
    let tier: AITier

    let createdAt: Date

    /// The material this summary was generated from. Derived from provenance so it cannot
    /// drift from the citation that names it.
    var materialId: String { provenance.materialId }

    init(
        id: String = UUID().uuidString,
        title: String,
        length: SummaryLength,
        style: SummaryStyle,
        language: OutputLanguage,
        tldr: String,
        keyPoints: [String],
        glossary: [SummaryTerm],
        provenance: AIProvenance,
        tier: AITier,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.length = length
        self.style = style
        self.language = language
        self.tldr = tldr
        self.keyPoints = keyPoints
        self.glossary = glossary
        self.provenance = provenance
        self.tier = tier
        self.createdAt = createdAt
    }
}

/// One glossary entry in a saved summary: a term exactly as the source used it, and a
/// one-line definition the source supports.
struct SummaryTerm: Equatable, Sendable, Codable {
    var term: String
    var definition: String
}
