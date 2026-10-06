//
//  AIAdminView.swift
//  StudyForge
//
//  K07 + K08 — `115_Admin_AIConfig_Settings_{M4}` and the trail it writes (docs/03 §K, P0/P1).
//
//  This screen is the cost-governor innovation made operational: an admin sees what the AI has spent
//  today and changes the policy that spends it, and the change takes effect on the next generation.
//

import SwiftUI

struct AIAdminView: View {

    @State private var viewModel: AIAdminViewModel

    init(
        store: any AIConfigurationStore,
        router: AIRouter,
        governor: AICostGovernor,
        actorName: String
    ) {
        _viewModel = State(initialValue: AIAdminViewModel(
            store: store,
            router: router,
            governor: governor,
            actorName: actorName
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                if let error = viewModel.error {
                    SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
                }

                policySection
                quotaSection
                costSection

                SFPrimaryButton(
                    title: viewModel.saveTitle,
                    isLoading: viewModel.isSaving,
                    isEnabled: viewModel.hasChanges,
                    action: { Task { await viewModel.save() } },
                    loadingTitle: viewModel.savingTitle
                )

                if viewModel.didSave {
                    Label(viewModel.savedTitle, systemImage: "checkmark.circle.fill")
                        .font(.sfCallout)
                        .foregroundStyle(ColorTokens.successText)
                        .accessibilityElement(children: .combine)
                }

                auditSection
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

    // MARK: Policy

    private var policySection: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            SFSegmentedField(
                label: viewModel.policyLabel,
                selection: Binding(
                    get: { viewModel.policy },
                    set: { viewModel.policy = $0 ?? viewModel.policy }
                ),
                options: AIRoutingPolicy.allCases,
                title: { $0.title }
            )

            Text(viewModel.policyHint)
                .font(.sfCaption)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Quota

    private var quotaSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Toggle(viewModel.planDefaultTitle, isOn: $viewModel.usesPlanDefaultQuota)
                .tint(ColorTokens.primary)
                .font(.sfBodyEmph)

            Text(viewModel.quotaHint)
                .font(.sfCaption)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            // The stepper is hidden while the plan default is in force, so the screen never shows two
            // numbers that disagree about the ceiling.
            if !viewModel.usesPlanDefaultQuota {
                SFSegmentedField(
                    label: viewModel.quotaLabel,
                    selection: Binding(
                        get: { viewModel.quotaOverride },
                        set: { viewModel.quotaOverride = $0 ?? viewModel.quotaOverride }
                    ),
                    options: viewModel.quotaOptions,
                    title: { viewModel.quotaValueTitle($0) }
                )
            }
        }
    }

    // MARK: Cost

    private var costSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(viewModel.costHeading)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)

            Text(viewModel.costUsedTitle(used: viewModel.usedToday, limit: viewModel.effectiveQuota))
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.textPrimary)

            // A plain bar rather than a chart: the number is the point, and the bar is the glance.
            GeometryReader { geometry in
                let limit = max(viewModel.effectiveQuota, 1)
                let fraction = min(1, Double(viewModel.usedToday) / Double(limit))
                ZStack(alignment: .leading) {
                    Capsule().fill(ColorTokens.outline)
                    Capsule()
                        .fill(fraction >= 1 ? ColorTokens.error : ColorTokens.primary)
                        .frame(width: geometry.size.width * fraction)
                }
            }
            .frame(height: Spacing.s2)

            Text(viewModel.costOnDeviceNote)
                .font(.sfCaption)
                .foregroundStyle(ColorTokens.textTertiary)
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
    }

    // MARK: Audit trail

    private var auditSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(viewModel.auditHeading)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)

            if viewModel.auditLog.isEmpty {
                Text(viewModel.auditEmptyTitle)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
            } else {
                ForEach(viewModel.auditLog) { entry in
                    auditRow(entry)
                }
            }
        }
    }

    private func auditRow(_ entry: AuditEntry) -> some View {
        HStack(alignment: .top, spacing: Spacing.s3) {
            Image(systemName: entry.action.symbolName)
                .font(.sfBody)
                .foregroundStyle(ColorTokens.primary)
                .frame(minWidth: Spacing.s6, alignment: .leading)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text("\(entry.action.title) · \(entry.actorName)")
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textPrimary)
                Text(entry.detail)
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textSecondary)
                Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textTertiary)
            }

            Spacer(minLength: Spacing.s2)
        }
        .padding(Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Previews

#Preview("K07 AI settings") {
    let governor = AICostGovernor()
    return NavigationStack {
        AIAdminView(
            store: InMemoryAIConfigurationStore(),
            router: AIRouter.standard(governor: governor),
            governor: governor,
            actorName: "Shahad Ashoor"
        )
    }
}