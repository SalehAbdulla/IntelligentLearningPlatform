//
//  FileDeckStore.swift
//  StudyForge
//
//  The on-device store for decks: one JSON file in Application Support.
//
//  WHY A FILE AND NOT FIRESTORE
//  ----------------------------
//  Decks must be reviewable offline, and they are derived from material that never leaves the
//  device. The file is the local half; Firestore's `decks/{id}` collection is what a future sync
//  swaps in behind this protocol.
//
//  `actor`, because it owns mutable state (the loaded decks) and file IO must not run on the main
//  actor.
//

import Foundation

actor FileDeckStore: DeckStore {

    private let fileURL: URL

    /// The decks once read. `nil` until then, so the file is touched at most once per launch.
    private var cache: [Deck]?

    /// - Parameter directory: where to keep the file. Injected so a test can point at a temporary
    ///   directory rather than the real Application Support folder.
    init(directory: URL? = nil) {
        let base = directory ?? Self.defaultDirectory
        self.fileURL = base.appendingPathComponent("decks.json")
    }

    // MARK: DeckStore

    func all() async throws -> [Deck] {
        try load().sorted { $0.updatedAt > $1.updatedAt }
    }

    func deck(id: String) async throws -> Deck? {
        try load().first { $0.id == id }
    }

    func add(_ deck: Deck) async throws {
        var decks = try load()
        if let index = decks.firstIndex(where: { $0.id == deck.id }) {
            decks[index] = deck
        } else {
            decks.append(deck)
        }
        try persist(decks)
    }

    func delete(id: String) async throws {
        var decks = try load()
        decks.removeAll { $0.id == id }
        try persist(decks)
    }

    // MARK: Storage

    private func load() throws -> [Deck] {
        if let cache { return cache }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            cache = []
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([Deck].self, from: data)
            cache = decoded
            return decoded
        } catch {
            throw DeckError.storageFailed
        }
    }

    private func persist(_ decks: [Deck]) throws {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(decks)
            try data.write(to: fileURL, options: .atomic)
            cache = decks
        } catch {
            throw DeckError.storageFailed
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
