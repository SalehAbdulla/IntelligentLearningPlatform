//
//  ProfileSetupLearningStyleView.swift
//  StudyForge
//
//  B02 — `12_ProfileSetup_LearningStyle_{M1}` (docs/03 §B, P0). Step two of the profile
//  wizard: four selectable cards, each with a sample output preview, then Continue.
//
//  The cards are driven by `LearningStyle.allCases`, so the screen cannot offer a style the
//  AI layer does not understand, and the value written is the one the prompt builder reads.
//

import SwiftUI

struct ProfileSetupLearningStyleView: View {

    @State private var viewModel: ProfileSetupLearningStyleViewModel

    /// Card selection animates, so it respects Reduce Motion like everything else.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(profile: any ProfileService, onContinue: @escaping (LearningStyle) -> Void) {
        _viewModel = State(
            initialValue: ProfileSetupLearningStyleViewModel(
                profile: profile,
                onSaved: onContinue
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {

                heading

                if let error = viewModel.error {
                    SFErrorBanner(
                        error: error,
                        onRecover: { Task { await viewModel.submit() } }
                    )
                }

                cards

                SFPrimaryButton(
                    title: L10n.commonContinue.string,
                    isLoading: viewModel.isSubmitting,
                    isEnabled: viewModel.isSubmitEnabled,
                    action: { Task { await viewModel.submit() } },
                    loadingTitle: L10n.profileLearningStyleSubmitting.string
                )
                .padding(.top, Spacing.s3)
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(ColorTokens.surface)
    }

    // MARK: Sections

    private var heading: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {

            Text(viewModel.stepLabel)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.primary)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: Spacing.s2) {
                Text(L10n.profileLearningStyleTitle.string)
                    .font(.sfTitleL)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(L10n.profileLearningStyleSubtitle.string)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
        }
    }

    private var cards: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            ForEach(viewModel.options) { option in
                SFRadioCard(
                    title: option.title,
                    detail: option.preview,
                    isSelected: viewModel.isSelected(option.style)
                ) {
                    viewModel.select(option.style)
                }
            }

            SFFieldFeedback(error: viewModel.selectionError, hint: nil)
        }
        .animation(
            Motion.respecting(Motion.quick, reduceMotion: reduceMotion),
            value: viewModel.selection
        )
    }
}

// MARK: - Previews

#Preview("B02 Profile setup — learning style") {
    ProfileSetupLearningStyleView(profile: MockProfileService(latency: .zero)) { _ in }
}

#Preview("B02 Profile setup — save rejected") {
    // The state worth seeing before a viva: the server refusing the write.
    let profile = MockProfileService(latency: .zero)
    profile.forceFailure(.writeRejected(reference: "profile-write-denied"))

    return ProfileSetupLearningStyleView(profile: profile) { _ in }
}
