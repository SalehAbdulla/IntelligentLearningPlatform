//
//  FileGroupStore.swift
//  StudyForge
//
//  The on-device store for group revision spaces: one JSON file in Application Support.
//
//  WHY A FILE AND NOT FIRESTORE — YET
//  ----------------------------------
//  docs/05 §2.4 defines `groups/{id}` with member-based rules, and `backend/firestore.rules` already
//  enforces them. What that does not give us is a group screen that works before a project is
//  configured — which is the whole reason the other stores are local-first too. This file is the
//  local half; the rules are the server half, waiting behind the same protocol.
//

import Foundation

actor FileGroupStore: GroupStore {

    private let fileURL: URL

    /// The groups once read. `nil` until then, so the file is touched at most once per launch.
    private var cache: [StudyGroup]?

    /// - Parameter directory: where to keep the file. Injected so a test can point at a temporary
    ///   directory rather than the real Application Support folder.
    init(directory: URL? = nil) {
        let base = directory ?? Self.defaultDirectory
        self.fileURL = base.appendingPathComponent("groups.json")
    }

    // MARK: GroupStore

    func all() async throws -> [StudyGroup] {
        try load().sorted { $0.updatedAt > $1.updatedAt }
    }

    func group(id: String) async throws -> StudyGroup? {
        try load().first { $0.id == id }
    }

    func add(_ group: StudyGroup) async throws {
        var groups = try load()
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index] = group
        } else {
            groups.append(group)
        }
        try persist(groups)
    }

    func delete(id: String) async throws {
        var groups = try load()
        groups.removeAll { $0.id == id }
        try persist(groups)
    }

    func group(withInviteCode code: String) async throws -> StudyGroup? {
        let needle = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return try load().first { $0.inviteCode.uppercased() == needle }
    }

    // MARK: Storage

    private func load() throws -> [StudyGroup] {
        if let cache { return cache }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            cache = []
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([StudyGroup].self, from: data)
            cache = decoded
            return decoded
        } catch {
            throw GroupError.storageFailed
        }
    }

    private func persist(_ groups: [StudyGroup]) throws {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(groups)
            try data.write(to: fileURL, options: .atomic)
            cache = groups
        } catch {
            throw GroupError.storageFailed
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