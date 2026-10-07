//
//  FileTaxonomyStore.swift
//  StudyForge
//
//  The on-device store for the taxonomy: one JSON file in Application Support.
//
//  WHY A FILE AND NOT FIRESTORE, YET
//  ---------------------------------
//  docs/05 gives subjects and tags a shared, readable collection, and merging two terms is a
//  server-side operation on content counts. The file is the stand-in that keeps K06 demonstrable before
//  a backend exists; the protocol is the seam the real query swaps in behind.
//

import Foundation

actor FileTaxonomyStore: TaxonomyStore {

    private let fileURL: URL

    /// Read once per launch, like the other file stores.
    private var cache: [TaxonomyTerm]?

    /// - Parameter directory: where to keep the file. Injected so a test can point at a temporary
    ///   directory rather than the real Application Support folder.
    init(directory: URL? = nil) {
        let base = directory ?? Self.defaultDirectory
        self.fileURL = base.appendingPathComponent("taxonomy.json")
    }

    // MARK: TaxonomyStore

    func terms() async throws -> [TaxonomyTerm] {
        try load().sorted {
            if $0.kind != $1.kind { return $0.kind.rawValue < $1.kind.rawValue }
            if $0.sortIndex != $1.sortIndex { return $0.sortIndex < $1.sortIndex }
            return $0.name < $1.name
        }
    }

    func save(_ term: TaxonomyTerm) async throws {
        var terms = try load()
        if let index = terms.firstIndex(where: { $0.id == term.id }) {
            terms[index] = term
        } else {
            terms.append(term)
        }
        try persist(terms)
    }

    func remove(id: String) async throws {
        var terms = try load()
        terms.removeAll { $0.id == id }
        try persist(terms)
    }

    // MARK: Storage

    private func load() throws -> [TaxonomyTerm] {
        if let cache { return cache }
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            cache = []
            return []
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([TaxonomyTerm].self, from: data)
            cache = decoded
            return decoded
        } catch {
            throw AdminError.storageFailed
        }
    }

    private func persist(_ terms: [TaxonomyTerm]) throws {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(terms)
            try data.write(to: fileURL, options: .atomic)
            cache = terms
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
