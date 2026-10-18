import SwiftUI

struct SummaryQuotaView: View {

    let viewModel: SummaryScreensViewModel
    let onUpgrade: (() -> Void)?

    @State private var isShowingUpgradeInfo = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.s4) {
                Text("!")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(ColorTokens.onAccent)
                    .frame(width: 64, height: 64)
                    .background(ColorTokens.warning, in: .circle)
                    .padding(.top, 140 - Spacing.s12)
                    .accessibilityHidden(true)

                VStack(spacing: Spacing.s2) {
                    Text("Daily limit reached")
                        .font(.sfTitleM)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .accessibilityAddTraits(.isHeader)

                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        Text("Your free AI generations reset in \(viewModel.resetText(now: context.date)).")
                            .font(.sfCallout)
                            .foregroundStyle(ColorTokens.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, Spacing.s3)
                .padding(.bottom, Spacing.s8)

                Button {
                    viewModel.switchToOnDevice()
                } label: {
                    optionLabel(
                        title: "Switch to on-device engine",
                        subtitle: "Unlimited · private",
                        foreground: ColorTokens.textPrimary,
                        secondary: ColorTokens.textSecondary
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                            .strokeBorder(ColorTokens.outline, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    if let onUpgrade {
                        onUpgrade()
                    } else {
                        isShowingUpgradeInfo = true
                    }
                } label: {
                    optionLabel(
                        title: "Upgrade plan",
                        subtitle: "Plus BHD 1.900 / term",
                        foreground: ColorTokens.onError,
                        secondary: ColorTokens.onError
                    )
                    .background(ColorTokens.primary, in: .rect(cornerRadius: Radius.m))
                }
                .buttonStyle(.plain)

                Button("Try again later") {
                    viewModel.backToConfigure()
                }
                .buttonStyle(SummarySecondaryButtonStyle())
            }
            .padding(.horizontal, Layout.screenMargin + Spacing.s3)
            .padding(.bottom, Spacing.s6)
        }
        .alert("Upgrade plan", isPresented: $isShowingUpgradeInfo) {
            Button(L10n.commonDone.string, role: .cancel) {}
        } message: {
            Text("Upgrading will be available soon.")
        }
    }

    private func optionLabel(title: String, subtitle: String, foreground: Color, secondary: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text(title)
                .font(.sfSubhead)
                .foregroundStyle(foreground)
            Text(subtitle)
                .font(.sfCaption)
                .foregroundStyle(secondary)
        }
        .padding(.horizontal, Spacing.s4)
        .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
