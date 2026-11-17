import SwiftUI

struct QuizAnswerReviewView: View {

    let result: QuizResult

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                SummaryBackdrop()
                ScrollView {
                    LazyVStack(spacing: Spacing.s3) {
                        ForEach(Array(result.questions.enumerated()), id: \.element.id) { index, question in
                            card(number: index + 1, question: question)
                        }
                    }
                    .padding(.horizontal, Layout.screenMargin + Spacing.s3)
                    .padding(.vertical, Spacing.s4)
                    .frame(maxWidth: Layout.maxContentWidth)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle(QuizCopy.reviewTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(QuizCopy.done) { dismiss() }
                }
            }
        }
    }

    private func answerLine(_ question: QuizQuestion) -> some View {
        let outcome = result.outcome(for: question)
        let (symbol, color): (String, Color) = switch outcome {
        case .correct: ("checkmark.circle.fill", ColorTokens.successText)
        case .partial: ("circle.lefthalf.filled", ColorTokens.warningText)
        case .incorrect: ("xmark.circle.fill", ColorTokens.error)
        case .skipped: ("minus.circle", ColorTokens.textSecondary)
        }
        let text: String = if outcome == .skipped {
            QuizCopy.skipped
        } else {
            QuizCopy.yourAnswer(result.yourAnswer(for: question) ?? "")
        }
        return HStack(alignment: .firstTextBaseline, spacing: Spacing.s2) {
            Label(text, systemImage: symbol)
                .font(.sfCallout)
                .foregroundStyle(color)
            if outcome == .partial {
                Text(QuizCopy.halfCredit)
                    .font(.sfCaption.weight(.semibold))
                    .foregroundStyle(ColorTokens.warningText)
            }
        }
    }

    private func card(number: Int, question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            HStack {
                Text(QuizCopy.questionNumber(number))
                    .font(.sfFootnote.weight(.semibold))
                    .foregroundStyle(ColorTokens.textSecondary)
                Spacer()
                if result.isFlagged(question) {
                    Label(QuizCopy.flaggedTag, systemImage: "flag.fill")
                        .font(.sfCaption.weight(.semibold))
                        .foregroundStyle(ColorTokens.warningText)
                }
            }
            Text(question.stem)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Label(QuizCopy.correctAnswer(result.correctAnswer(for: question)), systemImage: "checkmark.circle.fill")
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.successText)
            answerLine(question)
            if !question.explanation.isEmpty {
                Text(question.explanation)
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: Spacing.s2) {
                QuizCitationChip(label: question.provenance.pageNumbers.isEmpty ? QuizCopy.source : question.provenance.citationLabel)
                QuizTopicChip(title: QuizCopy.topicTag(question.topic))
                Spacer(minLength: 0)
            }
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .summaryGlass(cornerRadius: 14, strong: true)
        .accessibilityElement(children: .combine)
    }
}

#Preview("59 Review answers") {
    QuizAnswerReviewView(
        result: QuizResult(
            quiz: QuizPreviewData.takenQuiz,
            attempt: QuizPreviewData.takenQuiz.attempts[0],
            record: QuizPreviewData.takenRecord
        )
    )
}
