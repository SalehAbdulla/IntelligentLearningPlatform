import SwiftUI

struct QuizScorecardView: View {

    let result: QuizResult
    let error: AppError?
    let onReview: () -> Void
    let onRetakeWeak: () -> Void
    let onRetakeAll: () -> Void
    let onAllAttempts: () -> Void
    let onDone: () -> Void

    private var margin: CGFloat { Layout.screenMargin + Spacing.s3 }

    private var scoreValue: String {
        let earned = result.earned
        return earned.rounded() == earned ? Int(earned).formatted() : earned.formatted(.number.precision(.fractionLength(1)))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.s5) {
                HStack {
                    Spacer()
                    Button(QuizCopy.done, action: onDone)
                        .font(.sfCallout.weight(.semibold))
                        .tint(ColorTokens.primary)
                        .frame(minHeight: Layout.minTouchTarget)
                }

                QuizScoreRing(
                    fraction: Double(result.percent) / 100,
                    score: result.scoreText,
                    percent: result.percent,
                    accessibilityText: QuizCopy.scoreAccessibility(scoreValue, result.total, result.percent)
                )

                VStack(spacing: Spacing.s1) {
                    Text(result.quiz.title)
                        .font(.sfTitleM)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    if let duration = result.durationText {
                        Text(QuizCopy.completedIn(duration))
                            .font(.sfFootnote)
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                    if result.timedOut {
                        Label(QuizCopy.timeUp, systemImage: "timer")
                            .font(.sfFootnote)
                            .foregroundStyle(ColorTokens.warningText)
                            .multilineTextAlignment(.center)
                            .padding(.top, Spacing.s1)
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.s2) {
                    Text(QuizCopy.topicHeading)
                        .font(.sfSubhead)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    ForEach(result.topics) { topic in
                        QuizTopicBar(result: topic)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                callout

                if let error {
                    SFErrorBanner(error: error, onRecover: nil)
                }

                HStack(spacing: Spacing.s3) {
                    Button(QuizCopy.review, action: onReview)
                        .buttonStyle(SummaryActionButtonStyle(isPrimary: true))
                    if result.weakQuestions.isEmpty {
                        Button(QuizCopy.retakeQuiz, action: onRetakeAll)
                            .buttonStyle(SummaryActionButtonStyle())
                    } else {
                        Button(QuizCopy.retakeWeak, action: onRetakeWeak)
                            .buttonStyle(SummaryActionButtonStyle())
                    }
                }

                Button(QuizCopy.allAttempts, action: onAllAttempts)
                    .font(.sfFootnote.weight(.semibold))
                    .tint(ColorTokens.primary)
                    .frame(minHeight: Layout.minTouchTarget)
            }
            .padding(.horizontal, margin)
            .padding(.bottom, Spacing.s6)
        }
    }

    @ViewBuilder
    private var callout: some View {
        if let weakest = result.weakestTopic {
            Label(QuizCopy.focus(weakest.topic), systemImage: "scope")
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textPrimary)
                .padding(Spacing.s4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ColorTokens.error.opacity(0.24), in: .rect(cornerRadius: Radius.m))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                        .strokeBorder(ColorTokens.error.opacity(0.6), lineWidth: 1)
                )
        } else {
            Label(QuizCopy.allStrong, systemImage: "star.fill")
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textPrimary)
                .padding(Spacing.s4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ColorTokens.success.opacity(0.2), in: .rect(cornerRadius: Radius.m))
        }
    }
}

#Preview("58 Scorecard") {
    ZStack {
        SummaryBackdrop()
        QuizScorecardView(
            result: QuizResult(
                quiz: QuizPreviewData.takenQuiz,
                attempt: QuizPreviewData.takenQuiz.attempts[0],
                record: QuizPreviewData.takenRecord
            ),
            error: nil,
            onReview: {},
            onRetakeWeak: {},
            onRetakeAll: {},
            onAllAttempts: {},
            onDone: {}
        )
    }
}
