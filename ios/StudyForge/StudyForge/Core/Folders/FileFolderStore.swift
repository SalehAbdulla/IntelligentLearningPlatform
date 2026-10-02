//
//  FileFolderStore.swift
//  StudyForge
//
//  The on-device store for shared folders: one JSON file in Application Support.
//
//  WHY A FILE AND NOT FIRESTORE — YET
//  ----------------------------------
//  docs/05 §2.4 defines `folders/{id}` with owner/member/editor rules, and `backend/firestore.rules`
//  already enforces them. What that does not give us is a folder screen that works before a project
//  is configured — which is the whole reason the other stores are local-first too. This file is the
//  local half; the rules are the server half, waiting behind the same protocol.
//

import Foundation

actor FileFolderStore: FolderStore {

    private let fileURL: URL

    /// The folders once read. `nil` until then, so the file is touched at most once per launch.
    private var cache: [SharedFolder]?

    /// - Parameter directory: where to keep the file. Injected so a test can point at a temporary
    ///   directory rather than the real Application Support folder.
    init(directory: URL? = nil) {
        let base = directory ?? Self.defaultDirectory
        self.fileURL = base.appendingPathComponent("folders.json")
    }

    // MARK: FolderStore

    func all() async throws -> [SharedFolder] {
        try load().sorted { $0.updatedAt > $1.updatedAt }
    }

    func folder(id: String) async throws -> SharedFolder? {
        try load().first { $0.id == id }
    }

    func add(_ folder: SharedFolder) async throws {
        var folders = try load()
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            folders[index] = folder
        } else {
            folders.append(folder)
        }
        try persist(folders)
    }

    func delete(id: String) async throws {
        var folders = try load()
        folders.removeAll { $0.id == id }
        try persist(folders)
    }

    // MARK: Storage

    private func load() throws -> [SharedFolder] {
        if let cache { return cache }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            cache = []
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([SharedFolder].self, from: data)
            cache = decoded
            return decoded
        } catch {
            throw FolderError.storageFailed
        }
    }

    private func persist(_ folders: [SharedFolder]) throws {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(folders)
            try data.write(to: fileURL, options: .atomic)
            cache = folders
        } catch {
            throw FolderError.storageFailed
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