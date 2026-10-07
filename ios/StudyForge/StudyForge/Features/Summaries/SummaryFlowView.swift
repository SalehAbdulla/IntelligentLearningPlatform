//
//  SummaryFlowView.swift
//  StudyForge
//
//  F03's one sheet: D01 configure, D02 generating, D03 result and D07 error, drawn in place.
//  The view model explains why these are one screen rather than four.
//

import SwiftUI

// Accessibility: the generating state is one announcement rather than a progress indicator followed by
// two loose lines, the citation chip is a named button, and the key-point bullets are decorative, so the
// result reads as prose instead of a run of marks.

struct SummaryFlowView: View {

    @State private var viewModel: SummaryFlowViewModel
    @State private var showingProvenance = false

    @Environment(\.dismiss) private var dismiss

    init(
        material: Material,
        router: AIRouter,
        store: any SummaryStore,
        learningStyle: LearningStyle = .visual
    ) {
        _viewModel = State(initialValue: SummaryFlowViewModel(
            material: material,
            router: router,
            store: store,
            learningStyle: learningStyle
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s6) {
                    switch viewModel.phase {
                    case .configuring: config
                    case .generating: generating
                    case .result: result
                    case .saved: saved
                    }

                    if let error = viewModel.error {
                        SFErrorBanner(error: error, onRecover: nil)
                    }
                }
                .padding(Layout.screenMargin)
                .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(ColorTokens.surface)
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel.string) { dismiss() }
                        .disabled(viewModel.isGenerating || viewModel.isSaving)
                }
            }
            .sheet(isPresented: $showingProvenance) {
                provenanceSheet
            }
        }
    }

    // MARK: D01 — configure

    private var config: some View {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            SFSegmentedField(
                label: viewModel.lengthLabel,
                selection: $viewModel.length,
                options: SummaryLength.allCases,
                title: { viewModel.lengthTitle($0) }
            )

            SFSegmentedField(
                label: viewModel.styleLabel,
                selection: $viewModel.style,
                options: SummaryStyle.allCases,
                title: { viewModel.styleTitle($0) }
            )

            SFSegmentedField(
                label: viewModel.languageLabel,
                selection: $viewModel.language,
                options: OutputLanguage.allCases,
                title: { viewModel.languageTitle($0) }
            )

            SFTextField(
                label: viewModel.focusLabel,
                text: $viewModel.focusTopics,
                placeholder: viewModel.focusPlaceholder,
                submitLabel: .done,
                autocorrectionDisabled: false,
                onSubmit: {}
            )

            SFPrimaryButton(
                title: viewModel.generateTitle,
                isLoading: viewModel.isGenerating,
                action: { Task { await viewModel.generate() } },
                loadingTitle: viewModel.generatingTitle
            )
        }
    }

    // MARK: D02 — generating

    private var generating: some View {
        VStack(spacing: Spacing.s4) {
            ProgressView()
                .controlSize(.large)
                .tint(ColorTokens.primary)

            Text(viewModel.generatingTitle)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)

            Text(viewModel.generatingBody)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.s10)
        // One announcement, not a progress indicator with two loose lines after it.
        .accessibilityElement(children: .combine)
    }

    // MARK: D03 — result

    private var result: some View {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            metadata

            card(viewModel.tldrHeading) {
                Text(viewModel.tldr)
                    .font(.sfBody)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            card(viewModel.keyPointsHeading) {
                VStack(alignment: .leading, spacing: Spacing.s2) {
                    ForEach(Array(viewModel.keyPoints.enumerated()), id: \.offset) { _, point in
                        HStack(alignment: .top, spacing: Spacing.s2) {
                            Text("•")
                                .font(.sfBody)
                                .foregroundStyle(ColorTokens.primary)
                                .accessibilityHidden(true)
                            Text(point)
                                .font(.sfBody)
                                .foregroundStyle(ColorTokens.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            if viewModel.hasGlossary {
                card(viewModel.glossaryHeading) {
                    VStack(alignment: .leading, spacing: Spacing.s3) {
                        ForEach(Array(viewModel.glossary.enumerated()), id: \.offset) { _, entry in
                            VStack(alignment: .leading, spacing: Spacing.s1) {
                                Text(entry.term)
                                    .font(.sfBodyEmph)
                                    .foregroundStyle(ColorTokens.textPrimary)
                                Text(entry.definition)
                                    .font(.sfCallout)
                                    .foregroundStyle(ColorTokens.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }

            SFPrimaryButton(
                title: viewModel.saveTitle,
                isLoading: viewModel.isSaving,
                action: { Task { await viewModel.save() } },
                loadingTitle: viewModel.savingTitle
            )
        }
    }

    /// The engine badge, confidence band and citation chip — the honesty layer that says where
    /// the material went and where each claim came from.
    private var metadata: some View {
        SFChipFlow(spacing: Spacing.s2, lineSpacing: Spacing.s2) {
            if let engine = viewModel.engineBadge {
                chip(engine, fill: ColorTokens.accent, ink: ColorTokens.onAccent)
            }
            if let confidence = viewModel.confidenceLabel {
                chip(confidence, fill: ColorTokens.surfaceVariant, ink: ColorTokens.textPrimary)
            }
            if let citation = viewModel.citationLabel {
                Button { showingProvenance = true } label: {
                    chip(citation, fill: ColorTokens.primaryContainer, ink: ColorTokens.onPrimaryContainer)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(viewModel.sourceTitle): \(citation)")
            }
        }
    }

    // MARK: Saved

    private var saved: some View {
        VStack(spacing: Spacing.s4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.sfDisplayL)
                .foregroundStyle(ColorTokens.successText)

            Text(viewModel.savedTitle)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)

            Text(viewModel.savedBody)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)

            SFPrimaryButton(title: L10n.commonDone.string) { dismiss() }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.s10)
    }

    // MARK: D04-lite — provenance

    private var provenanceSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s4) {
                    Text(viewModel.material.title)
                        .font(.sfTitleM)
                        .foregroundStyle(ColorTokens.textPrimary)

                    if let citation = viewModel.citationLabel {
                        chip(citation, fill: ColorTokens.primaryContainer, ink: ColorTokens.onPrimaryContainer)
                    }
                    if let confidence = viewModel.confidenceLabel {
                        chip(confidence, fill: ColorTokens.surfaceVariant, ink: ColorTokens.textPrimary)
                    }
                }
                .padding(Layout.screenMargin)
                .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(ColorTokens.surface)
            .navigationTitle(viewModel.sourceTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.commonDone.string) { showingProvenance = false }
                }
            }
        }
    }

    // MARK: Presentation helpers

    private func card(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(title)
                .font(.sfTitleS)
                .foregroundStyle(ColorTokens.textPrimary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s4)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
    }

    private func chip(_ text: String, fill: Color, ink: Color) -> some View {
        Text(text)
            .font(.sfCaption)
            .lineLimit(1)
            .foregroundStyle(ink)
            .padding(.horizontal, Spacing.s3)
            .padding(.vertical, Spacing.s2)
            .background(fill, in: .capsule)
    }
}

// MARK: - Previews

#Preview("F03 Summary flow") {
    SummaryFlowView(
        material: Material.samples[0],
        router: AIRouter.standard(governor: AICostGovernor()),
        store: InMemorySummaryStore()
    )
}
