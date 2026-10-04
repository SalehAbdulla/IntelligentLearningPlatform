//
//  BookmarkStoreTests.swift
//  StudyForgeTests
//
//  Tests for the bookmark models and their store.
//

import Foundation
import Testing
@testable import StudyForge

// MARK: - Model

@Suite("Bookmark model")
struct BookmarkModelTests {

    private func collection() -> BookmarkCollection {
        BookmarkCollection(
            id: "c1",
            name: "Exam revision",
            bookmarks: [
                Bookmark(kind: .material, referenceId: "m1", title: "Lecture 4", savedOffline: true),
                Bookmark(kind: .deck, referenceId: "d1", title: "Normalisation cards"),
            ]
        )
    }

    @Test("A collection round-trips through JSON without losing bookmarks")
    func codableRoundTrip() throws {
        let original = collection()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BookmarkCollection.self, from: data)

        #expect(decoded == original)
        #expect(decoded.bookmarks.first?.kind == .material)
        #expect(decoded.bookmarks.first?.savedOffline == true)
    }

    @Test("The offline count is what drives the badge, and an empty collection has none")
    func offlineAggregates() {
        let collection = collection()
        #expect(collection.offlineCount == 1)
        #expect(collection.hasOffline)
        #expect(BookmarkCollection(name: "Empty").hasOffline == false)
    }

    @Test("A collection knows what it already holds, by reference and kind")
    func duplicateDetection() {
        let collection = collection()
        #expect(collection.contains(referenceId: "m1", kind: .material))
        #expect(collection.contains(referenceId: "m1", kind: .deck) == false, "kind is part of the identity")
        #expect(collection.contains(referenceId: "x", kind: .material) == false)
    }
}

// MARK: - Store

@Suite("Bookmark store")
struct BookmarkStoreTests {

    private func collection(id: String, updatedAt: Date) -> BookmarkCollection {
        BookmarkCollection(id: id, name: "Collection", createdAt: .now, updatedAt: updatedAt)
    }

    @Test("The in-memory store returns collections most recently updated first")
    func inMemoryOrdersNewestFirst() async throws {
        let store = InMemoryBookmarkStore(seededWith: [
            collection(id: "old", updatedAt: .now.addingTimeInterval(-3600)),
            collection(id: "new", updatedAt: .now),
        ])
        #expect(try await store.all().map(\.id) == ["new", "old"])
    }

    @Test("The in-memory store adds, looks up and deletes")
    func inMemoryCRUD() async throws {
        let store = InMemoryBookmarkStore()
        let record = collection(id: "c1", updatedAt: .now)

        try await store.add(record)
        #expect(try await store.collection(id: "c1") == record)

        try await store.delete(id: "c1")
        #expect(try await store.collection(id: "c1") == nil)
    }

    @Test("The in-memory store surfaces a forced failure")
    func inMemoryFailureIsReported() async {
        let store = InMemoryBookmarkStore()
        await store.forceFailure(.storageFailed)
        await #expect(throws: BookmarkError.self) {
            try await store.all()
        }
    }

    @Test("The file store persists collections across instances")
    func fileStorePersists() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("bookmark-tests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        try await FileBookmarkStore(directory: directory).add(collection(id: "c1", updatedAt: .now))
        #expect(try await FileBookmarkStore(directory: directory).collection(id: "c1")?.id == "c1")
    }

    @Test("Bookmark store failures map to the app's single user-facing error")
    func errorMapsToAppError() {
        let expected = AppError.server(reference: "bookmark-store-failed")
        #expect(BookmarkError.storageFailed.asAppError == expected)
        // And through the boundary the view models actually use, so the mapping is not merely
        // available but wired.
        #expect(AppError.from(BookmarkError.storageFailed) == expected)
    }
}