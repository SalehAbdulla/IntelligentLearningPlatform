//
//  InMemoryFolderStore.swift
//  StudyForge
//
//  A `FolderStore` that keeps everything in memory — previews and tests.
//
//  A REAL conformance rather than a stub, mirroring `InMemoryDeckStore`, so a screen driven by it
//  behaves exactly as it does against the file store.
//

import Foundation

actor InMemoryFolderStore: FolderStore {

    private var folders: [SharedFolder]

    /// When set, every call fails with it until cleared.
    private var failure: FolderError?

    init(seededWith folders: [SharedFolder] = []) {
        self.folders = folders
    }

    // MARK: FolderStore

    func all() async throws -> [SharedFolder] {
        try failIfForced()
        return folders.sorted { $0.updatedAt > $1.updatedAt }
    }

    func folder(id: String) async throws -> SharedFolder? {
        try failIfForced()
        return folders.first { $0.id == id }
    }

    func add(_ folder: SharedFolder) async throws {
        try failIfForced()
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            folders[index] = folder
        } else {
            folders.append(folder)
        }
    }

    func delete(id: String) async throws {
        try failIfForced()
        folders.removeAll { $0.id == id }
    }

    // MARK: Test and preview controls

    /// Forces every call to fail with `error`. Pass `nil` to restore success.
    func forceFailure(_ error: FolderError?) {
        failure = error
    }

    private func failIfForced() throws {
        if let failure { throw failure }
    }
}