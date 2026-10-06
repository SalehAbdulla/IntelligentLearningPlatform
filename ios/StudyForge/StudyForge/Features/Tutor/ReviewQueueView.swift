//
//  ReviewQueueView.swift
//  StudyForge
//
//  J06 — `104_Tutor_AI_Content_ReviewQueue_{M2}` (docs/03 §J, P0). The list of AI-drafted
//  artefacts awaiting approval, with the confidence filter and the bulk approve.
//
//  WHY THE FILTER AND THE BULK ACTION SIT TOGETHER
//  -----------------------------------------------
//  They are one control in two parts: the filter decides what "approve all" means. Presented
//  apart, a tutor could filter to the uncertain drafts, tap approve, and believe they had
//  approved only those — so the confirmation names the count, and the list is short enough to
//  read before it is confirmed.
//

import SwiftUI

struct ReviewQueueView: View {

    let container: AppContainer

    @State private var viewModel: ReviewQueueViewModel
    @State private var showingBulkConfirm = false

    init(container: AppContainer, courseId: String) {
        self.container = container
        _viewModel = State(initialValue: ReviewQueueViewModel(
            courseId: courseId,
            store: container.courses
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
            } else {
                content
            }
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .confirmationDialog(
            viewModel.bulkConfirmTitle(),
            isPresented: $showingBulkConfirm,
            titleVisibility: .visible
        ) {
            Button(viewModel.bulkTitle) {
                Task { await viewModel.approveAll() }
            }
            Button(L10n.commonCancel.string, role: .cancel) {}
        } message: {
            Text(viewModel.bulkConfirmBody)
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s5) {
                Text(viewModel.pendingCountLabel)
                    .font(.sfSubhead)
                    .foregroundStyle(ColorTokens.textSecondary)

                Toggle(viewModel.filterTitle, isOn: $viewModel.lowConfidenceOnly)
                    .font(.sfCallout)
                    .tint(ColorTokens.primary)

                if viewModel.canBulkApprove {
                    SFPrimaryButton(
                        title: viewModel.bulkTitle,
                        isLoading: viewModel.isBulkApproving,
                        action: { showingBulkConfirm = true }
                    )
                }

                if viewModel.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: Spacing.s3) {
                        ForEach(viewModel.items) { item in
                            NavigationLink {
                                ReviewDetailView(container: container, item: item)
                            } label: {
                                row(item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private func row(_ item: ReviewItem) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            HStack(spacing: Spacing.s2) {
                Label(viewModel.kindName(item), systemImage: item.kind.symbolName)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textPrimary)

                Spacer(minLength: Spacing.s2)

                if item.isLowConfidence {
                    Text(viewModel.lowConfidenceBadge)
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.warningText)
                        .padding(.horizontal, Spacing.s2)
                        .padding(.vertical, Spacing.s1)
                        .background(ColorTokens.warning.opacity(0.14), in: Capsule())
                }
            }

            Text(item.materialTitle)
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textSecondary)
                .lineLimit(1)

            Text(viewModel.confidenceLabel(item))
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s4)
        .frame(minHeight: Layout.minTouchTarget)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
        .accessibilityElement(children: .combine)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(viewModel.emptyTitle)
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.textPrimary)

            Text(viewModel.filterHidEverything
                ? L10n.tutorFilterLowConfidence.string
                : viewModel.emptyBody)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s4)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Previews

#Preview("J06 Review queue") {
    NavigationStack {
        ReviewQueueView(container: .previewing(), courseId: Course.sample.id)
    }
}
