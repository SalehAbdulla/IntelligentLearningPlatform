//
//  AdminTests.swift
//  StudyForgeTests
//
//  Tests for F12's routing policy, AI configuration, store and the K07 admin screen.
//

import Foundation
import Testing
@testable import StudyForge

// MARK: - Policy

@Suite("AI routing policy (F12)")
struct AIRoutingPolicyTests {

    private let summarizePreference = AITask.summarize.tierPreference  // [onDevice, firebaseAI, cloudFunction]

    @Test("On-device first puts the device ahead of every cloud tier")
    func onDeviceFirst() {
        let ordered = AIRoutingPolicy.onDeviceFirst.ordered(summarizePreference)
        #expect(ordered.first == .onDevice)
        #expect(ordered == [.onDevice, .firebaseAI, .cloudFunction])
    }

    @Test("Cloud first moves the device behind the cloud tiers, keeping their order")
    func cloudFirst() {
        let ordered = AIRoutingPolicy.cloudFirst.ordered(summarizePreference)
        #expect(ordered == [.firebaseAI, .cloudFunction, .onDevice])
    }

    @Test("On-device only drops every cloud tier")
    func offlineOnly() {
        let ordered = AIRoutingPolicy.offlineOnly.ordered(summarizePreference)
        #expect(ordered == [.onDevice])
    }

    @Test("A task that cannot run on-device has no candidates under on-device only")
    func offlineOnlyDropsEverythingForCloudOnlyTasks() {
        // `coachAnswer` leads with the cloud but keeps the device as a fallback, so it survives; a
        // task whose preference has NO on-device tier would not. This asserts the filter's edge.
        let ordered = AIRoutingPolicy.offlineOnly.ordered([.firebaseAI, .cloudFunction])
        #expect(ordered.isEmpty)
    }

    @Test("The policy never invents a tier the task did not ask for")
    func policyDoesNotAddTiers() {
        for policy in AIRoutingPolicy.allCases {
            let ordered = policy.ordered([.firebaseAI])
            #expect(ordered.allSatisfy { $0 == .firebaseAI })
        }
    }
}

// MARK: - Configuration

@Suite("AI configuration (F12)")
struct AIConfigurationTests {

    @Test("The default is the shipped behaviour")
    func defaults() {
        #expect(AIConfiguration.default.policy == .onDeviceFirst)
        #expect(AIConfiguration.default.dailyQuotaOverride == nil)
        #expect(AIConfiguration.default.isDefault)
    }

    @Test("An override wins, and no override falls back to the plan")
    func effectiveQuota() {
        #expect(AIConfiguration().effectiveQuota(planLimit: 20) == 20)
        #expect(AIConfiguration(policy: .cloudFirst, dailyQuotaOverride: 50).effectiveQuota(planLimit: 20) == 50)
    }

    @Test("A configuration round-trips through JSON")
    func codableRoundTrip() throws {
        let original = AIConfiguration(policy: .offlineOnly, dailyQuotaOverride: 5)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AIConfiguration.self, from: data)
        #expect(decoded == original)
    }
}

// MARK: - Store

@Suite("AI configuration store (F12)")
struct AIConfigurationStoreTests {

    @Test("An untouched store reports the shipped defaults")
    func defaultsBeforeAnySave() async throws {
        let store = InMemoryAIConfigurationStore()
        #expect(try await store.configuration() == .default)
        #expect(try await store.auditLog().isEmpty)
    }

    @Test("Saving the configuration reads back")
    func saveReadsBack() async throws {
        let store = InMemoryAIConfigurationStore()
        try await store.save(AIConfiguration(policy: .cloudFirst, dailyQuotaOverride: 10))
        #expect(try await store.configuration().policy == .cloudFirst)
        #expect(try await store.configuration().dailyQuotaOverride == 10)
    }

    @Test("The audit trail grows and reads newest first")
    func auditTrailIsAppendOnlyAndNewestFirst() async throws {
        let store = InMemoryAIConfigurationStore()
        let older = AuditEntry(
            action: .aiConfigChanged, actorName: "A", detail: "first",
            createdAt: .now.addingTimeInterval(-60)
        )
        let newer = AuditEntry(action: .aiConfigChanged, actorName: "A", detail: "second")

        try await store.record(older)
        try await store.record(newer)

        #expect(try await store.auditLog().map(\.detail) == ["second", "first"])
    }

    @Test("The in-memory store surfaces a forced failure")
    func inMemoryFailureIsReported() async {
        let store = InMemoryAIConfigurationStore()
        await store.forceFailure(.storageFailed)
        await #expect(throws: AdminError.self) {
            try await store.configuration()
        }
    }

    @Test("The file store persists the settings and the trail across instances")
    func fileStorePersists() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("admin-tests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let writer = FileAIConfigurationStore(directory: directory)
        try await writer.save(AIConfiguration(policy: .offlineOnly, dailyQuotaOverride: 5))
        try await writer.record(AuditEntry(action: .aiConfigChanged, actorName: "A", detail: "changed"))

        let reader = FileAIConfigurationStore(directory: directory)
        #expect(try await reader.configuration().policy == .offlineOnly)
        #expect(try await reader.configuration().dailyQuotaOverride == 5)
        #expect(try await reader.auditLog().count == 1)
    }

    @Test("Admin failures map to the app's single user-facing error")
    func errorMapsToAppError() {
        let expected = AppError.server(reference: "admin-store-failed")
        #expect(AdminError.storageFailed.asAppError == expected)
        #expect(AppError.from(AdminError.storageFailed) == expected)
    }
}

// MARK: - K07 screen

@Suite("Admin AI settings (F12)")
@MainActor
struct AIAdminViewModelTests {

    /// A router with both engines available, so the policy's effect is observable.
    private func router(governor: AICostGovernor) -> AIRouter {
        AIRouter(
            providers: [
                .onDevice: MockProvider(tier: .onDevice, latency: .zero),
                .firebaseAI: MockProvider(tier: .firebaseAI, latency: .zero),
            ],
            governor: governor
        )
    }

    private func model(
        store: any AIConfigurationStore = InMemoryAIConfigurationStore()
    ) -> (AIAdminViewModel, AIRouter, AICostGovernor) {
        let governor = AICostGovernor(plan: .free)
        let router = router(governor: governor)
        let viewModel = AIAdminViewModel(
            store: store,
            router: router,
            governor: governor,
            actorName: "Shahad Ashoor"
        )
        return (viewModel, router, governor)
    }

    @Test("Loading an untouched store shows the shipped defaults and no changes to save")
    func loadDefaults() async {
        let (viewModel, _, _) = model()

        await viewModel.load()

        #expect(viewModel.policy == .onDeviceFirst)
        #expect(viewModel.usesPlanDefaultQuota)
        #expect(viewModel.hasChanges == false)
        #expect(viewModel.auditLog.isEmpty)
    }

    @Test("Changing the policy offers a save")
    func changingPolicyOffersSave() async {
        let (viewModel, _, _) = model()
        await viewModel.load()

        viewModel.policy = .cloudFirst

        #expect(viewModel.hasChanges)
    }

    @Test("Saving persists the settings, applies them to the live router, and records the change")
    func saveAppliesAndRecords() async throws {
        let store = InMemoryAIConfigurationStore()
        let (viewModel, router, governor) = model(store: store)
        await viewModel.load()

        viewModel.policy = .cloudFirst
        viewModel.usesPlanDefaultQuota = false
        viewModel.quotaOverride = 10
        await viewModel.save()

        #expect(viewModel.didSave)
        #expect(viewModel.hasChanges == false, "the saved settings are now the loaded ones")

        // Persisted.
        #expect(try await store.configuration().policy == .cloudFirst)
        #expect(try await store.configuration().dailyQuotaOverride == 10)

        // Applied to the objects that actually enforce them.
        #expect(router.policy == .cloudFirst)
        #expect(governor.limitOverride == 10)
        #expect(governor.limit == 10, "the override moves the real ceiling, not just the screen")

        // And recorded.
        let trail = try await store.auditLog()
        #expect(trail.count == 1)
        #expect(trail.first?.actorName == "Shahad Ashoor")
        #expect(trail.first?.action == .aiConfigChanged)
        #expect(viewModel.auditLog.count == 1)
    }

    @Test("The plan default clears the override rather than freezing today's number")
    func planDefaultClearsTheOverride() async throws {
        let store = InMemoryAIConfigurationStore(configuration: AIConfiguration(dailyQuotaOverride: 50))
        let (viewModel, _, governor) = model(store: store)
        await viewModel.load()
        #expect(viewModel.usesPlanDefaultQuota == false)

        viewModel.usesPlanDefaultQuota = true
        await viewModel.save()

        #expect(try await store.configuration().dailyQuotaOverride == nil)
        #expect(governor.limitOverride == nil)
        #expect(governor.limit == governor.plan.dailyAIGenerationLimit)
    }

    @Test("The cost readout follows the ceiling that would apply")
    func costReadoutFollowsTheCeiling() async {
        let (viewModel, _, governor) = model()
        await viewModel.load()

        #expect(viewModel.effectiveQuota == governor.plan.dailyAIGenerationLimit)
        #expect(viewModel.usedToday == 0)

        viewModel.usesPlanDefaultQuota = false
        viewModel.quotaOverride = 5
        #expect(viewModel.effectiveQuota == 5)
    }

    @Test("A store that refuses the write is reported rather than swallowed")
    func storeFailureIsReported() async {
        let store = InMemoryAIConfigurationStore()
        let (viewModel, _, _) = model(store: store)
        await viewModel.load()
        await store.forceFailure(.storageFailed)

        viewModel.policy = .offlineOnly
        await viewModel.save()

        #expect(viewModel.error == AppError.server(reference: "admin-store-failed"))
        #expect(viewModel.didSave == false)
    }

    @Test("Every string comes from the catalogue")
    func copyIsLocalised() async {
        let (viewModel, _, _) = model()
        await viewModel.load()

        #expect(viewModel.title == L10n.adminTitle.string)
        #expect(viewModel.policyLabel == L10n.adminPolicyLabel.string)
        #expect(viewModel.saveTitle == L10n.adminSave.string)
        #expect(viewModel.quotaValueTitle(20) == L10n.adminQuotaValue.string(20))
        #expect(AIRoutingPolicy.cloudFirst.title == L10n.adminPolicyCloudFirst.string)
        #expect(AuditAction.aiConfigChanged.title == L10n.adminAuditConfigChanged.string)
    }
}

// MARK: - Directory

@Suite("Admin directory (F12)")
@MainActor
struct AdminDirectoryTests {

    private func student(id: String, lastLoginDaysAgo: Int, mastery: Int = 70) -> PlatformUser {
        PlatformUser(
            id: id,
            displayName: "Student \(id)",
            email: "\(id)@example.test",
            role: .student,
            masteryPercent: mastery,
            lastLoginAt: .now.addingTimeInterval(-Double(lastLoginDaysAgo) * 86_400)
        )
    }

    @Test("The store returns accounts most recently active first")
    func ordersByActivity() async throws {
        let store = InMemoryAdminDirectoryStore(seededWith: [
            student(id: "old", lastLoginDaysAgo: 9),
            student(id: "new", lastLoginDaysAgo: 1),
        ])
        #expect(try await store.users().map(\.id) == ["new", "old"])
    }

    @Test("The store saves and looks up an account")
    func saveAndLookUp() async throws {
        let store = InMemoryAdminDirectoryStore()
        try await store.save(student(id: "a", lastLoginDaysAgo: 1))
        #expect(try await store.user(id: "a")?.id == "a")
        #expect(try await store.user(id: "nope") == nil)
    }

    @Test("The file store persists the directory across instances")
    func fileStorePersists() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("directory-tests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        try await FileAdminDirectoryStore(directory: directory).save(student(id: "a", lastLoginDaysAgo: 1))
        #expect(try await FileAdminDirectoryStore(directory: directory).user(id: "a")?.id == "a")
    }

    @Test("Risk is a stated rule, not a hidden score")
    func riskRule() {
        // Recent and mastering.
        #expect(student(id: "a", lastLoginDaysAgo: 1, mastery: 80).isAtRisk == false)
        // Gone quiet for a fortnight.
        #expect(student(id: "b", lastLoginDaysAgo: 20, mastery: 80).isAtRisk)
        // Mastery under half.
        #expect(student(id: "c", lastLoginDaysAgo: 1, mastery: 40).isAtRisk)
        // A tutor is not "at risk": the flag is about students.
        let tutor = PlatformUser(displayName: "Dr", email: "d@example.test", role: .tutor, masteryPercent: 0)
        #expect(tutor.isAtRisk == false)
    }

    @Test("Active this week counts only recent sign-ins")
    func activeThisWeek() {
        #expect(student(id: "a", lastLoginDaysAgo: 3).isActive())
        #expect(student(id: "b", lastLoginDaysAgo: 10).isActive() == false)
    }
}

@Suite("Admin accounts screen (F12)")
@MainActor
struct AdminUsersViewModelTests {

    private func model() -> (AdminUsersViewModel, InMemoryAdminDirectoryStore, InMemoryAIConfigurationStore) {
        let store = InMemoryAdminDirectoryStore(seededWith: PlatformUser.samples)
        let audit = InMemoryAIConfigurationStore()
        let viewModel = AdminUsersViewModel(store: store, audit: audit, actorName: "Shahad Ashoor")
        return (viewModel, store, audit)
    }

    @Test("An empty directory shows the empty state")
    func emptyDirectory() async {
        let viewModel = AdminUsersViewModel(
            store: InMemoryAdminDirectoryStore(),
            audit: InMemoryAIConfigurationStore(),
            actorName: "Admin"
        )
        await viewModel.load()
        #expect(viewModel.users.isEmpty)
    }

    @Test("Search and the role filter both narrow the list, and both count as filtered-empty")
    func searchAndFilter() async {
        let (viewModel, _, _) = model()
        await viewModel.load()

        viewModel.query = "omar"
        #expect(viewModel.visibleUsers.map(\.displayName) == ["Omar Hassan"])

        viewModel.query = ""
        viewModel.roleFilter = .tutor
        #expect(viewModel.visibleUsers.allSatisfy { $0.role == .tutor })

        viewModel.query = "zzzz"
        #expect(viewModel.visibleUsers.isEmpty)
        #expect(viewModel.isFilteredEmpty, "accounts exist, the search hid them")
    }

    @Test("A role change persists and is recorded in the trail")
    func roleChangeIsAudited() async throws {
        let (viewModel, store, audit) = model()
        await viewModel.load()
        let student = try #require(viewModel.users.first { $0.role == .student })

        await viewModel.setRole(.tutor, for: student)

        #expect(try await store.user(id: student.id)?.role == .tutor)
        let trail = try await audit.auditLog()
        #expect(trail.count == 1)
        #expect(trail.first?.action == .roleChanged)
        #expect(trail.first?.actorName == "Shahad Ashoor")
    }

    @Test("Suspending flips the status and reactivating flips it back, both recorded")
    func suspensionToggles() async throws {
        let (viewModel, store, audit) = model()
        await viewModel.load()
        let student = try #require(viewModel.users.first { $0.role == .student })
        #expect(student.isSuspended == false)

        await viewModel.toggleSuspension(student)
        #expect(try await store.user(id: student.id)?.isSuspended == true)

        let suspended = try #require(viewModel.user(id: student.id))
        await viewModel.toggleSuspension(suspended)
        #expect(try await store.user(id: student.id)?.isSuspended == false)

        #expect(try await audit.auditLog().count == 2)
    }

    @Test("Every string comes from the catalogue")
    func copyIsLocalised() async {
        let (viewModel, _, _) = model()
        await viewModel.load()

        #expect(viewModel.title == L10n.adminUsersTitle.string)
        #expect(viewModel.emptyTitle == L10n.adminUsersEmptyTitle.string)
        #expect(viewModel.suspendTitle == L10n.adminSuspend.string)
        #expect(AuditAction.roleChanged.title == L10n.adminAuditRoleChanged.string)
        #expect(AccountStatus.suspended.title == L10n.adminStatusSuspended.string)
    }
}