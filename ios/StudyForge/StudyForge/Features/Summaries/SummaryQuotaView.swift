import SwiftUI

struct SummaryQuotaView: View {

    let viewModel: SummaryScreensViewModel

    @Environment(AppContainer.self) private var container: AppContainer?

    @State private var isShowingPaywall = false
    @State private var isShowingUpgradeUnavailable = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.s4) {
                Text(verbatim: "!")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(ColorTokens.onAccent)
                    .frame(width: 64, height: 64)
                    .background(ColorTokens.warning, in: .circle)
                    .padding(.top, 140 - Spacing.s12)
                    .accessibilityHidden(true)

                VStack(spacing: Spacing.s2) {
                    Text(SummaryCopy.quotaTitle)
                        .font(.sfTitleM)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .accessibilityAddTraits(.isHeader)

                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        Text(SummaryCopy.quotaBody(viewModel.resetText(now: context.date)))
                            .font(.sfCallout)
                            .foregroundStyle(ColorTokens.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, Spacing.s3)
                .padding(.bottom, Spacing.s8)

                Button {
                    _ = viewModel.switchToOnDevice()
                } label: {
                    optionLabel(
                        title: SummaryCopy.quotaOnDevice,
                        subtitle: viewModel.onDeviceUnavailableReason?.title ?? SummaryCopy.quotaOnDeviceSubtitle,
                        foreground: ColorTokens.textPrimary,
                        secondary: ColorTokens.textSecondary
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                            .strokeBorder(ColorTokens.outline, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canUseOnDevice)
                .opacity(viewModel.canUseOnDevice ? 1 : 0.5)

                Button {
                    if container != nil {
                        isShowingPaywall = true
                    } else {
                        isShowingUpgradeUnavailable = true
                    }
                } label: {
                    optionLabel(
                        title: SummaryCopy.quotaUpgrade,
                        subtitle: SummaryCopy.quotaUpgradeSubtitle,
                        foreground: ColorTokens.onError,
                        secondary: ColorTokens.onError
                    )
                    .background(ColorTokens.primary, in: .rect(cornerRadius: Radius.m))
                }
                .buttonStyle(.plain)

                Button(SummaryCopy.quotaLater) {
                    viewModel.backToConfigure()
                }
                .buttonStyle(SummarySecondaryButtonStyle())
            }
            .padding(.horizontal, Layout.screenMargin + Spacing.s3)
            .padding(.bottom, Spacing.s6)
        }
        .sheet(isPresented: $isShowingPaywall, onDismiss: {
            if !viewModel.isQuotaBlocked {
                viewModel.backToConfigure()
            }
        }) {
            if let container {
                NavigationStack {
                    PaywallView(container: container)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button(L10n.commonCancel.string) { isShowingPaywall = false }
                            }
                        }
                }
            }
        }
        .alert(SummaryCopy.quotaUpgrade, isPresented: $isShowingUpgradeUnavailable) {
            Button(L10n.commonDone.string, role: .cancel) {}
        } message: {
            Text(SummaryCopy.quotaUpgradeUnavailable)
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
