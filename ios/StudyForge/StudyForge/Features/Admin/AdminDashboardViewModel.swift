//
//  AdminDashboardViewModel.swift
//  StudyForge
//
//  Presentation logic for K01 (`109_Home_Dashboard_Admin_{M4}`) — the platform's numbers at a glance.
//
//  WHY THE NUMBERS ARE READ FROM THE REAL STORES
//  ---------------------------------------------
//  A dashboard of invented figures is worse than no dashboard, so every count here comes from a store
//  the app actually writes: accounts from the directory, content from the material/summary/deck/quiz
//  stores, groups from the group store, and the AI figures from the governor the router spends
//  against. On a fresh install they are all zero — which is the honest state of a fresh platform, and
//  the screen says so rather than dressing it up.
//

import Foundation

@MainActor
@Observable
final class AdminDashboardViewModel {

    private(set) var isLoading = false
    private(set) var error: AppError?

    private(set) var accounts: [PlatformUser] = []
    private(set) var materialCount = 0
    private(set) var summaryCount = 0
    private(set) var deckCount = 0
    private(set) var quizCount = 0
    private(set) var groupCount = 0

    private let directory: any AdminDirectoryStore
    private let materials: any MaterialStore
    private let summaries: any SummaryStore
    private let decks: any DeckStore
    private let quizzes: any QuizStore
    private let groups: any GroupStore
    private let governor: AICostGovernor

    init(
        directory: any AdminDirectoryStore,
        materials: any MaterialStore,
        summaries: any SummaryStore,
        decks: any DeckStore,
        quizzes: any QuizStore,
        groups: any GroupStore,
        governor: AICostGovernor
    ) {
        self.directory = directory
        self.materials = materials
        self.summaries = summaries
        self.decks = decks
        self.quizzes = quizzes
        self.groups = groups
        self.governor = governor
    }

    // MARK: Numbers

    var accountCount: Int { accounts.count }
    var activeThisWeek: Int { accounts.filter { $0.isActive() }.count }
    var atRiskCount: Int { accounts.filter(\.isAtRisk).count }

    /// The governor's own counter and ceiling, read live rather than copied.
    var usedToday: Int { governor.usedToday }
    var aiLimit: Int { governor.limit }

    /// Whether the AI allowance is nearly spent — K01's alert banner.
    var isQuotaNearlySpent: Bool {
        aiLimit > 0 && Double(usedToday) / Double(aiLimit) >= 0.8
    }

    /// Whether anything needs the admin's attention.
    var needsAttention: Bool { atRiskCount > 0 || isQuotaNearlySpent }

    // MARK: Copy

    var title: String { L10n.adminDashboardTitle.string }
    var manageHeading: String { L10n.adminManageHeading.string }
    var kpiUsers: String { L10n.adminKpiUsers.string }
    var kpiActive: String { L10n.adminKpiActive.string }
    var kpiAtRisk: String { L10n.adminKpiAtRisk.string }
    var kpiAIToday: String { L10n.adminKpiAIToday.string }
    var usersTitle: String { L10n.adminUsersTitle.string }
    var aiTitle: String { L10n.adminTitle.string }
    var moderationTitle: String { L10n.adminModerationTitle.string }
    var auditLogTitle: String { L10n.adminAuditLogTitle.string }
    var taxonomyTitle: String { L10n.adminTaxonomyTitle.string }

    func costUsedTitle(used: Int, limit: Int) -> String { L10n.adminCostUsed.string(used, limit) }

    // MARK: Loading

    func load() async {
        isLoading = true
        defer { isLoading = false }
        error = nil

        do {
            accounts = try await directory.users()
            materialCount = try await materials.all().count
            summaryCount = try await summaries.all().count
            deckCount = try await decks.all().count
            quizCount = try await quizzes.all().count
            groupCount = try await groups.all().count
        } catch {
            self.error = AppError.from(error)
        }
    }
}