//
//  ReviewDetailView.swift
//  StudyForge
//
//  J07 — `105_Tutor_AI_Content_EditApprove_{M2}` (docs/03 §J, P0). The editable AI draft, the
//  source it was grounded in, the confidence badge, and the three decisions.
//
//  WHY THE DRAFT AND THE SOURCE ARE STACKED, NOT SIDE BY SIDE
//  ---------------------------------------------------------
//  The design draws J07 as a split view. At AX3+ — and at the text sizes a marker demonstrating
//  accessibility will use — two columns of prose become two columns of two-word lines, and the
//  whole point of the screen (CHECK the draft against its source) is defeated. Stacking keeps
//  the draft and the evidence legible at every size; the split is a layout choice that had to
//  give way to the requirement it exists to serve.
//

import SwiftUI

struct ReviewDetailView: View {

    let container: AppContainer

    @State private var viewModel: ReviewDetailViewModel

    init(container: AppContainer, item: ReviewItem) {
        self.container = container
        _viewModel = State(initialValue: ReviewDetailViewModel(
            item: item,
            store: container.courses
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                if let error = viewModel.error {
                    SFErrorBanner(error: error)
                }

                header
                draftSection
                sourceSection

                if !viewModel.isPending {
                    outcomeSection
                }
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if viewModel.isPending { decisions }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            HStack(spacing: Spacing.s2) {
                Label(viewModel.kindName(), systemImage: viewModel.item.kind.symbolName)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textPrimary)

                Spacer(minLength: Spacing.s2)

                Text(viewModel.confidenceLabel())
                    .font(.sfCaption)
                    .foregroundStyle(
                        viewModel.isLowConfidence ? ColorTokens.warning : ColorTokens.textSecondary
                    )
            }

            Text(viewModel.materialTitle)
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textSecondary)

            if let banner = viewModel.bannerText {
                Text(banner)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Draft (editable while pending)

    private var draftSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(viewModel.draftHeading)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)

            if viewModel.isPending {
                TextEditor(text: $viewModel.editedDraft)
                    .font(.sfBody)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .frame(minHeight: 180)
                    .padding(Spacing.s2)
                    .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
                    .accessibilityLabel(viewModel.draftHeading)
            } else {
                Text(viewModel.publishedText ?? viewModel.draft)
                    .font(.sfBody)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Source

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(viewModel.sourceHeading)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)

            Text(viewModel.sourceSnippet)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s4)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
    }

    // MARK: Outcome

    private var outcomeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(viewModel.publishedTextHeading)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)

            Text(viewModel.publishedText ?? L10n.tutorRejectedBanner.string)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Decisions (J07)

    private var decisions: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            if let message = viewModel.validationMessage {
                Text(message)
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.error)
                    .fixedSize(horizontal: false, vertical: true)
            }

            SFTextField(
                label: viewModel.rejectReasonLabel,
                text: $viewModel.rejectReason,
                placeholder: viewModel.rejectReasonPlaceholder,
                autocorrectionDisabled: false
            )

            SFPrimaryButton(
                title: viewModel.editAndApproveTitle,
                isLoading: viewModel.isDeciding,
                isEnabled: viewModel.canDecide && viewModel.hasEdited,
                action: { Task { await viewModel.editAndApprove() } }
            )

            HStack(spacing: Spacing.s3) {
                Button(viewModel.approveTitle) {
                    Task { await viewModel.approve() }
                }
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.primary)
                .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)

                Button(viewModel.rejectTitle) {
                    Task { await viewModel.reject() }
                }
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.error)
                .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .trailing)
            }
            .disabled(!viewModel.canDecide)
        }
        .padding(Layout.screenMargin)
        .background(.bar)
    }
}

// MARK: - Previews

#Preview("J07 Review draft") {
    NavigationStack {
        ReviewDetailView(
            container: .previewing(),
            item: ReviewItem(
                courseId: Course.sample.id,
                materialId: "m1",
                materialTitle: "Lecture 4 — Normalisation",
                kind: .summary,
                draft: "Normalisation removes redundancy by organising columns and tables.",
                sourceSnippet: "Normalisation is the process of organising data to minimise redundancy.",
                confidence: 0.64
            )
        )
    }
}
