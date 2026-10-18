import SwiftUI

enum SummaryGlass {
    static let fill = Color(light: 0xFFFFFF, dark: 0x131C2E)
    static let border = Color(light: 0xFFFFFF, dark: 0x263149)
    static let canvasTop = Color(light: 0xF5F6FB, dark: 0x0B1220)
    static let canvasMiddle = Color(light: 0xFFFFFF, dark: 0x10233A)
    static let canvasBottom = Color(light: 0xF8F7FC, dark: 0x10233A)
    static let blobBlue = Color(hex: 0x0062CC, opacity: 0.24)
    static let blobSky = Color(hex: 0x32ADE6, opacity: 0.24)
    static let blobTeal = Color(hex: 0x30B0C7, opacity: 0.24)
}

extension View {
    func summaryGlass(cornerRadius: CGFloat = Radius.m, strong: Bool = false) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(SummaryGlass.fill.opacity(strong ? 0.86 : 0.66))
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(SummaryGlass.border.opacity(0.85), lineWidth: 1)
        )
    }
}

struct SummaryBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [SummaryGlass.canvasTop, SummaryGlass.canvasMiddle, SummaryGlass.canvasBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            Circle()
                .fill(SummaryGlass.blobBlue)
                .frame(width: 260, height: 260)
                .blur(radius: 50)
                .offset(x: -150, y: -170)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            Circle()
                .fill(SummaryGlass.blobSky)
                .frame(width: 230, height: 230)
                .blur(radius: 50)
                .offset(x: 195, y: 190)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            Circle()
                .fill(SummaryGlass.blobTeal)
                .frame(width: 250, height: 250)
                .blur(radius: 50)
                .offset(x: -160, y: 46)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct SummaryOptionPicker<Option: Hashable>: View {
    let title: String
    let options: [Option]
    @Binding var selection: Option
    let optionTitle: (Option) -> String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(title)
                .font(.sfFootnote.weight(.semibold))
                .foregroundStyle(ColorTokens.textSecondary)

            HStack(spacing: 0) {
                ForEach(options, id: \.self) { option in
                    let isSelected = option == selection
                    Button {
                        withAnimation(Motion.respecting(Motion.quick, reduceMotion: reduceMotion)) {
                            selection = option
                        }
                    } label: {
                        Text(optionTitle(option))
                            .font(isSelected ? Font.sfFootnote.weight(.semibold) : Font.sfFootnote)
                            .foregroundStyle(isSelected ? ColorTokens.textPrimary : ColorTokens.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .background {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: Radius.s, style: .continuous)
                                        .fill(SummaryGlass.fill)
                                        .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
                                }
                            }
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(Spacing.s1)
            .summaryGlass(cornerRadius: 10)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
    }
}

struct SummarySecondaryButtonStyle: ButtonStyle {
    var outlined = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.sfSubhead)
            .foregroundStyle(ColorTokens.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background {
                if outlined {
                    RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                        .strokeBorder(ColorTokens.outline, lineWidth: 1)
                } else {
                    Color.clear.summaryGlass()
                }
            }
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

struct SummarySkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Capsule()
                .fill(ColorTokens.outline)
                .frame(height: 10)
            Capsule()
                .fill(ColorTokens.outline)
                .frame(height: 10)
                .padding(.trailing, Spacing.s12 + Spacing.s3)
        }
        .padding(.horizontal, Spacing.s4)
        .padding(.vertical, Spacing.s4 + 2)
        .frame(maxWidth: .infinity, minHeight: 70, alignment: .topLeading)
        .summaryGlass(strong: true)
    }
}
