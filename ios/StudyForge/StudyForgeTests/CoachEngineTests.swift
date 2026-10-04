//
//  CoachEngineTests.swift
//  StudyForgeTests
//
//  F15 — the four techniques the advanced feature claims, tested where they can actually be
//  checked: chunking, retrieval, enforced citation and the deterministic planner.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Text chunking (F15)")
struct TextChunkingTests {

    @Test("A page marker becomes the chunk's page number")
    func pagesAreCarried() {
        let text = """
        \(PageMarker.forPage(1))Alpha beta gamma delta epsilon.
        \(PageMarker.forPage(2))Zeta eta theta iota kappa.
        """

        let chunks = TextChunker.chunk(text, materialId: "m1")

        #expect(chunks.contains { $0.page == 1 })
        #expect(chunks.contains { $0.page == 2 })
    }

    @Test("A chunk never straddles a page boundary")
    func pagesDoNotMix() {
        let text = """
        \(PageMarker.forPage(1))First page content here.
        \(PageMarker.forPage(2))Second page content here.
        """

        for chunk in TextChunker.chunk(text, materialId: "m1") {
            #expect(!(chunk.text.contains("First") && chunk.text.contains("Second")))
        }
    }

    @Test("Text with no pages chunks with a nil page rather than an invented one")
    func noPagesMeansNoPageNumber() {
        let chunks = TextChunker.chunk("Just some pasted text with no page structure.", materialId: "m1")

        #expect(!chunks.isEmpty)
        #expect(chunks.allSatisfy { $0.page == nil })
    }

    @Test("A long paragraph is broken at word boundaries, never mid-word")
    func longParagraphsSplitCleanly() {
        let paragraph = Array(repeating: "normalisation", count: 400).joined(separator: " ")
        let text = "\(PageMarker.forPage(3))\(paragraph)"

        let chunks = TextChunker.chunk(text, materialId: "m1")

        #expect(chunks.count > 1)
        for chunk in chunks {
            // A mid-word cut would leave a fragment that is not the repeated token.
            #expect(chunk.text.split(separator: " ").allSatisfy { $0 == "normalisation" })
        }
    }

    @Test("Chunk ids are stable, so re-indexing replaces rather than duplicates")
    func idsAreStable() {
        let text = "\(PageMarker.forPage(1))Stable content for chunk identity."

        let first = TextChunker.chunk(text, materialId: "m1").map(\.id)
        let second = TextChunker.chunk(text, materialId: "m1").map(\.id)

        #expect(first == second)
        #expect(first.first == "m1#0")
    }
}

@Suite("Retrieval (F15)")
struct RetrievalTests {

    private func service() -> LocalRetrievalService {
        LocalRetrievalService(embedder: HashingEmbedder())
    }

    private func chunks(_ text: String, material: String = "m1") -> [TextChunk] {
        TextChunker.chunk(text, materialId: material)
    }

    @Test("The same text always produces the same vector — no per-process hashing")
    func embeddingIsStable() {
        let embedder = HashingEmbedder()
        #expect(embedder.embed("normalisation removes redundancy") == embedder.embed("normalisation removes redundancy"))
    }

    @Test("A passage about the query ranks above an unrelated one")
    func relevantChunkWins() async throws {
        let service = service()
        try await service.index(materialID: "m1", chunks: chunks(
            "\(PageMarker.forPage(1))Normalisation removes redundancy by organising columns and tables."
        ))
        try await service.index(materialID: "m2", chunks: chunks(
            "\(PageMarker.forPage(1))The cafeteria menu rotates on a fortnightly basis.",
            material: "m2"
        ))

        let results = try await service.retrieve(query: "what does normalisation remove", scope: [], topK: 5)

        #expect(results.first?.chunk.materialId == "m1")
    }

    @Test("An unrelated query retrieves nothing at all")
    func unrelatedQueryReturnsNothing() async throws {
        let service = service()
        try await service.index(materialID: "m1", chunks: chunks(
            "\(PageMarker.forPage(1))Normalisation removes redundancy by organising columns."
        ))

        let results = try await service.retrieve(query: "quantum chromodynamics", scope: [], topK: 5)

        #expect(results.isEmpty, "a weak match is not grounding")
    }

    @Test("The scope restricts retrieval to the chosen materials")
    func scopeRestricts() async throws {
        let service = service()
        try await service.index(materialID: "m1", chunks: chunks("\(PageMarker.forPage(1))Database normalisation.", material: "m1"))
        try await service.index(materialID: "m2", chunks: chunks("\(PageMarker.forPage(1))Database normalisation again.", material: "m2"))

        let results = try await service.retrieve(query: "database normalisation", scope: ["m2"], topK: 5)

        #expect(!results.isEmpty)
        #expect(results.allSatisfy { $0.chunk.materialId == "m2" })
    }

    @Test("Re-indexing replaces, and an empty re-index removes")
    func reindexReplaces() async throws {
        let service = service()
        try await service.index(materialID: "m1", chunks: chunks("\(PageMarker.forPage(1))First version of the text."))
        #expect(await service.indexedChunkCount(materialID: "m1") == 1)

        try await service.index(materialID: "m1", chunks: chunks("\(PageMarker.forPage(1))Second version."))
        #expect(await service.indexedChunkCount(materialID: "m1") == 1, "replaced, not appended")

        try await service.index(materialID: "m1", chunks: [])
        #expect(await service.indexedChunkCount(materialID: "m1") == 0)
    }
}

@Suite("Grounded answering (F15)")
@MainActor
struct GroundedAnsweringTests {

    private func makeService(materialText: String) async -> CoachService {
        let materials = InMemoryMaterialStore(seededWith: [
            Material(id: "m1", title: "Lecture 4", source: .pdf, text: materialText),
        ])
        let service = CoachService(
            retrieval: LocalRetrievalService(embedder: HashingEmbedder()),
            router: AIRouter.standard(governor: AICostGovernor()),
            materials: materials
        )
        await service.reindex()
        return service
    }

    @Test("A question nothing supports is refused WITHOUT consulting an engine")
    func refusesWithoutGrounding() async throws {
        let service = await makeService(
            materialText: "\(PageMarker.forPage(1))Normalisation removes redundancy from a schema."
        )

        let answer = try await service.ask("quantum chromodynamics", scope: [], level: .standard)

        #expect(answer.isGrounded == false)
        #expect(answer.citations.isEmpty)
        #expect(answer.text == L10n.coachNoSource.string)
        #expect(answer.engineTier == nil, "the model was never asked")
    }

    @Test("A question the material supports comes back grounded, with citations")
    func answersWithCitations() async throws {
        let service = await makeService(
            materialText: "\(PageMarker.forPage(12))Normalisation removes redundancy by organising columns and tables."
        )

        let answer = try await service.ask("what does normalisation remove", scope: [], level: .standard)

        #expect(answer.isGrounded)
        #expect(!answer.citations.isEmpty)
        #expect(answer.engineTier != nil)
    }

    @Test("A citation points at a real page of a real material — it is ours, not the model's")
    func citationsAreOurs() async throws {
        let service = await makeService(
            materialText: "\(PageMarker.forPage(12))Normalisation removes redundancy by organising columns."
        )

        let answer = try await service.ask("normalisation redundancy", scope: [], level: .standard)
        let citation = try #require(answer.citations.first)

        #expect(citation.materialId == "m1")
        #expect(citation.materialTitle == "Lecture 4")
        #expect(citation.page == 12)
        #expect(citation.pageLabel == "p.12")
    }

    @Test("An empty question is refused before any work happens")
    func emptyQuestion() async {
        let service = await makeService(materialText: "\(PageMarker.forPage(1))Some real text here.")

        await #expect(throws: CoachError.emptyQuestion) {
            try await service.ask("   ", scope: [], level: .standard)
        }
    }

    @Test("An empty library refuses rather than answering from nowhere")
    func emptyLibraryRefuses() async throws {
        let service = CoachService(
            retrieval: LocalRetrievalService(embedder: HashingEmbedder()),
            router: AIRouter.standard(governor: AICostGovernor()),
            materials: InMemoryMaterialStore()
        )
        await service.reindex()

        let answer = try await service.ask("anything at all", scope: [], level: .standard)

        #expect(answer.isGrounded == false)
        #expect(answer.engineTier == nil)
    }
}

@Suite("Study path planner (F15)")
struct StudyPathPlannerTests {

    @Test("The weakest topic leads the path")
    func weakestFirst() async throws {
        let planner = LocalCoachPlanner(minutesAvailable: 60)

        let steps = try await planner.studyPath(for: "u1", weakTopics: [
            TopicScore(topic: "joins", mastery: 0.8),
            TopicScore(topic: "normalisation", mastery: 0.2),
        ])

        #expect(steps.first?.topic == "normalisation")
    }

    @Test("Each topic is worked read → flashcards → quiz")
    func progression() async throws {
        let planner = LocalCoachPlanner(minutesAvailable: 90)

        let steps = try await planner.studyPath(
            for: "u1",
            weakTopics: [TopicScore(topic: "normalisation", mastery: 0.1)]
        )
        let activities = steps.filter { $0.topic == "normalisation" }.map(\.activity)

        #expect(Array(activities.prefix(3)) == [.read, .flashcards, .quiz])
    }

    @Test("The path fits the time budget")
    func fitsBudget() async throws {
        let planner = LocalCoachPlanner(minutesAvailable: 30)

        let steps = try await planner.studyPath(for: "u1", weakTopics: [TopicScore(topic: "a", mastery: 0)])

        #expect(steps.reduce(0) { $0 + $1.minutes } <= 30)
    }

    @Test("Nothing weak yields an empty path, not a failure")
    func emptyIsValid() async throws {
        #expect(try await LocalCoachPlanner().studyPath(for: "u1", weakTopics: []).isEmpty)
    }

    @Test("A completely mastered topic is not scheduled")
    func masteredTopicsAreSkipped() async throws {
        let steps = try await LocalCoachPlanner(minutesAvailable: 60)
            .studyPath(for: "u1", weakTopics: [TopicScore(topic: "joins", mastery: 1)])

        #expect(steps.isEmpty)
    }

    @Test("The same input always yields the same path — the planner, not the model")
    func deterministic() async throws {
        let planner = LocalCoachPlanner(minutesAvailable: 45)
        let topics = [TopicScore(topic: "joins", mastery: 0.3)]

        let first = try await planner.studyPath(for: "u1", weakTopics: topics)
        let second = try await planner.studyPath(for: "u1", weakTopics: topics)

        #expect(first == second)
        #expect(!first.isEmpty)
    }
}
