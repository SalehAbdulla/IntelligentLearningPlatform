import SwiftUI

enum TutorStudioLayout {
    static let margin = Layout.screenMargin + Spacing.s3
}

struct TutorKPITile: View {
    let value: String
    let label: String
    var tint: Color = ColorTokens.textPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text(value)
                .font(.sfTitleM)
                .foregroundStyle(tint)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.sfCaption)
                .foregroundStyle(ColorTokens.textSecondary)
                .lineLimit(1)
        }
        .padding(Spacing.s3)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .summaryGlass(strong: true)
        .accessibilityElement(children: .combine)
    }
}

struct TutorMasteryPill: View {
    let percent: Int

    private var color: Color {
        if percent >= 80 { return ColorTokens.success }
        if percent >= TutorStudentInsights.atRiskMastery { return ColorTokens.warning }
        return ColorTokens.error
    }

    var body: some View {
        Text(TutorStudioCopy.percent(percent))
            .font(.sfFootnote.weight(.semibold))
            .foregroundStyle(Color.black.opacity(0.85))
            .monospacedDigit()
            .padding(.horizontal, Spacing.s2)
            .frame(minWidth: 48, minHeight: 24)
            .background(color, in: .capsule)
    }
}

struct TutorConfidenceBadge: View {
    let confidence: Double

    private var isLow: Bool { confidence < 0.7 }

    var body: some View {
        Text(TutorStudioCopy.confidence(confidence))
            .font(.sfCaption.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(isLow ? ColorTokens.warningText : ColorTokens.successText)
            .padding(.horizontal, Spacing.s2)
            .frame(minHeight: 22)
            .background((isLow ? ColorTokens.warning : ColorTokens.success).opacity(0.18), in: .capsule)
    }
}

struct TutorRiskBadge: View {
    let flag: TutorRiskFlag

    var body: some View {
        Label(TutorStudioCopy.riskTitle(flag), systemImage: flag.symbolName)
            .font(.sfCaption.weight(.semibold))
            .foregroundStyle(flag == .pendingApproval ? ColorTokens.textSecondary : ColorTokens.error)
            .padding(.horizontal, Spacing.s2)
            .frame(minHeight: 24)
            .background((flag == .pendingApproval ? ColorTokens.outline : ColorTokens.error).opacity(0.16), in: .capsule)
    }
}

struct TutorSectionHeader: View {
    let title: String
    var trailing: String?

    var body: some View {
        HStack {
            Text(title)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
        }
        .padding(.top, Spacing.s2)
    }
}

struct TutorFilterChips<Option: Hashable & Identifiable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s2) {
                ForEach(options) { option in
                    let isSelected = option == selection
                    Button {
                        selection = option
                    } label: {
                        Text(title(option))
                            .font(.sfFootnote.weight(isSelected ? .semibold : .regular))
                            .foregroundStyle(isSelected ? ColorTokens.onError : ColorTokens.textPrimary)
                            .padding(.horizontal, Spacing.s3)
                            .frame(minHeight: 32)
                            .background {
                                if isSelected {
                                    Capsule().fill(ColorTokens.primary)
                                } else {
                                    Capsule().fill(SummaryGlass.fill.opacity(0.66))
                                    Capsule().strokeBorder(SummaryGlass.border, lineWidth: 1)
                                }
                            }
                            .frame(minHeight: Layout.minTouchTarget)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }
}

struct TutorCourseCard: View {
    let course: Course
    let detail: String

    var body: some View {
        HStack(spacing: Spacing.s3) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(course.coverColour)
                .frame(width: 6)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(TutorStudioCopy.courseTitle(course.code, course.name))
                    .font(.sfSubhead)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                Text(detail)
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
                if course.isArchived {
                    Text(TutorStudioCopy.archived)
                        .font(.sfCaption.weight(.semibold))
                        .foregroundStyle(ColorTokens.warningText)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.forward")
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textSecondary)
                .accessibilityHidden(true)
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .summaryGlass(cornerRadius: 14, strong: true)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
