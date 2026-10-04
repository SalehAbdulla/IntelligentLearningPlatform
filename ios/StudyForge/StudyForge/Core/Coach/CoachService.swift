//
//  CoachService.swift
//  StudyForge
//
//  F15 — the orchestrator: retrieve, ask, enforce the citation (docs/02 §5, techniques 1–2).
//
//  THE ONE RULE THIS FILE EXISTS TO ENFORCE
//  ----------------------------------------
//  A grounded answer, or an honest refusal. There is no third outcome. So:
//
//    · nothing relevant retrieved  → the model is NEVER asked. It is not prompted to "say you don't
//      know" and trusted to comply; the call is not made at all. That is the difference between a
//      guard-rail and a hope.
//    · answered but cites nothing we supplied → the answer is discarded and the refusal is shown.
//      A model that ignores its evidence has produced exactly the confident guess this feature
//      exists to prevent.
//
//  Citation is therefore ENFORCED here rather than rendered nicely and trusted: every `Citation`
//  the message carries is built from a chunk WE retrieved, matched by id against the set we sent.
//

import Foundation

/// An answer, and the evidence for it.
struct GroundedAnswer: Equatable, Sendable {

    let text: String
    let citations: [Citation]

    /// The tier that produced it, for H02's engine badge (`nil` on a refusal).
    let engineTier: String?

    /// Whether the answer is supported by the student's own materials.
    ///
    /// `false` is a SUCCESSFUL outcome: the coach correctly declined rather than guessed.
    let isGrounded: Bool
}

/// Failures in the coach layer, in the app's own vocabulary.
enum CoachError: Error, Equatable {

    /// The question was empty after trimming.
    case emptyQuestion

    /// Nothing in the library could be indexed.
    case noMaterials

    var asAppError: AppError {
        switch self {
        case .emptyQuestion:
            .server(reference: "coach-empty-question")
        case .noMaterials:
            .materialUnreadable(reason: "There is nothing in your library for the coach to read yet.")
        }
    }
}

/// Retrieval plus grounded answering.
///
/// `@MainActor` because it is reached only from view models; the expensive work is `await`ed on the
/// retrieval actor and the router, so the main actor is yielded rather than blocked.
@MainActor
final class CoachService {

    private let retrieval: any RetrievalService
    private let router: AIRouter
    private let materials: any MaterialStore

    /// How many passages go into the prompt. Small on purpose: a tight context window is what keeps
    /// an answer checkable, and a citation sheet listing twelve sources is one nobody reads.
    static let defaultTopK = 4

    init(
        retrieval: any RetrievalService,
        router: AIRouter,
        materials: any MaterialStore
    ) {
        self.retrieval = retrieval
        self.router = router
        self.materials = materials
    }

    /// Rebuilds the index from the library.
    ///
    /// Called when the library changes rather than on every question: embedding a whole library per
    /// keystroke would make the ask bar feel broken.
    func reindex() async {
        guard let library = try? await materials.all() else { return }

        for material in library where !material.hasNoText {
            let chunks = TextChunker.chunk(material.text, materialId: material.id)
            try? await retrieval.index(materialID: material.id, chunks: chunks)
        }
    }

    /// Answers a question, or declines to.
    func ask(
        _ question: String,
        scope: [String],
        level: AnswerLevel,
        topK: Int = defaultTopK
    ) async throws -> GroundedAnswer {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CoachError.emptyQuestion }

        let retrieved = try await retrieval.retrieve(query: trimmed, scope: scope, topK: topK)

        // Rule one: no relevant passage, no question asked.
        guard !retrieved.isEmpty else {
            return GroundedAnswer(
                text: L10n.coachNoSource.string,
                citations: [],
                engineTier: nil,
                isGrounded: false
            )
        }

        let prompt = AICoachPrompt(
            question: trimmed,
            chunks: retrieved.map {
                AICoachChunk(
                    id: $0.chunk.id,
                    materialId: $0.chunk.materialId,
                    text: $0.chunk.text,
                    page: $0.chunk.page
                )
            },
            depth: level.promptDirective,
            language: level.language
        )

        let generated = try await router.answer(prompt)

        // Rule two: the model may only cite what it was given.
        let supplied = Dictionary(uniqueKeysWithValues: retrieved.map { ($0.chunk.id, $0) })
        let titles = await materialTitles()

        let citations = generated.value.citedChunkIds
            .compactMap { supplied[$0] }
            .map {
                Citation(
                    chunk: $0.chunk,
                    materialTitle: titles[$0.chunk.materialId] ?? "",
                    score: $0.score
                )
            }

        guard !citations.isEmpty else {
            return GroundedAnswer(
                text: L10n.coachNoSource.string,
                citations: [],
                engineTier: generated.tier.rawValue,
                isGrounded: false
            )
        }

        return GroundedAnswer(
            text: generated.value.answer,
            citations: citations,
            engineTier: generated.tier.rawValue,
            isGrounded: true
        )
    }

    // MARK: Helpers

    /// material id → title, for labelling citations.
    private func materialTitles() async -> [String: String] {
        guard let library = try? await materials.all() else { return [:] }
        return Dictionary(uniqueKeysWithValues: library.map { ($0.id, $0.title) })
    }
}
