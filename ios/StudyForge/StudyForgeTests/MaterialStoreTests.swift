//
//  MaterialStoreTests.swift
//  StudyForgeTests
//
//  The on-device store, plus the two facts about a material that other layers depend on: its
//  content hash — the AI response cache keys on the same digest, and `firestore.rules` requires
//  one on create — and its source's stored value, which is a wire format rather than a name.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Material store")
struct MaterialStoreTests {

    /// A directory of its own per test, so runs cannot see each other's library.
    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("studyforge-tests-\(UUID().uuidString)", isDirectory: true)
    }

    private func material(
        id: String = UUID().uuidString,
        title: String = "Lecture 4",
        text: String = "Normalisation removes redundancy.",
        createdAt: Date = .now,
        tags: [String] = []
    ) -> Material {
        Material(
            id: id,
            title: title,
            source: .pdf,
            text: text,
            tags: tags,
            createdAt: createdAt
        )
    }

    // MARK: The file store

    @Test("An empty store is empty, not an error")
    func emptyStoreIsEmpty() async throws {
        let store = FileMaterialStore(directory: temporaryDirectory())

        let all = try await store.all()

        #expect(all.isEmpty)
    }

    @Test("A material round-trips, newest first")
    func roundTripsNewestFirst() async throws {
        let store = FileMaterialStore(directory: temporaryDirectory())
        let older = material(title: "Older", createdAt: .now.addingTimeInterval(-3600))
        let newer = material(title: "Newer", createdAt: .now)

        try await store.add(older)
        try await store.add(newer)

        let all = try await store.all()
        #expect(all.map(\.title) == ["Newer", "Older"])
    }

    @Test("A second store over the same directory sees what the first wrote")
    func writesArePersistedNotJustCached() async throws {
        // The whole reason the file store exists alongside the in-memory one: a library has to
        // survive a launch, which a cache alone does not.
        let directory = temporaryDirectory()
        let first = FileMaterialStore(directory: directory)
        try await first.add(material(title: "Persisted"))

        let second = FileMaterialStore(directory: directory)
        let all = try await second.all()

        #expect(all.map(\.title) == ["Persisted"])
    }

    @Test("Adding the same id twice replaces rather than duplicates")
    func addingTheSameIdReplaces() async throws {
        let store = FileMaterialStore(directory: temporaryDirectory())

        try await store.add(material(id: "material-1", title: "First"))
        try await store.add(material(id: "material-1", title: "Second"))

        let all = try await store.all()
        #expect(all.count == 1)
        #expect(all.first?.title == "Second")
    }

    @Test("A material can be fetched by id, and a missing id is nil")
    func fetchesById() async throws {
        let store = FileMaterialStore(directory: temporaryDirectory())
        try await store.add(material(id: "material-1", title: "Lecture 4"))

        let found = try await store.material(id: "material-1")
        let missing = try await store.material(id: "no-such-id")

        #expect(found?.title == "Lecture 4")
        #expect(missing == nil)
    }

    @Test("Deleting removes it, and deleting something already gone is not an error")
    func deletes() async throws {
        let store = FileMaterialStore(directory: temporaryDirectory())
        try await store.add(material(id: "material-1"))

        try await store.delete(id: "material-1")
        let all = try await store.all()
        #expect(all.isEmpty)

        // Twice, because a swipe action can fire on a row whose deletion already landed.
        try await store.delete(id: "material-1")
    }

    // MARK: The content hash

    @Test("The text hash is the SHA-256 of the text")
    func textHashIsSHA256() {
        // A fixed vector, so swapping the algorithm cannot pass unnoticed.
        #expect(
            ContentHash.sha256Hex(of: "abc")
                == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        )
    }

    @Test("The hash follows the text and is stable for the same text")
    func hashFollowsTheText() {
        let first = material(text: "same text")
        let second = material(text: "same text")
        let different = material(text: "other text")

        #expect(first.textHash == second.textHash)
        #expect(first.textHash != different.textHash)
        #expect(first.textHash == ContentHash.sha256Hex(of: "same text"))
    }

    @Test("The character count and the no-text flag describe the extracted text")
    func describesTheExtractedText() {
        #expect(material(text: "12345").characterCount == 5)
        #expect(material(text: "   \n ").hasNoText)
        #expect(material(text: "words").hasNoText == false)
    }

    // MARK: The stored vocabulary

    @Test("Every source stores the value docs/05 §3 documents")
    func sourcesMatchTheDocumentedVocabulary() {
        #expect(MaterialSource.allCases.map(\.storageValue) == [
            "pdf", "image", "scan", "link", "text",
        ])
    }
}
