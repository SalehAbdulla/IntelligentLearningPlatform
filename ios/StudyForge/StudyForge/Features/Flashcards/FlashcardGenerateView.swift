//
//  FlashcardGenerateView.swift
//  StudyForge
//
//  F04's generation sheet — E02's config, E03's generating, the "review your cards" step, and the
//  saved state, drawn in place. The view model explains why the source is optional.
//

import SwiftUI

// Accessibility: the generating state and each preview card are single elements, and the source
// rows hide their decorative icons, so a VoiceOver pass reads the screen as statements, not fragments.

struct FlashcardGenerateView: View {

    @State private var viewModel: FlashcardGenerateViewModel
    @Environment(\.dismiss) private var dismiss

    init(
        initialMaterial: Material?,
        materialStore: any MaterialStore,
        deckStore: any DeckStore,
        router: AIRouter,
        learningStyle: LearningStyle = .visual
    ) {
        _viewModel = State(initialValue: FlashcardGenerateViewModel(
            initialMaterial: initialMaterial,
            materialStore: materialStore,
            deckStore: deckStore,
            router: router,
            learningStyle: learningStyle
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s6) {
                    switch viewModel.phase {
                    case .choosingSource: sourcePicker
                    case .configuring: config
                    case .generating: generating
                    case .review: review
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
            .task { await viewModel.loadMaterials() }
        }
    }

    // MARK: Choosing source

    private var sourcePicker: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(viewModel.sourcePrompt)
                .font(.sfTitleS)
                .foregroundStyle(ColorTokens.textPrimary)

            ForEach(viewModel.materials) { material in
                Button { viewModel.choose(material) } label: {
                    HStack(spacing: Spacing.s3) {
                        Image(systemName: material.source.symbolName)
                            .font(.sfBody)
                            .foregroundStyle(ColorTokens.primary)
                            .frame(minWidth: Spacing.s6, alignment: .leading)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: Spacing.s1) {
                            Text(material.title)
                                .font(.sfBodyEmph)
                                .foregroundStyle(ColorTokens.textPrimary)
                                .lineLimit(2)
                            Text(material.source.title)
                                .font(.sfFootnote)
                                .foregroundStyle(ColorTokens.textSecondary)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(Spacing.s3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Configure

    private var config: some View {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            if let material = viewModel.selectedMaterial {
                Text(material.title)
                    .font(.sfSubhead)
                    .foregroundStyle(ColorTokens.textSecondary)
            }

            SFSegmentedField(
                label: viewModel.countLabel,
                selection: $viewModel.count,
                options: [10, 20, 30, 50],
                title: { "\($0)" }
            )

            SFSegmentedField(
                label: viewModel.difficultyLabel,
                selection: $viewModel.difficulty,
                options: FlashcardDifficulty.allCases,
                title: { viewModel.difficultyTitle($0) }
            )

            SFSegmentedField(
                label: viewModel.cardTypeLabel,
                selection: $viewModel.cardType,
                options: CardType.allCases,
                title: { $0.title }
            )

            SFPrimaryButton(
                title: viewModel.generateTitle,
                isLoading: viewModel.isGenerating,
                action: { Task { await viewModel.generate() } },
                loadingTitle: viewModel.generatingTitle
            )
        }
    }

    // MARK: Generating

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
        // The spinner and both lines are one announcement while the router works.
        .accessibilityElement(children: .combine)
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.s10)
    }

    // MARK: Review before saving

    private var review: some View {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            Text(viewModel.reviewHeading)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.s2) {
                ForEach(Array(viewModel.cards.enumerated()), id: \.offset) { _, card in
                    VStack(alignment: .leading, spacing: Spacing.s1) {
                        Text(card.front)
                            .font(.sfBodyEmph)
                            .foregroundStyle(ColorTokens.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(card.back)
                            .font(.sfCallout)
                            .foregroundStyle(ColorTokens.textSecondary)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.s3)
                    .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
                    .accessibilityElement(children: .combine)
                }
            }

            SFTextField(
                label: viewModel.deckNameLabel,
                text: $viewModel.deckTitle,
                placeholder: viewModel.deckNamePlaceholder,
                submitLabel: .done,
                autocorrectionDisabled: false,
                onSubmit: {}
            )

            SFPrimaryButton(
                title: viewModel.saveDeckTitle,
                isLoading: viewModel.isSaving,
                action: { Task { await viewModel.saveDeck() } },
                loadingTitle: viewModel.savingDeckTitle
            )
        }
    }

    // MARK: Saved

    private var saved: some View {
        VStack(spacing: Spacing.s4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.sfDisplayL)
                .foregroundStyle(ColorTokens.successText)
                .accessibilityHidden(true)

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
}

// MARK: - Previews

#Preview("E02 Generate from material") {
    FlashcardGenerateView(
        initialMaterial: Material.samples[0],
        materialStore: InMemoryMaterialStore(seededWith: Material.samples),
        deckStore: InMemoryDeckStore(),
        router: AIRouter.standard(governor: AICostGovernor())
    )
}

#Preview("E02 Generate — choose source") {
    FlashcardGenerateView(
        initialMaterial: nil,
        materialStore: InMemoryMaterialStore(seededWith: Material.samples),
        deckStore: InMemoryDeckStore(),
        router: AIRouter.standard(governor: AICostGovernor())
    )
}
