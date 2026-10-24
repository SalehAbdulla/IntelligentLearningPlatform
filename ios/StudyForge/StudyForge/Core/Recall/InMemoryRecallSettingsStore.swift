//
//  InMemoryRecallSettingsStore.swift
//  StudyForge
//
//  A `RecallSettingsStore` that keeps everything in memory — previews and tests.
//
//  A REAL conformance rather than a stub, mirroring `InMemoryDeckStore`: a screen driven by it
//  behaves exactly as it does against the file store, and `forceFailure` reaches the failed state
//  without inventing an unwritable file.
//

import Foundation

actor InMemoryRecallSettingsStore: RecallSettingsStore {

    private var stored: RecallSettings

    /// When set, every call fails with it until cleared.
    private var failure: RecallSettingsError?

    init(seededWith settings: RecallSettings = .default) {
        self.stored = settings
    }

    // MARK: RecallSettingsStore

    func settings() async throws -> RecallSettings {
        try failIfForced()
        return stored
    }

    func save(_ settings: RecallSettings) async throws {
        try failIfForced()
        stored = settings
    }

    // MARK: Test and preview controls

    /// Forces every call to fail with `error`. Pass `nil` to restore success.
    func forceFailure(_ error: RecallSettingsError?) {
        failure = error
    }

    private func failIfForced() throws {
        if let failure { throw failure }
    }
}
