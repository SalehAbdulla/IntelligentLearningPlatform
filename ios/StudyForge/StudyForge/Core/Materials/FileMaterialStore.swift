//
//  FileMaterialStore.swift
//  StudyForge
//
//  The on-device store: one JSON file in Application Support.
//
//  WHY A FILE AND NOT FIRESTORE
//  ---------------------------
//  D24 (docs/09): materials stay local. A PDF's text does not need to leave the device to be
//  useful, because the model that reads it runs here — so the durable home for a library is the
//  device. This is also what makes the library work in aeroplane mode, which is the brief's own
//  requirement rather than a nicety.
//
//  `actor`, for two reasons: it owns mutable state (the loaded library), and file IO must not run
//  on the main actor.
//

import Foundation

actor FileMaterialStore: MaterialStore {

    private let fileURL: URL

    /// The library once it has been read. `nil` until then, so the file is touched at most once
    /// per launch.
    private var cache: [Material]?

    /// - Parameter directory: where to keep the file. Injected so a test can point at a temporary
    ///   directory rather than the real Application Support folder.
    init(directory: URL? = nil) {
        let base = directory ?? Self.defaultDirectory
        self.fileURL = base.appendingPathComponent("materials.json")
    }

    // MARK: MaterialStore

    func all() async throws -> [Material] {
        // Newest first: the library is read most-recently-imported first, and the sort lives
        // here rather than in each screen so every caller agrees.
        try load().sorted { $0.createdAt > $1.createdAt }
    }

    func material(id: String) async throws -> Material? {
        try load().first { $0.id == id }
    }

    func add(_ material: Material) async throws {
        var library = try load()
        if let index = library.firstIndex(where: { $0.id == material.id }) {
            library[index] = material
        } else {
            library.append(material)
        }
        try persist(library)
    }

    func delete(id: String) async throws {
        var library = try load()
        library.removeAll { $0.id == id }
        try persist(library)
    }

    // MARK: Storage

    private func load() throws -> [Material] {
        if let cache { return cache }

        // No file is not a failure: it is a student who has not imported anything yet.
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            cache = []
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([Material].self, from: data)
            cache = decoded
            return decoded
        } catch {
            throw MaterialError.storageFailed
        }
    }

    private func persist(_ library: [Material]) throws {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(library)
            // `.atomic`: an interrupted write must not leave a half-written library behind,
            // which is the failure this file exists to avoid.
            try data.write(to: fileURL, options: .atomic)
            cache = library
        } catch {
            throw MaterialError.storageFailed
        }
    }

    /// Application Support, with a fallback.
    ///
    /// The fallback is defensive rather than expected: the directory is always present on iOS,
    /// but a `[0]` on an empty array is a crash, and a store that cannot be constructed is worse
    /// than one in an odd place.
    private static var defaultDirectory: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first
            .map { $0.appendingPathComponent("StudyForge", isDirectory: true) }
            ?? FileManager.default.temporaryDirectory
    }
}
