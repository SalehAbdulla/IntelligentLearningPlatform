import Charts
import SwiftUI

struct QuizAttemptsView: View {

    @State private var viewModel: QuizAttemptsViewModel
    @State private var reviewing: QuizAttemptSummary?

    @Environment(\.dismiss) private var dismiss

    private let onRetake: () -> Void
    private let margin = Layout.screenMargin + Spacing.s3

    init(
        quiz: Quiz,
        store: any QuizStore,
        log: any QuizAttemptLog = FileQuizAttemptLog.shared,
        onRetake: @escaping () -> Void
    ) {
        self.onRetake = onRetake
        _viewModel = State(initialValue: QuizAttemptsViewModel(quiz: quiz, store: store, log: log))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SummaryBackdrop()
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.s5) {
                        VStack(alignment: .leading, spacing: Spacing.s1) {
                            Text(viewModel.quiz.title)
                                .font(.sfTitleL)
                                .foregroundStyle(ColorTokens.textPrimary)
                                .accessibilityAddTraits(.isHeader)
                            Text(QuizCopy.attemptCount(viewModel.attempts.count))
                                .font(.sfFootnote)
                                .foregroundStyle(ColorTokens.textSecondary)
                        }

                        content

                        if viewModel.hasShortAnswers {
                            VStack(alignment: .leading, spacing: Spacing.s1) {
                                Label(QuizCopy.markingTitle, systemImage: "info.circle")
                                    .font(.sfSubhead)
                                    .foregroundStyle(ColorTokens.textPrimary)
                                Text(QuizCopy.markingBody)
                                    .font(.sfFootnote)
                                    .foregroundStyle(ColorTokens.textSecondary)
                            }
                            .padding(Spacing.s4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .summaryGlass(strong: true)
                        }

                        SFPrimaryButton(title: QuizCopy.retakeQuiz) {
                            onRetake()
                        }
                        Button(QuizCopy.backToResults) { dismiss() }
                            .buttonStyle(SummarySecondaryButtonStyle(outlined: true))
                    }
                    .padding(.horizontal, margin)
                    .padding(.vertical, Spacing.s4)
                    .frame(maxWidth: Layout.maxContentWidth)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonClose.string) { dismiss() }
                }
            }
            .task { await viewModel.load() }
            .sheet(item: $reviewing) { summary in
                QuizAnswerReviewView(result: summary.result)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.hasLoaded {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.s8)
        } else if let error = viewModel.error {
            SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
        } else if viewModel.attempts.isEmpty {
            Text(QuizCopy.noAttempts)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .padding(Spacing.s4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .summaryGlass(strong: true)
        } else {
            chart
            VStack(spacing: Spacing.s2) {
                ForEach(viewModel.attempts) { summary in
                    Button {
                        reviewing = summary
                    } label: {
                        row(summary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func label(for summary: QuizAttemptSummary) -> String {
        summary.date.formatted(.dateTime.day().month(.abbreviated))
    }

    private var chart: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(QuizCopy.chartTitle)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Chart(viewModel.chartPoints) { summary in
                BarMark(
                    x: .value(QuizCopy.chartTitle, "\(summary.number)"),
                    y: .value(QuizCopy.review, summary.result.percent)
                )
                .foregroundStyle(summary.result.tone.color.gradient)
                .cornerRadius(6)
                .annotation(position: .top) {
                    Text(summary.result.scoreText)
                        .font(.sfCaption.weight(.semibold))
                        .foregroundStyle(ColorTokens.textPrimary)
                }
                .accessibilityLabel(Text(QuizCopy.chartPoint(summary.number, summary.result.percent)))
            }
            .chartYScale(domain: 0...100)
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let raw = value.as(String.self),
                           let summary = viewModel.chartPoints.first(where: { "\($0.number)" == raw }) {
                            Text(label(for: summary))
                                .font(.sfCaption)
                        }
                    }
                }
            }
            .frame(height: 160)
        }
        .padding(Spacing.s4)
        .summaryGlass(strong: true)
    }

    private func row(_ summary: QuizAttemptSummary) -> some View {
        let date = summary.date.formatted(.relative(presentation: .named))
        let detail = summary.result.durationText.map { QuizCopy.attemptDetail(date, $0) } ?? date
        return HStack(spacing: Spacing.s3) {
            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(QuizCopy.attemptRow(summary.number, summary.result.scoreText))
                    .font(.sfSubhead)
                    .foregroundStyle(ColorTokens.textPrimary)
                Text(detail)
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
            Spacer(minLength: 0)
            QuizScorePill(text: QuizCopy.percent(summary.result.percent), tone: summary.result.tone)
            Image(systemName: "chevron.forward")
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textSecondary)
                .accessibilityHidden(true)
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget + Spacing.s4, alignment: .leading)
        .summaryGlass(strong: true)
        .contentShape(Rectangle())
    }
}

#Preview("58b All attempts") {
    QuizAttemptsView(
        quiz: QuizPreviewData.takenQuiz,
        store: InMemoryQuizStore(seededWith: [QuizPreviewData.takenQuiz]),
        log: InMemoryQuizAttemptLog(seededWith: [QuizPreviewData.takenRecord]),
        onRetake: {}
    )
}
