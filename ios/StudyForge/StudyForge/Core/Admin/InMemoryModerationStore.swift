//
//  InMemoryModerationStore.swift
//  StudyForge
//
//  A `ModerationStore` that keeps everything in memory, for previews and tests.
//
//  A REAL conformance rather than a stub, mirroring the other in-memory stores, so a screen driven by
//  it behaves exactly as it does against the file store.
//

import Foundation

actor InMemoryModerationStore: ModerationStore {

    private var reports: [ContentReport]

    /// When set, every call fails with it until cleared.
    private var failure: AdminError?

    init(seededWith reports: [ContentReport] = []) {
        self.reports = reports
    }

    // MARK: ModerationStore

    func reports() async throws -> [ContentReport] {
        try failIfForced()
        return reports.sorted { $0.reportedAt > $1.reportedAt }
    }

    func report(id: String) async throws -> ContentReport? {
        try failIfForced()
        return reports.first { $0.id == id }
    }

    func save(_ report: ContentReport) async throws {
        try failIfForced()
        if let index = reports.firstIndex(where: { $0.id == report.id }) {
            reports[index] = report
        } else {
            reports.append(report)
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
