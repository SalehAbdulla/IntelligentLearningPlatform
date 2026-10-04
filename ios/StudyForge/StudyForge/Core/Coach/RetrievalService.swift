//
//  RetrievalService.swift
//  StudyForge
//
//  F15 — the retrieval contract, and the chunk-plus-score it returns.
//
//  THIS PROTOCOL IS FROZEN
//  -----------------------
//  docs/02 §5 freezes it as the interface between the two owners of the advanced feature (M2's
//  retrieval/generation layer and M3's adaptation layer) so neither blocks the other. It is
//  reproduced here VERBATIM — same names, same shapes — because a contract that drifts from the
//  document is no longer a contract. Anything the implementation needs beyond it (removal,
//  introspection) is offered as a concrete method on `LocalRetrievalService`, never as a new
//  requirement here.
//

import Foundation

/// A stored passage that matched a query.
struct RetrievedChunk: Equatable, Sendable {

    let chunk: TextChunk

    /// Cosine similarity against the query, 0…1 in practice. Surfaced to the student on the
    /// citation sheet as the relevance score, because "why did it pick this?" should be
    /// answerable rather than mysterious.
    let score: Float

    /// Whether this result is strong enough to answer from.
    ///
    /// The threshold is what turns "no relevant material" into a supported outcome instead of a
    /// confident answer built on noise — the anti-hallucination rule docs/02 §5 describes.
    var isRelevant: Bool { score >= RetrievedChunk.relevanceFloor }

    /// Below this, a chunk is not treated as grounding.
    ///
    /// Deliberately a named constant with a stated meaning rather than a tuned number: a hash
    /// embedder's scores are not calibrated the way a trained model's are, so the floor is set
    /// where a genuine lexical overlap lands and everything else falls away.
    static let relevanceFloor: Float = 0.12
}

/// Retrieval over the student's own materials. **Frozen contract — see the file header.**
protocol RetrievalService: Sendable {

    /// Replaces the index for one material. Indexing the same material twice replaces rather than
    /// duplicates, so re-importing an edited material cannot leave stale passages retrievable.
    func index(materialID: String, chunks: [TextChunk]) async throws

    /// The `topK` best-matching chunks within `scope` (material ids). An empty scope means the
    /// whole library.
    func retrieve(query: String, scope: [String], topK: Int) async throws -> [RetrievedChunk]
}
