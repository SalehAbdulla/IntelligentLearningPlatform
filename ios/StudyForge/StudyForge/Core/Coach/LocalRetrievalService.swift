//
//  LocalRetrievalService.swift
//  StudyForge
//
//  F15 — the on-device retrieval index (docs/02 §5, technique 1).
//
//  WHY THE VECTORS NEVER LEAVE THE DEVICE
//  --------------------------------------
//  docs/05 §2 says the vectors stay on-device while the chunks sync. That is a privacy decision,
//  not a storage one: a vector is derived from the student's own material, and shipping it to a
//  server would leak the shape of a document the student never agreed to upload. So the index
//  lives here, in memory, and is rebuilt from the materials on the device.
//
//  WHY AN ACTOR
//  ------------
//  Indexing walks a whole library and embedding is CPU work; retrieval happens while the student
//  types. An actor keeps both off the main thread and serialises them against each other, so a
//  query can never read a half-built index.
//

import Foundation

actor LocalRetrievalService: RetrievalService {

    /// One stored passage: its text, where it came from, and its vector.
    private struct Entry: Sendable {
        let chunk: TextChunk
        let vector: EmbeddingVector
    }

    /// materialID → its passages. Keyed by material so re-indexing replaces atomically.
    private var index: [String: [Entry]] = [:]

    private let embedder: any EmbeddingProvider

    init(embedder: any EmbeddingProvider = HashingEmbedder()) {
        self.embedder = embedder
    }

    // MARK: RetrievalService

    func index(materialID: String, chunks: [TextChunk]) async throws {
        guard !chunks.isEmpty else {
            // An empty re-index is a deletion in disguise: the material no longer has retrievable
            // text, so leaving the old vectors would let it keep answering questions.
            index[materialID] = nil
            return
        }

        index[materialID] = chunks.map { chunk in
            Entry(chunk: chunk, vector: embedder.embed(chunk.text))
        }
    }

    func retrieve(query: String, scope: [String], topK: Int) async throws -> [RetrievedChunk] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, topK > 0 else { return [] }

        let candidates = scope.isEmpty
            ? index.values.flatMap { $0 }
            : scope.flatMap { index[$0] ?? [] }

        guard !candidates.isEmpty else { return [] }

        let queryVector = embedder.embed(trimmed)

        return candidates
            .map { entry in
                RetrievedChunk(
                    chunk: entry.chunk,
                    score: queryVector.cosineSimilarity(to: entry.vector)
                )
            }
            .filter { $0.isRelevant }
            .sorted { left, right in
                // Tie-break on reading order, so an unchanged library returns a stable answer
                // rather than reshuffling on every keystroke.
                left.score == right.score
                    ? left.chunk.ordinal < right.chunk.ordinal
                    : left.score > right.score
            }
            .prefix(topK)
            .map { $0 }
    }

    // MARK: Beyond the frozen contract

    /// Drops one material from the index.
    ///
    /// Offered as a concrete method rather than a protocol requirement: docs/02 §5 freezes the
    /// protocol at two methods, and a caller that needs removal is a caller that already holds
    /// this type.
    func remove(materialID: String) {
        index[materialID] = nil
    }

    /// How many passages are indexed for a material — for tests and diagnostics.
    func indexedChunkCount(materialID: String) -> Int {
        index[materialID]?.count ?? 0
    }

    /// How many materials are indexed.
    var indexedMaterialCount: Int { index.count }
}
