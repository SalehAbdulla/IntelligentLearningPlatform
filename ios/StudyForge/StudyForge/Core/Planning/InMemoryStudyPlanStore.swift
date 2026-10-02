//
//  InMemoryStudyPlanStore.swift
//  StudyForge
//
//  A `StudyPlanStore` that keeps everything in memory — previews and tests.
//
//  A REAL conformance rather than a stub, mirroring `InMemoryDeckStore`, so a screen driven by it
//  behaves exactly as it does against the file store.
//

import Foundation

actor InMemoryStudyPlanStore: StudyPlanStore {

    private var plans: [StudyPlan]

    /// When set, every call fails with it until cleared.
    private var failure: StudyPlanError?

    init(seededWith plans: [StudyPlan] = []) {
        self.plans = plans
    }

    // MARK: StudyPlanStore

    func all() async throws -> [StudyPlan] {
        try failIfForced()
        return plans.sorted { $0.updatedAt > $1.updatedAt }
    }

    func plan(id: String) async throws -> StudyPlan? {
        try failIfForced()
        return plans.first { $0.id == id }
    }

    func add(_ plan: StudyPlan) async throws {
        try failIfForced()
        if let index = plans.firstIndex(where: { $0.id == plan.id }) {
            plans[index] = plan
        } else {
            plans.append(plan)
        }
    }

    func delete(id: String) async throws {
        try failIfForced()
        plans.removeAll { $0.id == id }
    }

    // MARK: Test and preview controls

    /// Forces every call to fail with `error`. Pass `nil` to restore success.
    func forceFailure(_ error: StudyPlanError?) {
        failure = error
    }

    private func failIfForced() throws {
        if let failure { throw failure }
    }
}
