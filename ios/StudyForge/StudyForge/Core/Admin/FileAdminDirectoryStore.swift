//
//  FileAdminDirectoryStore.swift
//  StudyForge
//
//  The on-device store for the platform directory: one JSON file in Application Support.
//
//  WHY A FILE AND NOT FIRESTORE — YET
//  ----------------------------------
//  docs/05 §2.1 defines `users/{uid}` with per-role reads, and a cohort-wide list is a real query
//  this device cannot make. The file is the stand-in that keeps K02 demonstrable; the protocol is the
//  seam the real query swaps in behind.
//

import Foundation

actor FileAdminDirectoryStore: AdminDirectoryStore {

    private let fileURL: URL

    /// Read once per launch, like the other file stores.
    private var cache: [PlatformUser]?

    /// - Parameter directory: where to keep the file. Injected so a test can point at a temporary
    ///   directory rather than the real Application Support folder.
    init(directory: URL? = nil) {
        let base = directory ?? Self.defaultDirectory
        self.fileURL = base.appendingPathComponent("directory.json")
    }

    // MARK: AdminDirectoryStore

    func users() async throws -> [PlatformUser] {
        try load().sorted { $0.lastLoginAt > $1.lastLoginAt }
    }

    func user(id: String) async throws -> PlatformUser? {
        try load().first { $0.id == id }
    }

    func save(_ user: PlatformUser) async throws {
        var accounts = try load()
        if let index = accounts.firstIndex(where: { $0.id == user.id }) {
            accounts[index] = user
        } else {
            accounts.append(user)
        }
        try persist(accounts)
    }

    // MARK: Storage

    private func load() throws -> [PlatformUser] {
        if let cache { return cache }
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            cache = []
            return []
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([PlatformUser].self, from: data)
            cache = decoded
            return decoded
        } catch {
            throw AdminError.storageFailed
        }
    }

    private func persist(_ accounts: [PlatformUser]) throws {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(accounts)
            try data.write(to: fileURL, options: .atomic)
            cache = accounts
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