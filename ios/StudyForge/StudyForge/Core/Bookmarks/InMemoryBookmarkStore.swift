//
//  InMemoryBookmarkStore.swift
//  StudyForge
//
//  A `BookmarkStore` that keeps everything in memory — previews and tests.
//
//  A REAL conformance rather than a stub, mirroring `InMemoryFolderStore`, so a screen driven by
//  it behaves exactly as it does against the file store.
//

import Foundation

actor InMemoryBookmarkStore: BookmarkStore {

    private var collections: [BookmarkCollection]

    /// When set, every call fails with it until cleared.
    private var failure: BookmarkError?

    init(seededWith collections: [BookmarkCollection] = []) {
        self.collections = collections
    }

    // MARK: BookmarkStore

    func all() async throws -> [BookmarkCollection] {
        try failIfForced()
        return collections.sorted { $0.updatedAt > $1.updatedAt }
    }

    func collection(id: String) async throws -> BookmarkCollection? {
        try failIfForced()
        return collections.first { $0.id == id }
    }

    func add(_ collection: BookmarkCollection) async throws {
        try failIfForced()
        if let index = collections.firstIndex(where: { $0.id == collection.id }) {
            collections[index] = collection
        } else {
            collections.append(collection)
        }
    }

    func delete(id: String) async throws {
        try failIfForced()
        collections.removeAll { $0.id == id }
    }

    // MARK: Test and preview controls

    /// Forces every call to fail with `error`. Pass `nil` to restore success.
    func forceFailure(_ error: BookmarkError?) {
        failure = error
    }

    private func failIfForced() throws {
        if let failure { throw failure }
    }
}