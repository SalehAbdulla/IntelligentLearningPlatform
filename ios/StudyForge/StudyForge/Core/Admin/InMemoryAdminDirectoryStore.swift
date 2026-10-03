//
//  InMemoryAdminDirectoryStore.swift
//  StudyForge
//
//  An `AdminDirectoryStore` that keeps everything in memory — previews and tests.
//
//  A REAL conformance rather than a stub, mirroring the other in-memory stores, so a screen driven by
//  it behaves exactly as it does against the file store.
//

import Foundation

actor InMemoryAdminDirectoryStore: AdminDirectoryStore {

    private var accounts: [PlatformUser]

    /// When set, every call fails with it until cleared.
    private var failure: AdminError?

    init(seededWith accounts: [PlatformUser] = []) {
        self.accounts = accounts
    }

    // MARK: AdminDirectoryStore

    func users() async throws -> [PlatformUser] {
        try failIfForced()
        return accounts.sorted { $0.lastLoginAt > $1.lastLoginAt }
    }

    func user(id: String) async throws -> PlatformUser? {
        try failIfForced()
        return accounts.first { $0.id == id }
    }

    func save(_ user: PlatformUser) async throws {
        try failIfForced()
        if let index = accounts.firstIndex(where: { $0.id == user.id }) {
            accounts[index] = user
        } else {
            accounts.append(user)
        }
    }

    // MARK: Test and preview controls

    /// Forces every call to fail with `error`. Pass `nil` to restore success.
    func forceFailure(_ error: AdminError?) {
        failure = error
    }

    private func failIfForced() throws {
        if let failure { throw failure }
    }
}