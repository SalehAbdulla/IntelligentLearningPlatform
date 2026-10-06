//
//  QuizGenerateView.swift
//  StudyForge
//
//  F05's generation sheet — F02's config, F03's generating, and the "review your questions" step,
//  drawn in place. The view model explains why the source is optional.
//

import SwiftUI

struct QuizGenerateView: View {

    @State private var viewModel: QuizGenerateViewModel
    @Environment(\.dismiss) private var dismiss

    init(
        initialMaterial: Material?,
        materialStore: any MaterialStore,
        quizStore: any QuizStore,
        router: AIRouter,
        learningStyle: LearningStyle = .visual
    ) {
        _viewModel = State(initialValue: QuizGenerateViewModel(
            initialMaterial: initialMaterial,
            materialStore: materialStore,
            quizStore: quizStore,
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
                label: viewModel.typeLabel,
                selection: $viewModel.questionType,
                options: QuizQuestionType.allCases,
                title: { viewModel.typeTitle($0) }
            )

            SFSegmentedField(
                label: viewModel.countLabel,
                selection: $viewModel.count,
                options: [5, 10, 15, 20],
                title: { "\($0)" }
            )

            // E02's timer toggle and minutes. The minutes control appears only when the toggle is
            // on, so the config stays short for the common untimed case.
            VStack(alignment: .leading, spacing: Spacing.s3) {
                Toggle(viewModel.timerToggleTitle, isOn: $viewModel.timerEnabled)
                    .tint(ColorTokens.primary)

                if viewModel.timerEnabled {
                    SFSegmentedField(
                        label: viewModel.timerLabel,
                        selection: $viewModel.timerMinutes,
                        options: [5, 10, 15, 20],
                        title: { viewModel.minutesTitle($0) }
                    )
                }
            }

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
                ForEach(Array(viewModel.questions.enumerated()), id: \.offset) { _, question in
                    VStack(alignment: .leading, spacing: Spacing.s1) {
                        Text(question.stem)
                            .font(.sfBodyEmph)
                            .foregroundStyle(ColorTokens.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(question.topic)
                            .font(.sfCaption)
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.s3)
                    .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
                }
            }

            SFTextField(
                label: viewModel.nameLabel,
                text: $viewModel.quizTitle,
                placeholder: viewModel.namePlaceholder,
                submitLabel: .done,
                autocorrectionDisabled: false,
                onSubmit: {}
            )

            SFPrimaryButton(
                title: viewModel.saveTitle,
                isLoading: viewModel.isSaving,
                action: { Task { await viewModel.saveQuiz() } },
                loadingTitle: viewModel.savingTitle
            )
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
}

// MARK: - Previews

#Preview("F02 Generate quiz from material") {
    QuizGenerateView(
        initialMaterial: Material.samples[0],
        materialStore: InMemoryMaterialStore(seededWith: Material.samples),
        quizStore: InMemoryQuizStore(),
        router: AIRouter.standard(governor: AICostGovernor())
    )
}

#Preview("F02 Generate quiz — choose source") {
    QuizGenerateView(
        initialMaterial: nil,
        materialStore: InMemoryMaterialStore(seededWith: Material.samples),
        quizStore: InMemoryQuizStore(),
        router: AIRouter.standard(governor: AICostGovernor())
    )
}
