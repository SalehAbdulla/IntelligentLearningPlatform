//
//  QuizListView.swift
//  StudyForge
//
//  F01 — `51_Quizzes_List_{M2}` (docs/03 §F, P0). Quiz history with score, source and a Retake
//  entry point.
//

import SwiftUI

struct QuizListView: View {

    @State private var viewModel: QuizListViewModel
    @State private var isCreating = false
    @State private var quizToTake: Quiz?

    private let materialStore: any MaterialStore
    private let quizStore: any QuizStore
    private let router: AIRouter

    init(
        materialStore: any MaterialStore,
        quizStore: any QuizStore,
        router: AIRouter
    ) {
        self.materialStore = materialStore
        self.quizStore = quizStore
        self.router = router
        _viewModel = State(initialValue: QuizListViewModel(store: quizStore))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
                    .padding(Layout.screenMargin)
            } else if viewModel.isEmpty {
                emptyState
            } else {
                quizList
            }
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { isCreating = true } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(L10n.quizNewQuiz.string)
            }
        }
        .sheet(isPresented: $isCreating) {
            QuizGenerateView(
                initialMaterial: nil,
                materialStore: materialStore,
                quizStore: quizStore,
                router: router
            )
        }
        .sheet(item: $quizToTake) { quiz in
            QuizTakeView(quiz: quiz, store: quizStore)
        }
        .task { await viewModel.load() }
    }

    private var quizList: some View {
        List {
            ForEach(viewModel.quizzes) { quiz in
                row(quiz)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func row(_ quiz: Quiz) -> some View {
        HStack(spacing: Spacing.s3) {
            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(quiz.title)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .lineLimit(2)

                if let attempt = quiz.latestAttempt {
                    Text(L10n.quizScore.string(attempt.correctCount, attempt.totalCount))
                        .font(.sfFootnote)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
            }

            Spacer(minLength: Spacing.s2)

            Button { quizToTake = quiz } label: {
                Text(viewModel.retakeTitle)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.primary)
                    .frame(minHeight: Layout.minTouchTarget)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(viewModel.retakeTitle)
        }
        .padding(.vertical, Spacing.s2)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task { await viewModel.delete(quiz) }
            } label: {
                Label(L10n.commonDelete.string, systemImage: "trash")
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(viewModel.emptyTitle)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)
            Text(viewModel.emptyBody)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Layout.screenMargin)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Previews

#Preview("F01 Quizzes — empty") {
    NavigationStack {
        QuizListView(
            materialStore: InMemoryMaterialStore(seededWith: Material.samples),
            quizStore: InMemoryQuizStore(),
            router: AIRouter.standard(governor: AICostGovernor())
        )
    }
}
