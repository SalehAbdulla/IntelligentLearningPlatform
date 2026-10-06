//
//  InMemoryGroupStore.swift
//  StudyForge
//
//  A `GroupStore` that keeps everything in memory — previews and tests.
//
//  A REAL conformance rather than a stub, mirroring `InMemoryFolderStore`, so a screen driven by it
//  behaves exactly as it does against the file store.
//

import Foundation

actor InMemoryGroupStore: GroupStore {

    private var groups: [StudyGroup]

    /// When set, every call fails with it until cleared.
    private var failure: GroupError?

    init(seededWith groups: [StudyGroup] = []) {
        self.groups = groups
    }

    // MARK: GroupStore

    func all() async throws -> [StudyGroup] {
        try failIfForced()
        return groups.sorted { $0.updatedAt > $1.updatedAt }
    }

    func group(id: String) async throws -> StudyGroup? {
        try failIfForced()
        return groups.first { $0.id == id }
    }

    func add(_ group: StudyGroup) async throws {
        try failIfForced()
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index] = group
        } else {
            groups.append(group)
        }
    }

    func delete(id: String) async throws {
        try failIfForced()
        groups.removeAll { $0.id == id }
    }

    func group(withInviteCode code: String) async throws -> StudyGroup? {
        try failIfForced()
        let needle = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return groups.first { $0.inviteCode.uppercased() == needle }
    }

    // MARK: Test and preview controls

    /// Forces every call to fail with `error`. Pass `nil` to restore success.
    func forceFailure(_ error: GroupError?) {
        failure = error
    }

    private func failIfForced() throws {
        if let failure { throw failure }
    }
}