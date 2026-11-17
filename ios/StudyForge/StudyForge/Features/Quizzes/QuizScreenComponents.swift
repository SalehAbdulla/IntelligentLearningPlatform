import SwiftUI

extension QuizScoreTone {
    var color: Color {
        switch self {
        case .strong: ColorTokens.success
        case .fair: ColorTokens.warning
        case .weak: ColorTokens.error
        }
    }
}

enum QuizOptionState: Equatable {
    case idle
    case selected
    case correct
    case chosenWrong
    case dimmed
}

struct QuizScoreRing: View {
    let fraction: Double
    let score: String
    let percent: Int
    let accessibilityText: String
    var size: CGFloat = 132

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = 0.0

    var body: some View {
        ZStack {
            Circle()
                .stroke(ColorTokens.outline.opacity(0.6), lineWidth: 12)
            Circle()
                .trim(from: 0, to: shown)
                .stroke(ColorTokens.primary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: Spacing.s1) {
                Text(score)
                    .font(.sfTitleL)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                Text(QuizCopy.percent(percent))
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .monospacedDigit()
            }
            .padding(Spacing.s4)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .onAppear {
            withAnimation(Motion.respecting(Motion.emphasis, reduceMotion: reduceMotion)) {
                shown = min(max(fraction, 0), 1)
            }
        }
    }
}

struct QuizTopicBar: View {
    let result: QuizTopicResult

    private var tone: QuizScoreTone { QuizScoreTone(percent: result.percent) }

    var body: some View {
        HStack(spacing: Spacing.s3) {
            Text(result.topic)
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textPrimary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(ColorTokens.outline.opacity(0.6))
                    Capsule()
                        .fill(tone.color)
                        .frame(width: proxy.size.width * min(max(result.fraction, 0), 1))
                }
            }
            .frame(width: 120, height: 8)
            Text(QuizCopy.percent(result.percent))
                .font(.sfFootnote.weight(.semibold))
                .foregroundStyle(ColorTokens.textPrimary)
                .monospacedDigit()
                .frame(minWidth: 40, alignment: .trailing)
        }
        .frame(minHeight: Layout.minTouchTarget - Spacing.s2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(result.topic)
        .accessibilityValue(QuizCopy.percent(result.percent))
    }
}

struct QuizScorePill: View {
    let text: String
    let tone: QuizScoreTone

    var body: some View {
        Text(text)
            .font(.sfFootnote.weight(.semibold))
            .foregroundStyle(Color.black.opacity(0.85))
            .monospacedDigit()
            .padding(.horizontal, Spacing.s3)
            .frame(minHeight: 28)
            .background(tone.color, in: .capsule)
    }
}

struct QuizTopicChip: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.sfCaption.weight(.semibold))
            .foregroundStyle(ColorTokens.onPrimaryContainer)
            .lineLimit(1)
            .padding(.horizontal, Spacing.s3)
            .frame(minHeight: 24)
            .background(ColorTokens.primaryContainer, in: .capsule)
    }
}

struct QuizCitationChip: View {
    let label: String

    var body: some View {
        Label(QuizCopy.cite(label), systemImage: "doc.text")
            .font(.sfCaption.weight(.semibold))
            .foregroundStyle(ColorTokens.primary)
            .padding(.horizontal, Spacing.s3)
            .frame(minHeight: 26)
            .background(ColorTokens.primary.opacity(0.12), in: .capsule)
    }
}

struct QuizOptionRow: View {
    let text: String
    let state: QuizOptionState
    var tag: String?
    let accessibilityText: String

    private var fill: Color {
        switch state {
        case .idle, .dimmed: SummaryGlass.fill.opacity(0.66)
        case .selected: ColorTokens.primary.opacity(0.16)
        case .correct: ColorTokens.success.opacity(0.22)
        case .chosenWrong: ColorTokens.error.opacity(0.22)
        }
    }

    private var stroke: Color {
        switch state {
        case .idle, .dimmed: SummaryGlass.border.opacity(0.85)
        case .selected: ColorTokens.primary
        case .correct: ColorTokens.success
        case .chosenWrong: ColorTokens.error
        }
    }

    private var symbol: String {
        switch state {
        case .idle, .dimmed: "circle"
        case .selected: "largecircle.fill.circle"
        case .correct: "checkmark.circle.fill"
        case .chosenWrong: "xmark.circle.fill"
        }
    }

    private var symbolColor: Color {
        switch state {
        case .idle, .dimmed: ColorTokens.textTertiary
        case .selected: ColorTokens.primary
        case .correct: ColorTokens.success
        case .chosenWrong: ColorTokens.error
        }
    }

    var body: some View {
        HStack(spacing: Spacing.s3) {
            Image(systemName: symbol)
                .font(.sfBody)
                .foregroundStyle(symbolColor)
                .accessibilityHidden(true)
            Text(text)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textPrimary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let tag {
                Text(tag)
                    .font(.sfCaption.weight(.semibold))
                    .foregroundStyle(symbolColor)
            }
        }
        .padding(.horizontal, Spacing.s4)
        .padding(.vertical, Spacing.s3)
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .background(fill, in: .rect(cornerRadius: Radius.m))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                .strokeBorder(stroke, lineWidth: state == .idle || state == .dimmed ? 1 : 1.5)
        )
        .opacity(state == .dimmed ? 0.6 : 1)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }
}

struct QuizTimerBadge: View {
    let text: String
    let isLow: Bool

    var body: some View {
        Label(text, systemImage: "timer")
            .labelStyle(.titleOnly)
            .font(.sfFootnote.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(isLow ? ColorTokens.error : ColorTokens.textPrimary)
            .padding(.horizontal, Spacing.s3)
            .frame(minHeight: 30)
            .overlay(
                Capsule()
                    .strokeBorder(isLow ? ColorTokens.error : ColorTokens.outline, lineWidth: 1)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(QuizCopy.timeLeft(text))
            .accessibilityAddTraits(.updatesFrequently)
    }
}
