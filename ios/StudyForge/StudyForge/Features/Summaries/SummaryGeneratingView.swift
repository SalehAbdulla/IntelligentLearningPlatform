import SwiftUI

struct SummaryGeneratingView: View {

    let viewModel: SummaryScreensViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s4) {
                    Text("Generating summary")
                        .font(.sfTitleM)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .padding(.top, Spacing.s12)

                    Label(viewModel.engine.badgeTitle, systemImage: viewModel.engine.symbolName)
                        .font(.sfFootnote.weight(.semibold))
                        .foregroundStyle(ColorTokens.onPrimaryContainer)
                        .padding(.horizontal, Spacing.s4)
                        .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
                        .background(ColorTokens.primaryContainer, in: .rect(cornerRadius: Radius.m))
                        .padding(.bottom, Spacing.s3)

                    ForEach(0..<5, id: \.self) { _ in
                        SummarySkeletonCard()
                            .opacity(isPulsing ? 0.55 : 1)
                    }

                    HStack(spacing: Spacing.s2) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(ColorTokens.primary)
                                .frame(width: 12, height: 12)
                                .scaleEffect(isPulsing ? 0.6 : 1)
                                .animation(
                                    reduceMotion ? nil : Animation.easeInOut(duration: 0.6).repeatForever().delay(Double(index) * 0.2),
                                    value: isPulsing
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, Spacing.s5)
                }
                .padding(.horizontal, Layout.screenMargin + Spacing.s3)
            }
            .scrollDisabled(true)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Generating summary. \(viewModel.engine.badgeTitle)")
            .accessibilityAddTraits(.updatesFrequently)

            Button(L10n.commonCancel.string) {
                viewModel.cancelGeneration()
            }
            .buttonStyle(SummarySecondaryButtonStyle(outlined: true))
            .padding(.horizontal, Layout.screenMargin + Spacing.s3)
            .padding(.bottom, Spacing.s6)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}
