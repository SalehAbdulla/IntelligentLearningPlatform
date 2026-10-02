//
//  FileBookmarkStore.swift
//  StudyForge
//
//  The on-device store for bookmark collections: one JSON file in Application Support.
//
//  WHY A FILE AND NOT FIRESTORE — YET
//  ----------------------------------
//  docs/05 §2.5 defines `collections/{id}` and `bookmarks/{id}` with owner-only rules, and
//  `backend/firestore.rules` already enforces them. What that does not give us is a bookmarks
//  screen that works before a project is configured — which is the whole reason the other stores
//  are local-first too. This file is the local half; the rules are the server half, waiting behind
//  the same protocol.
//

import Foundation

actor FileBookmarkStore: BookmarkStore {

    private let fileURL: URL

    /// The collections once read. `nil` until then, so the file is touched at most once per launch.
    private var cache: [BookmarkCollection]?

    /// - Parameter directory: where to keep the file. Injected so a test can point at a temporary
    ///   directory rather than the real Application Support folder.
    init(directory: URL? = nil) {
        let base = directory ?? Self.defaultDirectory
        self.fileURL = base.appendingPathComponent("bookmarks.json")
    }

    // MARK: BookmarkStore

    func all() async throws -> [BookmarkCollection] {
        try load().sorted { $0.updatedAt > $1.updatedAt }
    }

    func collection(id: String) async throws -> BookmarkCollection? {
        try load().first { $0.id == id }
    }

    func add(_ collection: BookmarkCollection) async throws {
        var collections = try load()
        if let index = collections.firstIndex(where: { $0.id == collection.id }) {
            collections[index] = collection
        } else {
            collections.append(collection)
        }
        try persist(collections)
    }

    func delete(id: String) async throws {
        var collections = try load()
        collections.removeAll { $0.id == id }
        try persist(collections)
    }

    // MARK: Storage

    private func load() throws -> [BookmarkCollection] {
        if let cache { return cache }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            cache = []
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([BookmarkCollection].self, from: data)
            cache = decoded
            return decoded
        } catch {
            throw BookmarkError.storageFailed
        }
    }

    private func persist(_ collections: [BookmarkCollection]) throws {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(collections)
            try data.write(to: fileURL, options: .atomic)
            cache = collections
        } catch {
            throw BookmarkError.storageFailed
        }
    }

    /// Application Support, with a fallback.
    private static var defaultDirectory: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first
            .map { $0.appendingPathComponent("StudyForge", isDirectory: true) }
            ?? FileManager.default.temporaryDirectory
    }
}