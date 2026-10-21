import SwiftUI

struct SummaryConfigureView: View {

    @Bindable var viewModel: SummaryScreensViewModel
    let onClose: () -> Void

    @FocusState private var isFocusFieldActive: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                HStack {
                    Spacer()
                    Button(L10n.commonCancel.string, action: onClose)
                        .font(.sfCallout)
                        .foregroundStyle(ColorTokens.primary)
                        .frame(minHeight: Layout.minTouchTarget)
                }

                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Text("Summarise")
                        .font(.sfTitleL)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text(viewModel.fileName)
                        .font(.sfFootnote)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .lineLimit(2)
                }

                SummaryOptionPicker(
                    title: L10n.summaryLengthLabel.string,
                    options: SummaryLength.allCases,
                    selection: $viewModel.length,
                    optionTitle: { $0.optionTitle }
                )

                SummaryOptionPicker(
                    title: L10n.summaryStyleLabel.string,
                    options: SummaryStyle.allCases,
                    selection: $viewModel.style,
                    optionTitle: { $0.optionTitle }
                )

                SummaryOptionPicker(
                    title: L10n.summaryLanguageLabel.string,
                    options: OutputLanguage.allCases,
                    selection: $viewModel.language,
                    optionTitle: { $0.optionTitle }
                )

                focusField

                if let materialError = viewModel.materialError {
                    Label(materialError, systemImage: "exclamationmark.triangle.fill")
                        .font(.sfFootnote)
                        .foregroundStyle(ColorTokens.error)
                        .padding(Spacing.s3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .summaryGlass()
                }

                if let error = viewModel.error {
                    SFErrorBanner(
                        error: error,
                        onRecover: recoverAction(for: error),
                        recoverTitle: recoverTitle(for: error)
                    )
                }

                VStack(spacing: Spacing.s2) {
                    SFPrimaryButton(title: L10n.summaryGenerate.string, isEnabled: viewModel.canGenerate) {
                        isFocusFieldActive = false
                        _ = viewModel.generate()
                    }

                    if viewModel.showsCloudAllowance {
                        Text("\(viewModel.remainingToday) of \(viewModel.dailyLimit) free generations left today")
                            .font(.sfFootnote)
                            .foregroundStyle(ColorTokens.textSecondary)
                            .monospacedDigit()
                    } else {
                        Label(viewModel.predictedEngine.badgeTitle, systemImage: viewModel.predictedEngine.symbolName)
                            .font(.sfFootnote)
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.s12 - Spacing.s6)
            }
            .padding(.horizontal, Layout.screenMargin + Spacing.s3)
            .padding(.bottom, Spacing.s6)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func recoverAction(for error: AppError) -> (() -> Void)? {
        switch error {
        case .materialUnreadable, .notPermitted, .onDeviceAIUnavailable:
            return { viewModel.dismissError() }
        default:
            return { _ = viewModel.generate() }
        }
    }

    private func recoverTitle(for error: AppError) -> String? {
        switch error {
        case .materialUnreadable, .notPermitted, .onDeviceAIUnavailable:
            return L10n.commonDone.string
        default:
            return nil
        }
    }

    private var focusField: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text("\(L10n.summaryFocusLabel.string) (optional)")
                .font(.sfFootnote.weight(.semibold))
                .foregroundStyle(ColorTokens.textSecondary)

            TextField(
                "",
                text: $viewModel.focusTopics,
                prompt: Text(L10n.summaryFocusPlaceholder.string).foregroundStyle(ColorTokens.textTertiary)
            )
            .font(.sfCallout)
            .foregroundStyle(ColorTokens.textPrimary)
            .focused($isFocusFieldActive)
            .submitLabel(.done)
            .onSubmit { isFocusFieldActive = false }
            .onChange(of: viewModel.focusTopics) {
                viewModel.limitFocusTopics()
            }
            .padding(.horizontal, Spacing.s4)
            .frame(minHeight: 52)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                    .strokeBorder(viewModel.focusError == nil ? ColorTokens.outline : ColorTokens.error, lineWidth: 1)
            )
            .accessibilityLabel(L10n.summaryFocusLabel.string)

            HStack(alignment: .top) {
                if let focusError = viewModel.focusError {
                    Label(focusError, systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(ColorTokens.error)
                } else {
                    Text("Separate topics with commas.")
                        .foregroundStyle(ColorTokens.textSecondary)
                }
                Spacer()
                Text("\(viewModel.focusTopics.count)/\(SummaryLimits.focusMaxCharacters)")
                    .foregroundStyle(ColorTokens.textSecondary)
                    .monospacedDigit()
            }
            .font(.sfFootnote)
        }
    }
}
