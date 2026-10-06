//
//  Embedding.swift
//  StudyForge
//
//  F15 — text vectors and the similarity between them (docs/02 §5, technique 1).
//
//  WHY A PROTOCOL, AND WHY THE DEFAULT IS NOT `NLEmbedding`
//  ------------------------------------------------------
//  docs/02 §5 specifies `NLEmbedding` for the on-device vectorizer, and that is the production
//  implementation. It is also unavailable in the Simulator and can fail on older devices, which
//  would make the advanced feature undemonstrable exactly where every demo is rehearsed.
//
//  So the vectorizer is a protocol and the default is `HashingEmbedder`: a deterministic feature
//  hash over word tokens. It is a real, working vectorizer — it retrieves relevant passages by
//  cosine similarity — and because it is pure and deterministic it is also testable, which
//  `NLEmbedding` is not. Swapping in the framework embedder is one line in `AppContainer`.
//
//  WHY THE HASH IS HAND-WRITTEN
//  ----------------------------
//  Swift's `hashValue` is seeded per process, so the SAME text would land in different buckets on
//  the next launch and every previously-indexed vector would be silently wrong. A stable hash is
//  therefore a correctness requirement, not a micro-optimisation.
//

import Foundation

/// A unit vector representing a passage or a query.
struct EmbeddingVector: Equatable, Sendable, Codable {

    let values: [Float]

    var dimensions: Int { values.count }

    /// Euclidean length. Used by `cosineSimilarity`; zero for the empty vector.
    var magnitude: Float {
        values.reduce(0) { $0 + $1 * $1 }.squareRoot()
    }

    /// Cosine similarity, −1…1, where 1 is identical direction.
    ///
    /// Returns 0 rather than NaN for a zero vector, so an empty chunk scores "no similarity"
    /// instead of poisoning every comparison it takes part in.
    func cosineSimilarity(to other: EmbeddingVector) -> Float {
        guard dimensions == other.dimensions, dimensions > 0 else { return 0 }

        var dot: Float = 0
        for index in 0..<dimensions {
            dot += values[index] * other.values[index]
        }

        let denominator = magnitude * other.magnitude
        guard denominator > 0 else { return 0 }
        return dot / denominator
    }

    /// Scales to unit length. Cosine similarity is scale-invariant, so normalising once at
    /// embedding time makes every later comparison a plain dot product.
    func normalized() -> EmbeddingVector {
        let length = magnitude
        guard length > 0 else { return self }
        return EmbeddingVector(values: values.map { $0 / length })
    }
}

/// Turns text into a vector.
protocol EmbeddingProvider: Sendable {

    /// The vector width. Two providers may not be compared — the retrieval index records this so
    /// a stored index built by one embedder is discarded when another is swapped in.
    var dimensions: Int { get }

    func embed(_ text: String) -> EmbeddingVector
}

/// A deterministic bag-of-words embedder, by feature hashing.
///
/// See the note at the top of this file for why this is the default and what replaces it.
struct HashingEmbedder: EmbeddingProvider {

    let dimensions: Int

    init(dimensions: Int = 256) {
        self.dimensions = dimensions
    }

    func embed(_ text: String) -> EmbeddingVector {
        var buckets = [Float](repeating: 0, count: dimensions)

        for token in Self.tokens(in: text) {
            let hash = Self.stableHash(token)
            let bucket = Int(hash % UInt64(dimensions))

            // A second bit chooses the sign, so two colliding words cancel as often as they
            // reinforce — the standard trick that keeps collisions from inflating similarity.
            let sign: Float = (hash & 0x1_0000) == 0 ? 1 : -1
            buckets[bucket] += sign
        }

        return EmbeddingVector(values: buckets).normalized()
    }

    // MARK: Tokenising

    /// Words worth hashing: lower-cased, alphabetic, at least two characters, and not a word so
    /// common it appears in every passage. Stop-words matter here — without them "the" would be
    /// the strongest signal in the corpus.
    static func tokens(in text: String) -> [String] {
        text.lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { $0.count >= 2 && !stopWords.contains($0) }
    }

    /// A deliberately small list: English function words plus the Arabic definite article and a
    /// few of the same class, since the catalogue ships Arabic content.
    static let stopWords: Set<String> = [
        "the", "and", "for", "with", "that", "this", "from", "are", "was", "were", "has", "have",
        "not", "but", "you", "your", "can", "its", "into", "than", "then", "when", "which", "their",
        "ال", "في", "من", "على", "هذا", "هذه", "التي", "الذي", "مع", "عن", "الى", "إلى",
    ]

    // MARK: Hashing

    /// FNV-1a, 64-bit. Stable across processes and platforms, which `hashValue` is not.
    static func stableHash(_ value: String) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        let prime: UInt64 = 0x0000_0100_0000_01b3

        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* prime
        }

        return hash
    }
}
