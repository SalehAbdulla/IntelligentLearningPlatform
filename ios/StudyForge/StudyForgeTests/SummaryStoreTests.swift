//
//  SummaryStoreTests.swift
//  StudyForgeTests
//
//  Tests for the saved-summary model and its stores.
//
//  The load-bearing one is `codableRoundTrip`: a summary's value is its citation, so a save that
//  dropped the provenance would silently turn "tap to see the source" into dead UI. Encoding and
//  decoding the whole record proves the citation survives the trip to disk.
//

import Foundation
import Testing
@testable import StudyForge

// MARK: - Model

@Suite("Summary model")
struct SummaryModelTests {

    private func summary(createdAt: Date = .now, id: String = "s1") -> Summary {
        Summary(
            id: id,
            title: "Lecture 4 — Normalisation",
            length: .examReady,
            style: .cornell,
            language: .arabic,
            tldr: "Third normal form removes transitive dependencies.",
            keyPoints: ["A relation is in 3NF when it has no transitive dependencies."],
            glossary: [SummaryTerm(term: "3NF", definition: "Third normal form.")],
            provenance: AIProvenance(materialId: "m1", pageNumbers: [12, 13], confidence: .high),
            tier: .firebaseAI,
            createdAt: createdAt
        )
    }

    @Test("A summary round-trips through JSON without losing its citation")
    func codableRoundTrip() throws {
        let summary = summary()

        let data = try JSONEncoder().encode(summary)
        let decoded = try JSONDecoder().decode(Summary.self, from: data)

        #expect(decoded == summary)
        #expect(decoded.materialId == "m1", "materialId must derive from provenance, not drift")
        #expect(decoded.provenance.citationLabel == "pp.12–13")
    }
}

// MARK: - In-memory store

@Suite("Summary store")
struct SummaryStoreTests {

    private func summary(id: String, createdAt: Date) -> Summary {
        Summary(
            id: id,
            title: "T",
            length: .standard,
            style: .bullets,
            language: .english,
            tldr: "tl",
            keyPoints: ["k"],
            glossary: [],
            provenance: AIProvenance(materialId: "m", pageNumbers: [1], confidence: .high),
            tier: .onDevice,
            createdAt: createdAt
        )
    }

    @Test("The in-memory store returns summaries newest first")
    func inMemoryOrdersNewestFirst() async throws {
        let store = InMemorySummaryStore(seededWith: [
            summary(id: "old", createdAt: .now.addingTimeInterval(-3600)),
            summary(id: "new", createdAt: .now),
        ])

        let all = try await store.all()

        #expect(all.map(\.id) == ["new", "old"])
    }

    @Test("The in-memory store adds, looks up and deletes")
    func inMemoryCRUD() async throws {
        let store = InMemorySummaryStore()
        let record = summary(id: "s1", createdAt: .now)

        try await store.add(record)
        #expect(try await store.summary(id: "s1") == record)

        try await store.delete(id: "s1")
        #expect(try await store.summary(id: "s1") == nil)
    }

    @Test("The in-memory store surfaces a forced failure")
    func inMemoryFailureIsReported() async {
        let store = InMemorySummaryStore()
        await store.forceFailure(.storageFailed)

        await #expect(throws: SummaryError.self) {
            try await store.all()
        }
    }

    @Test("The file store persists summaries across instances")
    func fileStorePersistsAcrossInstances() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("summary-tests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        try await FileSummaryStore(directory: directory).add(summary(id: "s1", createdAt: .now))

        // A fresh instance reads from disk, proving the write was durable rather than cached.
        let reopened = FileSummaryStore(directory: directory)
        #expect(try await reopened.summary(id: "s1")?.id == "s1")
    }

    @Test("Summary store failures map to the app's single user-facing error")
    func errorMapsToAppError() {
        #expect(SummaryError.storageFailed.asAppError == AppError.server(reference: "summary-store-failed"))
    }
}
