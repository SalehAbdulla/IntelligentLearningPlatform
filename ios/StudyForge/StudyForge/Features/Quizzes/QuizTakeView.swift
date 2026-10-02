//
//  QuizTakeView.swift
//  StudyForge
//
//  F04–F09 — take a quiz: answer with immediate feedback, then a scorecard with per-topic bars and
//  an answer review.
//

import SwiftUI

struct QuizTakeView: View {

    @State private var viewModel: QuizTakeViewModel
    @Environment(\.dismiss) private var dismiss

    init(quiz: Quiz, store: any QuizStore) {
        _viewModel = State(initialValue: QuizTakeViewModel(quiz: quiz, store: store))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.phase {
                case .question: question
                case .feedback: feedback
                case .scorecard: scorecard
                }
            }
            .background(ColorTokens.surface)
            .navigationTitle(viewModel.takeTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonClose.string) { dismiss() }
                }
            }
        }
    }

    // MARK: Question

    private var question: some View {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            ProgressView(value: Double(viewModel.currentIndex), total: Double(viewModel.quiz.questions.count))
                .tint(ColorTokens.primary)

            Text(viewModel.progress)
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textSecondary)

            if let current = viewModel.currentQuestion {
                Text(current.stem)
                    .font(.sfTitleM)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: Spacing.s2) {
                    ForEach(Array(current.options.enumerated()), id: \.offset) { index, option in
                        optionButton(index: index, text: option, color: neutralOptionColor)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(Layout.screenMargin)
        .frame(maxWidth: Layout.maxContentWidth)
        .frame(maxWidth: .infinity)
    }

    // MARK: Feedback

    private var feedback: some View {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            if let current = viewModel.currentQuestion {
                banner(isCorrect: viewModel.lastResponseIsCorrect == true)

                Text(current.explanation)
                    .font(.sfBody)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.s4)
                    .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))

                VStack(spacing: Spacing.s2) {
                    ForEach(Array(current.options.enumerated()), id: \.offset) { index, option in
                        optionButton(index: index, text: option, color: optionColor(for: index, in: current))
                    }
                }

                HStack(spacing: Spacing.s2) {
                    Image(systemName: "quote.opening")
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.primary)
                    Text(viewModel.citationLabel(for: current))
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.onPrimaryContainer)
                        .padding(.horizontal, Spacing.s2)
                        .padding(.vertical, Spacing.s1)
                        .background(ColorTokens.primaryContainer, in: .capsule)
                }
            }

            Spacer(minLength: 0)

            SFPrimaryButton(title: L10n.commonNext.string) {
                Task { await viewModel.next() }
            }
        }
        .padding(Layout.screenMargin)
        .frame(maxWidth: Layout.maxContentWidth)
        .frame(maxWidth: .infinity)
    }

    // MARK: Option rendering

    private func optionButton(index: Int, text: String, color: Color) -> some View {
        Button {
            if viewModel.phase == .question { viewModel.select(index) }
        } label: {
            Text(text)
                .font(.sfBody)
                .foregroundStyle(ColorTokens.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.s3)
                .background(color, in: .rect(cornerRadius: Radius.m))
                .overlay {
                    RoundedRectangle(cornerRadius: Radius.m)
                        .strokeBorder(ColorTokens.outline, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private var neutralOptionColor: Color { ColorTokens.surfaceVariant }

    private func optionColor(for index: Int, in question: QuizQuestion) -> Color {
        if index == question.correctOptionIndex {
            return ColorTokens.success.opacity(0.15)
        }
        if index == viewModel.selectedOption {
            return ColorTokens.error.opacity(0.12)
        }
        return ColorTokens.surfaceVariant
    }

    private func banner(isCorrect: Bool) -> some View {
        HStack(spacing: Spacing.s2) {
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.sfTitleS)
            Text(isCorrect ? viewModel.correctTitle : viewModel.incorrectTitle)
                .font(.sfBodyEmph)
        }
        .foregroundStyle(isCorrect ? ColorTokens.successText : ColorTokens.error)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s4)
        .background(
            (isCorrect ? ColorTokens.success : ColorTokens.error).opacity(0.10),
            in: .rect(cornerRadius: Radius.m)
        )
    }

    // MARK: Scorecard

    private var scorecard: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                VStack(spacing: Spacing.s1) {
                    Text("\(viewModel.scorePercent)%")
                        .font(.sfDisplayL)
                        .foregroundStyle(ColorTokens.primary)
                    Text(viewModel.scoreText)
                        .font(.sfTitleS)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.s6)
                .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))

                if !viewModel.topicScores.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.s3) {
                        Text(viewModel.topicHeading)
                            .font(.sfTitleS)
                            .foregroundStyle(ColorTokens.textPrimary)

                        ForEach(viewModel.topicScores, id: \.topic) { score in
                            VStack(alignment: .leading, spacing: Spacing.s1) {
                                HStack {
                                    Text(score.topic)
                                        .font(.sfCallout)
                                        .foregroundStyle(ColorTokens.textPrimary)
                                    Spacer(minLength: Spacing.s2)
                                    Text("\(score.correct) / \(score.total)")
                                        .font(.sfFootnote)
                                        .foregroundStyle(ColorTokens.textSecondary)
                                }
                                ProgressView(value: score.fraction)
                                    .tint(ColorTokens.primary)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.s3) {
                    Text(viewModel.reviewAnswersTitle)
                        .font(.sfTitleS)
                        .foregroundStyle(ColorTokens.textPrimary)

                    ForEach(viewModel.quiz.questions) { question in
                        reviewRow(question)
                    }
                }

                SFPrimaryButton(title: L10n.commonDone.string) { dismiss() }
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private func reviewRow(_ question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(question.stem)
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if let response = viewModel.response(for: question),
               let index = response.selectedOptionIndex,
               question.options.indices.contains(index) {
                answerLine(label: viewModel.yourAnswerTitle,
                           text: question.options[index],
                           isCorrect: response.isCorrect)
            }

            answerLine(label: viewModel.correctAnswerTitle,
                       text: question.options[question.correctOptionIndex],
                       isCorrect: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s3)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
    }

    private func answerLine(label: String, text: String, isCorrect: Bool) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text(label)
                .font(.sfCaption)
                .foregroundStyle(ColorTokens.textSecondary)
            Text(text)
                .font(.sfCallout)
                .foregroundStyle(isCorrect ? ColorTokens.successText : ColorTokens.error)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Previews

#Preview("F04 Take quiz") {
    QuizTakeView(
        quiz: Quiz(
            title: "Normalisation",
            questionType: .multipleChoice,
            questions: [
                QuizQuestion(
                    stem: "What is 3NF?",
                    options: ["No transitive dependencies", "Atomic values", "No partial dependencies", "No duplicates"],
                    correctOptionIndex: 0,
                    explanation: "3NF removes transitive dependencies.",
                    topic: "normalisation",
                    provenance: AIProvenance(materialId: "m", pageNumbers: [1], confidence: .high)
                ),
                QuizQuestion(
                    stem: "What is 1NF?",
                    options: ["Atomic values", "No transitive dependencies", "No partial dependencies", "No duplicates"],
                    correctOptionIndex: 0,
                    explanation: "1NF requires atomic values.",
                    topic: "normalisation",
                    provenance: AIProvenance(materialId: "m", pageNumbers: [1], confidence: .high)
                ),
            ]
        ),
        store: InMemoryQuizStore()
    )
}
