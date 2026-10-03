//
//  AdminDashboardView.swift
//  StudyForge
//
//  K01 — `109_Home_Dashboard_Admin_{M4}` (docs/03 §K, P0). The platform's numbers, an alert strip, and
//  the way into the admin surfaces.
//

import SwiftUI

struct AdminDashboardView: View {

    @State private var viewModel: AdminDashboardViewModel

    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
        _viewModel = State(initialValue: AdminDashboardViewModel(
            directory: container.adminDirectory,
            materials: container.materials,
            summaries: container.summaries,
            decks: container.decks,
            quizzes: container.quizzes,
            groups: container.groups,
            governor: container.ai.governor
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                if let error = viewModel.error {
                    SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
                }

                if viewModel.needsAttention {
                    attentionBanner
                }

                kpiGrid
                contentSummary
                manageLinks
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }

    // MARK: Alert

    private var attentionBanner: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            if viewModel.isQuotaNearlySpent {
                Label(
                    viewModel.costUsedTitle(used: viewModel.usedToday, limit: viewModel.aiLimit),
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.warning)
            }
            if viewModel.atRiskCount > 0 {
                Label(
                    "\(viewModel.kpiAtRisk): \(viewModel.atRiskCount)",
                    systemImage: "person.badge.clock"
                )
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s4)
        .background(ColorTokens.warning.opacity(0.15), in: .rect(cornerRadius: Radius.l))
        .accessibilityElement(children: .combine)
    }

    // MARK: KPIs

    private var kpiGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.s3) {
            kpi(viewModel.kpiUsers, "\(viewModel.accountCount)", "person.3")
            kpi(viewModel.kpiActive, "\(viewModel.activeThisWeek)", "clock.arrow.circlepath")
            kpi(viewModel.kpiAtRisk, "\(viewModel.atRiskCount)", "exclamationmark.triangle")
            kpi(viewModel.kpiAIToday, "\(viewModel.usedToday) / \(viewModel.aiLimit)", "bolt")
        }
    }

    private func kpi(_ label: String, _ value: String, _ symbol: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Image(systemName: symbol)
                .font(.sfBody)
                .foregroundStyle(ColorTokens.primary)
                .accessibilityHidden(true)
            Text(value)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)
            Text(label)
                .font(.sfCaption)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s4)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
        .accessibilityElement(children: .combine)
    }

    // MARK: Content

    private var contentSummary: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            SFDetailRow(row: DetailRow(id: "materials", label: L10n.libraryTitle.string, value: "\(viewModel.materialCount)"))
            SFDetailRow(row: DetailRow(id: "summaries", label: L10n.summaryTitle.string, value: "\(viewModel.summaryCount)"))
            SFDetailRow(row: DetailRow(id: "decks", label: L10n.deckTitle.string, value: "\(viewModel.deckCount)"))
            SFDetailRow(row: DetailRow(id: "quizzes", label: L10n.quizTitle.string, value: "\(viewModel.quizCount)"))
            SFDetailRow(row: DetailRow(id: "groups", label: L10n.groupTitle.string, value: "\(viewModel.groupCount)"))
        }
    }

    // MARK: Manage

    private var manageLinks: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(viewModel.manageHeading)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)

            NavigationLink {
                AdminUsersView(
                    store: container.adminDirectory,
                    audit: container.aiConfigurations,
                    actorName: container.session?.displayName ?? ""
                )
            } label: {
                manageRow(viewModel.usersTitle, "person.3")
            }

            NavigationLink {
                AIAdminView(
                    store: container.aiConfigurations,
                    router: container.ai,
                    governor: container.ai.governor,
                    actorName: container.session?.displayName ?? ""
                )
            } label: {
                manageRow(viewModel.aiTitle, "slider.horizontal.3")
            }
        }
    }

    private func manageRow(_ title: String, _ symbol: String) -> some View {
        HStack(spacing: Spacing.s3) {
            Image(systemName: symbol)
                .font(.sfBody)
                .foregroundStyle(ColorTokens.primary)
                .frame(minWidth: Spacing.s6, alignment: .leading)
            Text(title)
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.textPrimary)
            Spacer(minLength: Spacing.s2)
            Image(systemName: "chevron.right")
                .font(.sfCaption)
                .foregroundStyle(ColorTokens.textTertiary)
        }
        .frame(minHeight: Layout.minTouchTarget)
        .contentShape(.rect)
    }
}

// MARK: - Previews

#Preview("K01 Admin dashboard") {
    NavigationStack {
        AdminDashboardView(container: .previewing())
    }
}