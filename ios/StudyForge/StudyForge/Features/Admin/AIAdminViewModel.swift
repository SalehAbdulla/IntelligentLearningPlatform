//
//  AIAdminViewModel.swift
//  StudyForge
//
//  Presentation logic for K07 (`115_Admin_AIConfig_Settings_{M4}`) and the audit trail K08 feeds.
//
//  WHY SAVING APPLIES THE CHANGE IMMEDIATELY
//  -----------------------------------------
//  The settings are persisted AND pushed straight into the live router and governor, so the next
//  generation on this device obeys the policy the admin just chose. A screen that only wrote a file
//  would look identical and do nothing until relaunch, which is the kind of gap that makes an
//  operator distrust the whole panel.
//
//  WHY IT READS THE GOVERNOR'S LIVE NUMBERS
//  ----------------------------------------
//  "Cost today" is not a stored field — it is the governor's own counter and ceiling, read through
//  the object the router actually spends against. A copy would be a second source of truth for the
//  one number this screen exists to show.
//

import Foundation

@MainActor
@Observable
final class AIAdminViewModel {

    // MARK: Bound state

    var policy: AIRoutingPolicy = .onDeviceFirst

    /// Whether to follow the plan's own ceiling rather than an admin number.
    var usesPlanDefaultQuota = true

    /// The admin's ceiling, used only when `usesPlanDefaultQuota` is off.
    var quotaOverride = 20

    // MARK: Derived state

    private(set) var isLoading = false
    private(set) var isSaving = false
    private(set) var didSave = false
    private(set) var error: AppError?
    private(set) var auditLog: [AuditEntry] = []

    private let store: any AIConfigurationStore
    private let router: AIRouter
    private let governor: AICostGovernor

    /// The signed-in admin's name, so the trail is attributable.
    let actorName: String

    init(
        store: any AIConfigurationStore,
        router: AIRouter,
        governor: AICostGovernor,
        actorName: String
    ) {
        self.store = store
        self.router = router
        self.governor = governor
        self.actorName = actorName
    }

    // MARK: Live numbers

    /// Cloud generations spent today, read from the governor the router spends against.
    var usedToday: Int { governor.usedToday }

    /// The plan's own ceiling, before any override.
    var planLimit: Int { governor.plan.dailyAIGenerationLimit }

    /// The ceiling that would apply if Save were pressed now.
    var effectiveQuota: Int { usesPlanDefaultQuota ? planLimit : quotaOverride }

    var quotaOptions: [Int] { [5, 10, 20, 50, 100] }

    /// Whether the edited settings differ from what is stored — Save is offered only when they do.
    var hasChanges: Bool {
        let stored = currentConfiguration
        return stored != loadedConfiguration
    }

    private var loadedConfiguration: AIConfiguration = .default
    private var currentConfiguration: AIConfiguration {
        AIConfiguration(
            policy: policy,
            dailyQuotaOverride: usesPlanDefaultQuota ? nil : quotaOverride
        )
    }

    // MARK: Copy

    var title: String { L10n.adminTitle.string }
    var policyLabel: String { L10n.adminPolicyLabel.string }
    var policyHint: String { L10n.adminPolicyHint.string }
    var quotaLabel: String { L10n.adminQuotaLabel.string }
    var quotaHint: String { L10n.adminQuotaHint.string }
    var planDefaultTitle: String { L10n.adminQuotaUsePlanDefault.string }
    var costHeading: String { L10n.adminCostHeading.string }
    var costOnDeviceNote: String { L10n.adminCostOnDeviceNote.string }
    var saveTitle: String { L10n.adminSave.string }
    var savingTitle: String { L10n.adminSaving.string }
    var savedTitle: String { L10n.adminSavedTitle.string }
    var auditHeading: String { L10n.adminAuditHeading.string }
    var auditEmptyTitle: String { L10n.adminAuditEmpty.string }

    func quotaValueTitle(_ value: Int) -> String { L10n.adminQuotaValue.string(value) }
    func costUsedTitle(used: Int, limit: Int) -> String { L10n.adminCostUsed.string(used, limit) }

    // MARK: Actions

    func load() async {
        isLoading = true
        defer { isLoading = false }
        error = nil

        do {
            let configuration = try await store.configuration()
            loadedConfiguration = configuration
            policy = configuration.policy
            usesPlanDefaultQuota = configuration.dailyQuotaOverride == nil
            quotaOverride = configuration.dailyQuotaOverride ?? 20
            auditLog = try await store.auditLog()
        } catch {
            self.error = AppError.from(error)
        }
    }

    /// Saves the settings, applies them to the live AI layer, and records the change.
    func save() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        error = nil

        let configuration = currentConfiguration

        do {
            try await store.save(configuration)
            apply(configuration)
            try await store.record(
                AuditEntry(action: .aiConfigChanged, actorName: actorName, detail: detail(for: configuration))
            )
            loadedConfiguration = configuration
            auditLog = try await store.auditLog()
            didSave = true
        } catch {
            self.error = AppError.from(error)
        }
    }

    /// Pushes the stored settings into the running router and governor.
    private func apply(_ configuration: AIConfiguration) {
        router.policy = configuration.policy
        governor.limitOverride = configuration.dailyQuotaOverride
    }

    /// The audit line, in a sentence an auditor can read.
    private func detail(for configuration: AIConfiguration) -> String {
        let quota = configuration.dailyQuotaOverride.map { quotaValueTitle($0) } ?? planDefaultTitle
        return "\(configuration.policy.title) · \(quota)"
    }
}