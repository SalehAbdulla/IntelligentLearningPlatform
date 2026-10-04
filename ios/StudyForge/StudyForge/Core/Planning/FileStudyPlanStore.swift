//
//  FileStudyPlanStore.swift
//  StudyForge
//
//  The on-device store for study plans: one JSON file in Application Support.
//
//  WHY A FILE AND NOT FIRESTORE
//  ----------------------------
//  Plans must be viewable offline, and they are derived from the student's own profile answers.
//  The file is the local half; Firestore's `studyPlans/{id}` collection is what a future sync swaps
//  in behind this protocol.
//

import Foundation

actor FileStudyPlanStore: StudyPlanStore {

    private let fileURL: URL

    /// The plans once read. `nil` until then, so the file is touched at most once per launch.
    private var cache: [StudyPlan]?

    /// - Parameter directory: where to keep the file. Injected so a test can point at a temporary
    ///   directory rather than the real Application Support folder.
    init(directory: URL? = nil) {
        let base = directory ?? Self.defaultDirectory
        self.fileURL = base.appendingPathComponent("study-plans.json")
    }

    // MARK: StudyPlanStore

    func all() async throws -> [StudyPlan] {
        try load().sorted { $0.updatedAt > $1.updatedAt }
    }

    func plan(id: String) async throws -> StudyPlan? {
        try load().first { $0.id == id }
    }

    func add(_ plan: StudyPlan) async throws {
        var plans = try load()
        if let index = plans.firstIndex(where: { $0.id == plan.id }) {
            plans[index] = plan
        } else {
            plans.append(plan)
        }
        try persist(plans)
    }

    func delete(id: String) async throws {
        var plans = try load()
        plans.removeAll { $0.id == id }
        try persist(plans)
    }

    // MARK: Storage

    private func load() throws -> [StudyPlan] {
        if let cache { return cache }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            cache = []
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([StudyPlan].self, from: data)
            cache = decoded
            return decoded
        } catch {
            throw StudyPlanError.storageFailed
        }
    }

    private func persist(_ plans: [StudyPlan]) throws {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(plans)
            try data.write(to: fileURL, options: .atomic)
            cache = plans
        } catch {
            throw StudyPlanError.storageFailed
        }
    }

    /// Application Support, with a fallback.
    private static var defaultDirectory: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first
            .map { $0.appendingPathComponent("StudyForge", isDirectory: true) }
            ?? FileManager.default.temporaryDirectory
    }
}
