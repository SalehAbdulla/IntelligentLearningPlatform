//
//  InMemorySummaryStore.swift
//  StudyForge
//
//  A `SummaryStore` that keeps everything in memory — previews and tests.
//
//  A REAL conformance rather than a stub, mirroring `InMemoryMaterialStore`: a screen driven by
//  it behaves exactly as it does against the file store, and the `forceFailure` hook lets a test
//  reach the failed state without inventing an unwritable file.
//

import Foundation

actor InMemorySummaryStore: SummaryStore {

    private var summaries: [Summary]

    /// When set, every call fails with it until cleared.
    private var failure: SummaryError?

    init(seededWith summaries: [Summary] = []) {
        self.summaries = summaries
    }

    // MARK: SummaryStore

    func all() async throws -> [Summary] {
        try failIfForced()
        return summaries.sorted { $0.createdAt > $1.createdAt }
    }

    func summary(id: String) async throws -> Summary? {
        try failIfForced()
        return summaries.first { $0.id == id }
    }

    func add(_ summary: Summary) async throws {
        try failIfForced()
        if let index = summaries.firstIndex(where: { $0.id == summary.id }) {
            summaries[index] = summary
        } else {
            summaries.append(summary)
        }
    }

    func delete(id: String) async throws {
        try failIfForced()
        summaries.removeAll { $0.id == id }
    }

    // MARK: Test and preview controls

    /// Forces every call to fail with `error`. Pass `nil` to restore success.
    func forceFailure(_ error: SummaryError?) {
        failure = error
    }

    private func failIfForced() throws {
        if let failure { throw failure }
    }
}
