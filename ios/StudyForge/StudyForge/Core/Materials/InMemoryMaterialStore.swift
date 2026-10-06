//
//  InMemoryMaterialStore.swift
//  StudyForge
//
//  A `MaterialStore` that keeps everything in memory — previews, tests, and the `-seedLibrary`
//  launch argument.
//
//  The same shape as `MockProfileService`: a REAL conformance rather than a stub, so a screen
//  driven by it behaves exactly as it does against the file store. A stub that only returned
//  success could not exercise the empty, no-match or failed states, which are the ones worth
//  designing.
//

import Foundation

actor InMemoryMaterialStore: MaterialStore {

    private var library: [Material]

    /// When set, every call fails with it until cleared. Lets a test reach the failed state
    /// without inventing an unwritable file.
    private var failure: MaterialError?

    init(seededWith library: [Material] = []) {
        self.library = library
    }

    // MARK: MaterialStore

    func all() async throws -> [Material] {
        try failIfForced()
        return library.sorted { $0.createdAt > $1.createdAt }
    }

    func material(id: String) async throws -> Material? {
        try failIfForced()
        return library.first { $0.id == id }
    }

    func add(_ material: Material) async throws {
        try failIfForced()
        if let index = library.firstIndex(where: { $0.id == material.id }) {
            library[index] = material
        } else {
            library.append(material)
        }
    }

    func delete(id: String) async throws {
        try failIfForced()
        library.removeAll { $0.id == id }
    }

    // MARK: Test and preview controls

    /// Forces every call to fail with `error`. Pass `nil` to restore success.
    func forceFailure(_ error: MaterialError?) {
        failure = error
    }

    private func failIfForced() throws {
        if let failure { throw failure }
    }
}
