//
//  ModerationQueueView.swift
//  StudyForge
//
//  K04: `112_Admin_Moderation_Queue_{M4}` (docs/03 section K, P0) and the decision panel that makes K05
//  (`113_Admin_FlaggedReports_{M4}`) a real screen rather than a table.
//
//  WHY THE DECISION IS A SHEET THAT RE-READS
//  ----------------------------------------
//  A decision rewrites the report and writes an audit line; a detail view holding the copy it opened
//  with would keep showing "Pending" after the decision landed. It re-reads by id, exactly as the
//  account detail does, so the sheet shows what was stored.
//

import SwiftUI

struct ModerationQueueView: View {

    @State private var viewModel: ModerationQueueViewModel

    /// The report whose detail sheet is open, by id so the sheet always reads the live row.
    @State private var selectedReportId: String?

    init(store: any ModerationStore, audit: any AIConfigurationStore, actorName: String) {
        _viewModel = State(initialValue: ModerationQueueViewModel(
            store: store,
            audit: audit,
            actorName: actorName
        ))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
                    .padding(Layout.screenMargin)
            } else if viewModel.reports.isEmpty {
                emptyState
            } else if viewModel.isFilteredEmpty {
                filteredEmptyState
            } else {
                list
            }
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) { filterMenu }
        }
        .task { await viewModel.load() }
        .sheet(isPresented: isShowingDetail) {
            if let reportId = selectedReportId {
                ModerationReportDetailSheet(viewModel: viewModel, reportId: reportId) {
                    selectedReportId = nil
                }
            }
        }
    }

    private var isShowingDetail: Binding<Bool> {
        Binding(
            get: { selectedReportId != nil },
            set: { if !$0 { selectedReportId = nil } }
        )
    }

    private var filterMenu: some View {
        Menu {
            Button(viewModel.allReasonsTitle) { viewModel.reasonFilter = nil }
            ForEach(ReportReason.allCases, id: \.self) { reason in
                Button(reason.title) { viewModel.reasonFilter = reason }
            }
            Divider()
            Toggle(viewModel.showDecidedTitle, isOn: $viewModel.showsDecided)
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel(viewModel.allReasonsTitle)
    }

    @ViewBuilder
    private var list: some View {
        List {
            Section {
                ForEach(viewModel.visibleReports) { report in
                    Button { selectedReportId = report.id } label: { row(report) }
                        .buttonStyle(.plain)
                }
            } header: {
                Text(viewModel.openCountTitle())
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .textCase(nil)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func row(_ report: ContentReport) -> some View {
        HStack(alignment: .top, spacing: Spacing.s3) {
            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(report.contentTitle)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .lineLimit(1)

                Text(report.contentPreview)
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .lineLimit(2)

                Text("\(viewModel.reporterTitle(report)) · \(viewModel.ageTitle(report))")
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textTertiary)
            }

            Spacer(minLength: Spacing.s2)

            VStack(alignment: .trailing, spacing: Spacing.s1) {
                pill(viewModel.reasonTitle(report), tinted: true)
                if !report.isPending {
                    pill(viewModel.statusTitle(report), tinted: false)
                }
            }
        }
        .padding(.vertical, Spacing.s2)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }

    private func pill(_ text: String, tinted: Bool) -> some View {
        Text(text)
            .font(.sfCaption)
            .foregroundStyle(tinted ? ColorTokens.accentText : ColorTokens.onPrimaryContainer)
            .padding(.horizontal, Spacing.s2)
            .padding(.vertical, Spacing.s1)
            .background(
                tinted ? ColorTokens.accent.opacity(0.15) : ColorTokens.primaryContainer,
                in: .capsule
            )
    }

    private var emptyState: some View {
        message(title: viewModel.emptyTitle, body: viewModel.emptyBody)
    }

    private var filteredEmptyState: some View {
        message(title: viewModel.filteredEmptyTitle, body: viewModel.filteredEmptyBody)
    }

    private func message(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(title)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)
            Text(body)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Layout.screenMargin)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - K04/K05 detail and decision

/// One report's detail, with the decision panel K05 requires.
///
/// Takes the LIST's view model rather than its own, so the decision is applied to the same loaded queue
/// the list is showing, exactly as the account detail does.
struct ModerationReportDetailSheet: View {

    let viewModel: ModerationQueueViewModel
    let reportId: String
    let onClose: () -> Void

    /// The admin's reason. Held here, not in the model, so switching reports starts clean.
    @State private var reason = ""

    /// Re-read by id, so a recorded decision is reflected without reopening the sheet.
    private var report: ContentReport? { viewModel.report(id: reportId) }


    var body: some View {
        NavigationStack {
            ScrollView {
                if let report {
                    VStack(alignment: .leading, spacing: Spacing.s6) {
                        contentSection(report)
                        metaSection(report)
                        decisionSection(report)
                    }
                    .padding(Layout.screenMargin)
                    .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
                    .frame(maxWidth: .infinity)
                }
            }
            .background(ColorTokens.surface)
            .navigationTitle(viewModel.detailTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonClose.string) { onClose() }
                }
            }
        }
    }

    private func contentSection(_ report: ContentReport) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(viewModel.kindTitle(report))
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)
            Text(report.contentTitle)
                .font(.sfTitleS)
                .foregroundStyle(ColorTokens.textPrimary)
            Text(report.contentPreview)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if !report.note.isEmpty {
                Text(report.note)
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metaSection(_ report: ContentReport) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            SFDetailRow(row: DetailRow(
                id: "reporter", label: viewModel.reporterLabel, value: report.reporterName))
            SFDetailRow(row: DetailRow(
                id: "reason", label: viewModel.reasonLabel, value: viewModel.reasonTitle(report)))
            SFDetailRow(row: DetailRow(
                id: "status", label: viewModel.statusLabel, value: viewModel.statusTitle(report)))
            SFDetailRow(row: DetailRow(
                id: "age", label: viewModel.ageLabel, value: viewModel.ageTitle(report)))
            if let decision = report.decisionReason, !decision.isEmpty {
                SFDetailRow(row: DetailRow(
                    id: "decision", label: viewModel.decisionLabel, value: decision))
            }
        }
    }


    @ViewBuilder
    private func decisionSection(_ report: ContentReport) -> some View {
        if report.isPending {
            VStack(alignment: .leading, spacing: Spacing.s4) {
                Text(viewModel.decideHeading)
                    .font(.sfSubhead)
                    .foregroundStyle(ColorTokens.textSecondary)

                SFTextField(
                    label: viewModel.reasonLabel,
                    text: $reason,
                    placeholder: viewModel.reasonPlaceholder,
                    error: viewModel.reasonError,
                    autocapitalization: .sentences,
                    autocorrectionDisabled: false
                )

                ForEach(ModerationDecision.allCases) { decision in
                    decisionButton(decision, report: report)
                }
            }
        } else {
            Label(viewModel.statusTitle(report), systemImage: "checkmark.seal")
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.successText)
                .accessibilityElement(children: .combine)
        }
    }

    private func decisionButton(_ decision: ModerationDecision, report: ContentReport) -> some View {
        Button(role: decision.isDestructive ? .destructive : nil) {
            viewModel.clearReasonError()
            Task {
                let didRecord = await viewModel.decide(decision, for: report, reason: reason)
                if didRecord { onClose() }
            }
        } label: {
            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(decision.title)
                    .font(.sfBodyEmph)
                    .foregroundStyle(decision.isDestructive ? ColorTokens.error : ColorTokens.primary)
                Text(decision.body)
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.s4)
            .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
        }
        .buttonStyle(.plain)
        .accessibilityHint(decision.body)
    }
}

// MARK: - Previews

#Preview("K04 Moderation queue") {
    NavigationStack {
        ModerationQueueView(
            store: InMemoryModerationStore(seededWith: ContentReport.samples),
            audit: InMemoryAIConfigurationStore(auditLog: AuditEntry.samples),
            actorName: "Shahad Ashoor"
        )
    }
}

