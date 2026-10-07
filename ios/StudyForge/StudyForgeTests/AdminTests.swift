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

// MARK: - Moderation store

@Suite("Moderation store (F12)")
struct ModerationStoreTests {

    private func sample() -> ContentReport {
        ContentReport(
            id: "r_test",
            kind: .comment,
            contentTitle: "A reply",
            contentPreview: "preview",
            reporterName: "Reporter",
            reason: .harassment
        )
    }

    @Test("An untouched store has an empty queue")
    func emptyByDefault() async throws {
        let store = InMemoryModerationStore()
        #expect(try await store.reports().isEmpty)
    }

    @Test("A saved report reads back, and saving again replaces it rather than duplicating it")
    func saveReadsBack() async throws {
        let store = InMemoryModerationStore()
        var report = sample()
        try await store.save(report)
        #expect(try await store.report(id: report.id)?.status == .pending)

        report.status = .removed
        try await store.save(report)
        #expect(try await store.reports().count == 1)
        #expect(try await store.report(id: report.id)?.status == .removed)
    }

    @Test("Reports come back newest first")
    func newestFirst() async throws {
        let older = ContentReport(
            kind: .summary, contentTitle: "Old", contentPreview: "",
            reporterName: "A", reason: .spam,
            reportedAt: .now.addingTimeInterval(-86_400))
        let newer = ContentReport(
            kind: .summary, contentTitle: "New", contentPreview: "",
            reporterName: "B", reason: .spam,
            reportedAt: .now)
        let store = InMemoryModerationStore(seededWith: [older, newer])
        #expect(try await store.reports().map(\.contentTitle) == ["New", "Old"])
    }

    @Test("A forced failure surfaces as a storage error, and clearing it restores success")
    func forcedFailure() async throws {
        let store = InMemoryModerationStore(seededWith: [sample()])
        await store.forceFailure(.storageFailed)
        do {
            _ = try await store.reports()
            Issue.record("expected a storage error")
        } catch {
            #expect(error as? AdminError == .storageFailed)
        }
        await store.forceFailure(nil)
        #expect(try await store.reports().count == 1)
    }
}

// MARK: - Moderation decision

@Suite("Moderation decision (F12)")
struct ModerationDecisionTests {

    @Test("Each decision maps to the status and the audit action it produces")
    func mapping() {
        #expect(ModerationDecision.keep.resultingStatus == .approved)
        #expect(ModerationDecision.remove.resultingStatus == .removed)
        #expect(ModerationDecision.escalate.resultingStatus == .escalated)

        #expect(ModerationDecision.keep.auditAction == .moderationApproved)
        #expect(ModerationDecision.remove.auditAction == .moderationRemoved)
        #expect(ModerationDecision.escalate.auditAction == .moderationEscalated)
    }

    @Test("Only removal is destructive")
    func destructive() {
        #expect(ModerationDecision.remove.isDestructive)
        #expect(ModerationDecision.keep.isDestructive == false)
        #expect(ModerationDecision.escalate.isDestructive == false)
    }
}


// MARK: - Moderation queue screen

@Suite("Moderation queue screen (F12)")
@MainActor
struct ModerationQueueViewModelTests {

    private func model() -> (ModerationQueueViewModel, InMemoryModerationStore, InMemoryAIConfigurationStore) {
        let store = InMemoryModerationStore(seededWith: ContentReport.samples)
        let audit = InMemoryAIConfigurationStore()
        let viewModel = ModerationQueueViewModel(store: store, audit: audit, actorName: "Shahad Ashoor")
        return (viewModel, store, audit)
    }

    @Test("Only pending reports are in the queue by default")
    func pendingByDefault() async {
        let (viewModel, _, _) = model()
        await viewModel.load()
        let allPending = viewModel.visibleReports.allSatisfy { $0.isPending }
        #expect(allPending)
        #expect(viewModel.openCount == 2, "two of the three samples are pending")
    }

    @Test("Showing decided reports reveals the rest")
    func showDecided() async {
        let (viewModel, _, _) = model()
        await viewModel.load()
        viewModel.showsDecided = true
        #expect(viewModel.visibleReports.count == ContentReport.samples.count)
    }

    @Test("Removing a report takes the content down and writes an audit line")
    func removeIsAudited() async throws {
        let (viewModel, store, audit) = model()
        await viewModel.load()
        let report = try #require(viewModel.visibleReports.first)

        let didRecord = await viewModel.decide(.remove, for: report, reason: "Removed for harassment")

        #expect(didRecord)
        #expect(try await store.report(id: report.id)?.status == .removed)
        let trail = try await audit.auditLog()
        #expect(trail.count == 1)
        #expect(trail.first?.action == .moderationRemoved)
        #expect(trail.first?.actorName == "Shahad Ashoor")
        #expect(trail.first?.detail.contains("Removed for harassment") == true)
    }

    @Test("Keeping a report closes it without removing the content")
    func keepIsAudited() async throws {
        let (viewModel, store, audit) = model()
        await viewModel.load()
        let report = try #require(viewModel.visibleReports.first)

        #expect(await viewModel.decide(.keep, for: report, reason: "Not a breach"))
        #expect(try await store.report(id: report.id)?.status == .approved)
        #expect(try await audit.auditLog().first?.action == .moderationApproved)
    }

    @Test("A decision with no reason is refused and nothing is written")
    func reasonIsRequired() async throws {
        let (viewModel, store, audit) = model()
        await viewModel.load()
        let report = try #require(viewModel.visibleReports.first)

        let didRecord = await viewModel.decide(.escalate, for: report, reason: "   ")

        #expect(didRecord == false)
        #expect(viewModel.reasonError != nil)
        #expect(try await store.report(id: report.id)?.status == .pending, "the report is untouched")
        #expect(try await audit.auditLog().isEmpty)
    }

    @Test("Every string comes from the catalogue")
    func copyIsLocalised() async {
        let (viewModel, _, _) = model()
        await viewModel.load()
        #expect(viewModel.title == L10n.adminModerationTitle.string)
        #expect(viewModel.reasonLabel == L10n.adminModerationReasonLabel.string)
        #expect(ModerationDecision.remove.title == L10n.adminModerationRemove.string)
        #expect(ReportReason.spam.title == L10n.adminReportReasonSpam.string)
        #expect(ReportStatus.removed.title == L10n.adminReportStatusRemoved.string)
    }
}


// MARK: - Audit log screen

@Suite("Audit log screen (F12)")
@MainActor
struct AuditLogViewModelTests {

    private func seededEntries() -> [AuditEntry] {
        [
            AuditEntry(id: "e1", action: .roleChanged, actorName: "Shahad Ashoor",
                       detail: "Omar Hassan: Student -> Tutor", createdAt: .now),
            AuditEntry(id: "e2", action: .aiConfigChanged, actorName: "Shahad Ashoor",
                       detail: "Daily limit 20 -> 50", createdAt: .now.addingTimeInterval(-60)),
            AuditEntry(id: "e3", action: .accountSuspended, actorName: "Saleh Abdulla",
                       detail: "Sara Ali: Suspended", createdAt: .now.addingTimeInterval(-120)),
        ]
    }

    private func model() -> AuditLogViewModel {
        AuditLogViewModel(audit: InMemoryAIConfigurationStore(auditLog: seededEntries()))
    }

    @Test("An empty trail loads to the empty state")
    func emptyTrail() async {
        let viewModel = AuditLogViewModel(audit: InMemoryAIConfigurationStore())
        await viewModel.load()
        #expect(viewModel.entries.isEmpty)
        #expect(viewModel.visibleEntries.isEmpty)
        #expect(viewModel.isFilteredEmpty == false, "an empty trail is not a filtered-empty trail")
    }

    @Test("Filtering by actor narrows the trail to that actor")
    func filterByActor() async {
        let viewModel = model()
        await viewModel.load()
        viewModel.actorFilter = "Saleh Abdulla"
        #expect(viewModel.visibleEntries.count == 1)
        let onlySaleh = viewModel.visibleEntries.allSatisfy { $0.actorName == "Saleh Abdulla" }
        #expect(onlySaleh)

        viewModel.actorFilter = nil
        #expect(viewModel.visibleEntries.count == 3)
    }

    @Test("Filtering by action narrows the trail to that action")
    func filterByAction() async {
        let viewModel = model()
        await viewModel.load()
        viewModel.actionFilter = .roleChanged
        #expect(viewModel.visibleEntries.count == 1)
        #expect(viewModel.visibleEntries.first?.action == .roleChanged)
    }

    @Test("Search matches the actor, the action title and the detail text")
    func search() async {
        let viewModel = model()
        await viewModel.load()

        viewModel.query = "sara"
        #expect(viewModel.visibleEntries.count == 1, "matches the detail text")

        viewModel.query = "suspended"
        #expect(viewModel.visibleEntries.count == 1, "matches the action title")

        viewModel.query = "zzzz"
        #expect(viewModel.visibleEntries.isEmpty)
        #expect(viewModel.isFilteredEmpty)
    }

    @Test("The offered filters come from the data, not a fixed list")
    func filtersComeFromData() async {
        let viewModel = model()
        await viewModel.load()
        #expect(viewModel.actors == ["Saleh Abdulla", "Shahad Ashoor"])
        #expect(viewModel.actions == [.aiConfigChanged, .roleChanged, .accountSuspended])
    }

    @Test("The export is a CSV header plus one line per visible entry")
    func export() async {
        let viewModel = model()
        await viewModel.load()
        viewModel.actionFilter = .roleChanged

        let lines = viewModel.exportText.split(separator: "\n")
        #expect(String(lines.first ?? "") == "Actor,Action,Detail,Timestamp")
        #expect(lines.count == 2, "the header plus the one visible entry")
        #expect(viewModel.exportText.contains("Shahad Ashoor"))
        #expect(viewModel.exportText.contains("Omar Hassan: Student -> Tutor"))
    }

    @Test("Every string comes from the catalogue")
    func copyIsLocalised() async {
        let viewModel = model()
        await viewModel.load()
        #expect(viewModel.title == L10n.adminAuditLogTitle.string)
        #expect(viewModel.allActorsTitle == L10n.adminAuditLogAllActors.string)
        #expect(viewModel.exportFileName == L10n.adminAuditLogExportFileName.string)
        #expect(viewModel.exportFileName.hasSuffix(".csv"))
    }
}


// MARK: - Taxonomy store

@Suite("Taxonomy store (F12)")
struct TaxonomyStoreTests {

    @Test("An untouched store is empty")
    func emptyByDefault() async throws {
        let store = InMemoryTaxonomyStore()
        #expect(try await store.terms().isEmpty)
    }

    @Test("Save, read back, and replace rather than duplicate")
    func saveReadsBack() async throws {
        let store = InMemoryTaxonomyStore()
        var term = TaxonomyTerm(name: "Biology", kind: .subject)
        try await store.save(term)
        #expect(try await store.terms().count == 1)

        term.usageCount = 9
        try await store.save(term)
        #expect(try await store.terms().count == 1)
        #expect(try await store.terms().first?.usageCount == 9)
    }

    @Test("Remove drops the term")
    func remove() async throws {
        let store = InMemoryTaxonomyStore(seededWith: TaxonomyTerm.samples)
        let target = TaxonomyTerm.samples[0]
        try await store.remove(id: target.id)
        let remaining = try await store.terms()
        #expect(remaining.contains { $0.id == target.id } == false)
        #expect(remaining.count == TaxonomyTerm.samples.count - 1)
    }

    @Test("Terms come back ordered by kind, then sort index")
    func ordering() async throws {
        let store = InMemoryTaxonomyStore(seededWith: TaxonomyTerm.samples)
        let kinds = try await store.terms().map(\.kind)
        #expect(kinds.first == .subject)
        #expect(kinds.last == .tag)
    }

    @Test("A forced failure surfaces as a storage error, and clearing restores success")
    func forcedFailure() async throws {
        let store = InMemoryTaxonomyStore(seededWith: TaxonomyTerm.samples)
        await store.forceFailure(.storageFailed)
        do {
            _ = try await store.terms()
            Issue.record("expected a storage error")
        } catch {
            #expect(error as? AdminError == .storageFailed)
        }
        await store.forceFailure(nil)
        #expect(try await store.terms().isEmpty == false)
    }
}

// MARK: - Taxonomy screen

@Suite("Taxonomy screen (F12)")
@MainActor
struct TaxonomyManageViewModelTests {

    private func model() -> (TaxonomyManageViewModel, InMemoryTaxonomyStore, InMemoryAIConfigurationStore) {
        let store = InMemoryTaxonomyStore(seededWith: TaxonomyTerm.samples)
        let audit = InMemoryAIConfigurationStore()
        let viewModel = TaxonomyManageViewModel(store: store, audit: audit, actorName: "Shahad Ashoor")
        return (viewModel, store, audit)
    }

    @Test("The default vocabulary is subjects, and adding one records it")
    func addRecords() async throws {
        let (viewModel, _, audit) = model()
        await viewModel.load()
        #expect(viewModel.kind == .subject)

        viewModel.newName = "Chemistry"
        #expect(await viewModel.add())

        #expect(viewModel.visibleTerms.contains { $0.name == "Chemistry" })
        #expect(viewModel.newName.isEmpty, "the field clears on success")
        let trail = try await audit.auditLog()
        #expect(trail.count == 1)
        #expect(trail.first?.action == .taxonomyChanged)
    }

    @Test("An empty or duplicate name is refused, and nothing is written")
    func refusesBadName() async throws {
        let (viewModel, _, audit) = model()
        await viewModel.load()

        viewModel.newName = "   "
        #expect(await viewModel.add() == false)
        #expect(viewModel.formError != nil)

        viewModel.newName = "biology"
        #expect(await viewModel.add() == false, "case-insensitive duplicate of an existing subject")
        #expect(try await audit.auditLog().isEmpty)
    }

    @Test("Rename changes the name and records it")
    func renameRecords() async throws {
        let (viewModel, store, audit) = model()
        await viewModel.load()
        let term = try #require(viewModel.visibleTerms.first)

        #expect(await viewModel.rename(term, to: "Life Sciences"))
        #expect(try await store.terms().contains { $0.id == term.id && $0.name == "Life Sciences" })
        #expect(try await audit.auditLog().first?.action == .taxonomyChanged)
    }

    @Test("Merge folds the counts into the target and removes the duplicate")
    func mergeAddsCounts() async throws {
        let (viewModel, store, _) = model()
        await viewModel.load()
        let bio = try #require(viewModel.visibleTerms.first { $0.name == "Bio" })
        let biology = try #require(viewModel.visibleTerms.first { $0.name == "Biology" })

        await viewModel.merge(bio, into: biology)

        let merged = try await store.terms()
        #expect(merged.contains { $0.id == bio.id } == false)
        #expect(merged.first { $0.id == biology.id }?.usageCount == biology.usageCount + bio.usageCount)
    }
}


// MARK: - Taxonomy screen, editing

@Suite("Taxonomy screen, editing (F12)")
@MainActor
struct TaxonomyEditingTests {

    private func model() -> (TaxonomyManageViewModel, InMemoryTaxonomyStore, InMemoryAIConfigurationStore) {
        let store = InMemoryTaxonomyStore(seededWith: TaxonomyTerm.samples)
        let audit = InMemoryAIConfigurationStore()
        let viewModel = TaxonomyManageViewModel(store: store, audit: audit, actorName: "Shahad Ashoor")
        return (viewModel, store, audit)
    }

    @Test("Delete removes the term and records it")
    func deleteRecords() async throws {
        let (viewModel, store, audit) = model()
        await viewModel.load()
        let term = try #require(viewModel.visibleTerms.first)

        await viewModel.delete(term)

        #expect(try await store.terms().contains { $0.id == term.id } == false)
        #expect(try await audit.auditLog().first?.action == .taxonomyChanged)
    }

    @Test("Reorder persists the new order")
    func reorder() async throws {
        let (viewModel, store, _) = model()
        await viewModel.load()
        var ordered = viewModel.visibleTerms
        ordered.swapAt(0, 2)

        await viewModel.persistOrder(ordered)

        let subjects = try await store.terms().filter { $0.kind == .subject }
        #expect(subjects.map(\.name) == ["Mathematics", "Bio", "Biology"])
    }

    @Test("Switching kind shows the other vocabulary")
    func switchingKind() async {
        let (viewModel, _, _) = model()
        await viewModel.load()
        viewModel.kind = .tag
        let allTags = viewModel.visibleTerms.allSatisfy { $0.kind == .tag }
        #expect(allTags)
        #expect(viewModel.visibleTerms.count == 3, "three sample tags")
    }

    @Test("Every string comes from the catalogue")
    func copyIsLocalised() async {
        let (viewModel, _, _) = model()
        await viewModel.load()
        #expect(viewModel.title == L10n.adminTaxonomyTitle.string)
        #expect(viewModel.addButton == L10n.adminTaxonomyAdd.string)
        #expect(TaxonomyKind.tag.title == L10n.adminTaxonomyKindTag.string)
        #expect(AuditAction.taxonomyChanged.title == L10n.adminAuditTaxonomyChanged.string)
    }
}


// MARK: - Broadcast store

@Suite("Broadcast store (F12)")
struct BroadcastStoreTests {

    @Test("An untouched store has no announcements")
    func emptyByDefault() async throws {
        let store = InMemoryBroadcastStore()
        #expect(try await store.broadcasts().isEmpty)
    }

    @Test("Save reads back, and replaces rather than duplicates")
    func saveReadsBack() async throws {
        let store = InMemoryBroadcastStore()
        let broadcast = Broadcast(segment: .everyone, title: "Hi", message: "Body", isSent: true)
        try await store.save(broadcast)
        try await store.save(broadcast)
        #expect(try await store.broadcasts().count == 1)
    }

    @Test("Announcements come back newest first")
    func newestFirst() async throws {
        let older = Broadcast(segment: .everyone, title: "Old", message: "a", createdAt: .now.addingTimeInterval(-600))
        let newer = Broadcast(segment: .everyone, title: "New", message: "b", createdAt: .now)
        let store = InMemoryBroadcastStore(seededWith: [older, newer])
        #expect(try await store.broadcasts().map(\.title) == ["New", "Old"])
    }

    @Test("A forced failure surfaces as a storage error, and clearing restores success")
    func forcedFailure() async throws {
        let store = InMemoryBroadcastStore(seededWith: [Broadcast(segment: .everyone, title: "Hi", message: "b")])
        await store.forceFailure(.storageFailed)
        do {
            _ = try await store.broadcasts()
            Issue.record("expected a storage error")
        } catch {
            #expect(error as? AdminError == .storageFailed)
        }
        await store.forceFailure(nil)
        #expect(try await store.broadcasts().isEmpty == false)
    }
}

// MARK: - Broadcast composer

@Suite("Broadcast composer (F12)")
@MainActor
struct BroadcastComposerViewModelTests {

    private func model() -> (BroadcastComposerViewModel, InMemoryBroadcastStore, InMemoryAIConfigurationStore) {
        let store = InMemoryBroadcastStore()
        let audit = InMemoryAIConfigurationStore()
        let directory = InMemoryAdminDirectoryStore(seededWith: PlatformUser.samples)
        let viewModel = BroadcastComposerViewModel(
            store: store,
            audit: audit,
            directory: directory,
            actorName: "Shahad Ashoor"
        )
        return (viewModel, store, audit)
    }

    @Test("The audience size is derived from the roster")
    func audienceSize() async {
        let (viewModel, _, _) = model()
        await viewModel.load()

        viewModel.segment = .everyone
        #expect(viewModel.audienceSize == PlatformUser.samples.count)

        viewModel.segment = .tutors
        #expect(viewModel.audienceSize == 1)

        viewModel.segment = .students
        #expect(viewModel.audienceSize == 2, "two sample students")

        viewModel.segment = .atRiskStudents
        #expect(viewModel.audienceSize == 1, "one sample student is at risk")
    }

    @Test("Sending records the announcement and the audit line, and clears the form")
    func sendRecords() async throws {
        let (viewModel, store, audit) = model()
        await viewModel.load()
        viewModel.segment = .students
        viewModel.title = "Revision clinic"
        viewModel.message = "Thursday at 4pm."

        #expect(await viewModel.send())

        let saved = try await store.broadcasts()
        #expect(saved.count == 1)
        #expect(saved.first?.isSent == true)
        #expect(saved.first?.recipientCount == 2)
        #expect(viewModel.title.isEmpty)
        #expect(viewModel.sentConfirmation == "Revision clinic")
        #expect(try await audit.auditLog().first?.action == .broadcastSent)
    }

    @Test("A scheduled announcement is not marked sent yet")
    func scheduled() async throws {
        let (viewModel, store, _) = model()
        await viewModel.load()
        viewModel.title = "Later"
        viewModel.message = "Body"
        viewModel.isScheduling = true
        viewModel.scheduledAt = .now.addingTimeInterval(86_400)

        #expect(await viewModel.send())

        let saved = try await store.broadcasts()
        #expect(saved.first?.isSent == false)
        #expect(saved.first?.isScheduled == true)
    }

    @Test("An empty title, body or audience is refused and nothing is written")
    func refusesEmpty() async throws {
        let (viewModel, store, audit) = model()
        await viewModel.load()
        viewModel.title = ""
        viewModel.message = ""

        #expect(await viewModel.send() == false)
        #expect(viewModel.formError != nil)
        #expect(try await store.broadcasts().isEmpty)
        #expect(try await audit.auditLog().isEmpty)
    }

    @Test("Every string comes from the catalogue")
    func copyIsLocalised() async {
        let (viewModel, _, _) = model()
        await viewModel.load()
        #expect(viewModel.navTitle == L10n.adminBroadcastTitle.string)
        #expect(viewModel.sendButton == L10n.adminBroadcastSend.string)
        #expect(AudienceSegment.tutors.title == L10n.adminBroadcastAudienceTutors.string)
        #expect(AuditAction.broadcastSent.title == L10n.adminAuditBroadcastSent.string)
    }
}

}