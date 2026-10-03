//
//  InMemoryAIConfigurationStore.swift
//  StudyForge
//
//  An `AIConfigurationStore` that keeps everything in memory — previews and tests.
//
//  A REAL conformance rather than a stub, mirroring the other in-memory stores, so a screen driven by
//  it behaves exactly as it does against the file store.
//

import Foundation

actor InMemoryAIConfigurationStore: AIConfigurationStore {

    private var stored: AIConfiguration
    private var entries: [AuditEntry]

    /// When set, every call fails with it until cleared.
    private var failure: AdminError?

    init(configuration: AIConfiguration = .default, auditLog: [AuditEntry] = []) {
        self.stored = configuration
        self.entries = auditLog
    }

    // MARK: AIConfigurationStore

    func configuration() async throws -> AIConfiguration {
        try failIfForced()
        return stored
    }

    func save(_ configuration: AIConfiguration) async throws {
        try failIfForced()
        stored = configuration
    }

    func auditLog() async throws -> [AuditEntry] {
        try failIfForced()
        return entries.sorted { $0.createdAt > $1.createdAt }
    }

    func record(_ entry: AuditEntry) async throws {
        try failIfForced()
        entries.append(entry)
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