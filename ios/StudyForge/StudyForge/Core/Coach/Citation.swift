//
//  Citation.swift
//  StudyForge
//
//  F15 — a reference from an answer back to the passage it came from (docs/03 §H H04).
//
//  WRITTEN BY US, NEVER BY THE MODEL
//  ---------------------------------
//  This is the same rule `AIProvenance` states for F03–F05 and it matters more here: if the model
//  supplied its own citations, a hallucinated claim could arrive with a hallucinated page number
//  attached, and the screen that exists to prove grounding would be the thing that fakes it. So a
//  `Citation` is assembled from the RETRIEVED CHUNK — a passage we indexed from the student's own
//  file — and the model's role ends at deciding which chunk supports which sentence.
//

import Foundation

/// One source reference shown under a coach answer.
struct Citation: Identifiable, Equatable, Sendable, Codable {

    /// The chunk's id, so two citations of the same passage collapse to one chip.
    let id: String

    let materialId: String

    /// A snapshot of the material's title, so the sheet renders without a second lookup.
    let materialTitle: String

    /// The page the passage came from, or `nil` for a source with no pages.
    let page: Int?

    /// The passage itself — the evidence, quoted rather than paraphrased.
    let snippet: String

    /// The retrieval score, shown on H04 so "why this source?" has an answer.
    let score: Float

    init(chunk: TextChunk, materialTitle: String, score: Float) {
        self.id = chunk.id
        self.materialId = chunk.materialId
        self.materialTitle = materialTitle
        self.page = chunk.page
        self.snippet = chunk.text
        self.score = score
    }

    /// A short page label — `p.12`.
    ///
    /// Inline rather than routed through `L10n`, matching `AIProvenance.citationLabel`: the page
    /// marker abbreviation is part of the same localisation debt those two share, recorded in
    /// `Core/Localisation/L10n.swift` rather than duplicated as a half-fix here.
    var pageLabel: String? {
        page.map { "p.\($0)" }
    }
}
