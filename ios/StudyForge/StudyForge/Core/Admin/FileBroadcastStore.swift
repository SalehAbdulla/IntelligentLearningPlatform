//
//  FileBroadcastStore.swift
//  StudyForge
//
//  The on-device store for announcements: one JSON file in Application Support.
//

import Foundation

actor FileBroadcastStore: BroadcastStore {

    private let fileURL: URL

    /// Read once per launch, like the other file stores.
    private var cache: [Broadcast]?

    /// - Parameter directory: where to keep the file. Injected so a test can point at a temporary
    ///   directory rather than the real Application Support folder.
    init(directory: URL? = nil) {
        let base = directory ?? Self.defaultDirectory
        self.fileURL = base.appendingPathComponent("broadcasts.json")
    }

    func broadcasts() async throws -> [Broadcast] {
        try load().sorted { $0.createdAt > $1.createdAt }
    }

    func save(_ broadcast: Broadcast) async throws {
        var broadcasts = try load()
        if let index = broadcasts.firstIndex(where: { $0.id == broadcast.id }) {
            broadcasts[index] = broadcast
        } else {
            broadcasts.append(broadcast)
        }
        try persist(broadcasts)
    }

    // MARK: Storage

    private func load() throws -> [Broadcast] {
        if let cache { return cache }
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            cache = []
            return []
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([Broadcast].self, from: data)
            cache = decoded
            return decoded
        } catch {
            throw AdminError.storageFailed
        }
    }

    private func persist(_ broadcasts: [Broadcast]) throws {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(broadcasts)
            try data.write(to: fileURL, options: .atomic)
            cache = broadcasts
        } catch {
            throw AdminError.storageFailed
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
