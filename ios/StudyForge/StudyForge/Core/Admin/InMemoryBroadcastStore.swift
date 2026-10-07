//
//  InMemoryBroadcastStore.swift
//  StudyForge
//
//  A `BroadcastStore` that keeps everything in memory, for previews and tests.
//

import Foundation

actor InMemoryBroadcastStore: BroadcastStore {

    private var stored: [Broadcast]

    /// When set, every call fails with it until cleared.
    private var failure: AdminError?

    init(seededWith broadcasts: [Broadcast] = []) {
        self.stored = broadcasts
    }

    func broadcasts() async throws -> [Broadcast] {
        try failIfForced()
        return stored.sorted { $0.createdAt > $1.createdAt }
    }

    func save(_ broadcast: Broadcast) async throws {
        try failIfForced()
        if let index = stored.firstIndex(where: { $0.id == broadcast.id }) {
            stored[index] = broadcast
        } else {
            stored.append(broadcast)
        }
    }

    // MARK: Test and preview controls

    func forceFailure(_ error: AdminError?) {
        failure = error
    }

    private func failIfForced() throws {
        if let failure { throw failure }
    }
}
