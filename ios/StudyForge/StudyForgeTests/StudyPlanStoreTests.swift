//
//  StudyPlanStoreTests.swift
//  StudyForgeTests
//
//  Tests for the study-plan models and their stores.
//

import Foundation
import Testing
@testable import StudyForge

// MARK: - Model

@Suite("Study plan model")
struct StudyPlanModelTests {

    private func plan() -> StudyPlan {
        StudyPlan(
            id: "p1",
            input: StudyPlanInput(subjects: ["Maths"], weeklyHours: 8, deadline: nil, intensity: .balanced),
            sessions: [
                StudySession(id: "s1", subject: "Maths", estimatedMinutes: 45,
                             scheduledAt: Date(timeIntervalSince1970: 1_000_000), status: .pending),
                StudySession(id: "s2", subject: "Maths", estimatedMinutes: 45,
                             scheduledAt: Date(timeIntervalSince1970: 1_000_000), status: .completed),
            ]
        )
    }

    @Test("A plan round-trips through JSON without losing its sessions or input")
    func codableRoundTrip() throws {
        let original = plan()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StudyPlan.self, from: data)

        #expect(decoded == original)
        #expect(decoded.input.intensity == .balanced)
        #expect(decoded.sessions.count == 2)
    }

    @Test("Pending sessions exclude the ones already handled")
    func pendingSessions() {
        #expect(plan().pendingSessions.map(\.id) == ["s1"])
    }
}

// MARK: - Store

@Suite("Study plan store")
struct StudyPlanStoreTests {

    private func plan(id: String, updatedAt: Date) -> StudyPlan {
        StudyPlan(
            id: id,
            input: StudyPlanInput(subjects: ["Maths"], weeklyHours: 8, intensity: .balanced),
            sessions: [],
            updatedAt: updatedAt
        )
    }

    @Test("The in-memory store returns plans most recently updated first")
    func inMemoryOrdersNewestFirst() async throws {
        let store = InMemoryStudyPlanStore(seededWith: [
            plan(id: "old", updatedAt: .now.addingTimeInterval(-3600)),
            plan(id: "new", updatedAt: .now),
        ])
        #expect(try await store.all().map(\.id) == ["new", "old"])
    }

    @Test("The in-memory store adds, looks up and deletes")
    func inMemoryCRUD() async throws {
        let store = InMemoryStudyPlanStore()
        let record = plan(id: "p1", updatedAt: .now)

        try await store.add(record)
        #expect(try await store.plan(id: "p1") == record)

        try await store.delete(id: "p1")
        #expect(try await store.plan(id: "p1") == nil)
    }

    @Test("The in-memory store surfaces a forced failure")
    func inMemoryFailureIsReported() async {
        let store = InMemoryStudyPlanStore()
        await store.forceFailure(.storageFailed)
        await #expect(throws: StudyPlanError.self) {
            try await store.all()
        }
    }

    @Test("The file store persists plans across instances")
    func fileStorePersists() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("plan-tests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        try await FileStudyPlanStore(directory: directory).add(plan(id: "p1", updatedAt: .now))
        #expect(try await FileStudyPlanStore(directory: directory).plan(id: "p1")?.id == "p1")
    }

    @Test("Study-plan store failures map to the app's single user-facing error")
    func errorMapsToAppError() {
        #expect(StudyPlanError.storageFailed.asAppError == AppError.server(reference: "study-plan-store-failed"))
    }
}
