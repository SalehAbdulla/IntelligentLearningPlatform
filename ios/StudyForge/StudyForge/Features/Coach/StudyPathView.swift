//
//  StudyPathView.swift
//  StudyForge
//
//  H05 — `77_Coach_StudyPath_Recommended_{M3}` (docs/03 §H, P0). Ordered step cards, each with an
//  estimate, over one primary action.
//

import SwiftUI

struct StudyPathView: View {

    let container: AppContainer

    @State private var viewModel: StudyPathViewModel

    init(container: AppContainer) {
        self.container = container
        _viewModel = State(initialValue: StudyPathViewModel(
            uid: container.session?.id ?? "",
            planner: container.coachPlanner,
            progress: ProgressDashboardViewModel(
                materials: container.materials,
                decks: container.decks,
                quizzes: container.quizzes,
                studyPlans: container.studyPlans,
                profile: container.profile
            )
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s5) {
                if let error = viewModel.error {
                    SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
                }

                Text(viewModel.subtitle)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if viewModel.isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                } else if viewModel.isEmpty {
                    Text(viewModel.emptyTitle)
                        .font(.sfCallout)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.s4)
                        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
                } else {
                    Text(viewModel.totalLabel)
                        .font(.sfSubhead)
                        .foregroundStyle(ColorTokens.textSecondary)

                    ForEach(viewModel.steps) { step in
                        stepCard(step)
                    }

                    if viewModel.addedToPlan {
                        Label(viewModel.addedTitle, systemImage: "checkmark.circle.fill")
                            .font(.sfBodyEmph)
                            .foregroundStyle(ColorTokens.primary)
                    } else {
                        SFPrimaryButton(title: viewModel.addAllTitle) {
                            Task { await viewModel.addAllToPlan() }
                        }
                    }
                }
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

    private func stepCard(_ step: StudyStep) -> some View {
        HStack(alignment: .top, spacing: Spacing.s3) {
            Image(systemName: step.activity.symbolName)
                .font(.sfTitleS)
                .foregroundStyle(ColorTokens.primary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(viewModel.stepTitle(step))
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(viewModel.minutesLabel(step))
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s4)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Previews

#Preview("H05 Study path") {
    NavigationStack {
        StudyPathView(container: .previewing())
    }
}
