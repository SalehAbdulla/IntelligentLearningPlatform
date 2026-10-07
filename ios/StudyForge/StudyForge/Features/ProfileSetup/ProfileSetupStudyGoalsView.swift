//
//  ProfileSetupStudyGoalsView.swift
//  StudyForge
//
//  B03 — `13_ProfileSetup_StudyGoals_{M1}` (docs/03 §B, P0). The wizard's last step: how
//  much time the student has each week, what they are aiming for, then Finish setup.
//
//  A NOTE ON THE CONTROL THIS SCREEN DELIBERATELY DOES NOT HAVE
//  -----------------------------------------------------------
//  docs/03 §B also draws exam-date pickers here. They are not built, because an exam date is
//  per-course and per-term and therefore belongs to the study plan F06 owns rather than to a
//  profile document — see `StudyGoals` and docs/09 Q11 for the reasoning, recorded as a
//  deviation rather than left as a gap.
//

import SwiftUI

// Accessibility: each question's heading reads as one element.

struct ProfileSetupStudyGoalsView: View {

    @State private var viewModel: ProfileSetupStudyGoalsViewModel

    init(profile: any ProfileService, onFinish: @escaping (StudyGoals) -> Void) {
        _viewModel = State(
            initialValue: ProfileSetupStudyGoalsViewModel(
                profile: profile,
                onSaved: onFinish
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

                SFSlider(
                    label: L10n.profileStudyGoalsHoursLabel.string,
                    value: $viewModel.hours,
                    range: ProfileSetupStudyGoalsViewModel.hoursRange,
                    readout: viewModel.hoursReadout
                )

                SFSegmentedField(
                    label: L10n.profileStudyGoalsGradeLabel.string,
                    selection: $viewModel.grade,
                    options: viewModel.gradeOptions,
                    title: viewModel.title(for:),
                    error: viewModel.gradeError
                )

                SFPrimaryButton(
                    // "Finish setup" rather than "Continue": this is the last step, and a
                    // wizard that keeps saying Continue leaves the student waiting for a
                    // further screen that does not exist.
                    title: L10n.profileStudyGoalsFinish.string,
                    isLoading: viewModel.isSubmitting,
                    isEnabled: viewModel.isSubmitEnabled,
                    action: { Task { await viewModel.submit() } },
                    loadingTitle: L10n.profileStudyGoalsSubmitting.string
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
                Text(L10n.profileStudyGoalsTitle.string)
                    .font(.sfTitleL)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(L10n.profileStudyGoalsSubtitle.string)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
        }
    }
}

// MARK: - Previews

#Preview("B03 Profile setup — study goals") {
    ProfileSetupStudyGoalsView(profile: MockProfileService(latency: .zero)) { _ in }
}

#Preview("B03 Profile setup — save rejected") {
    // The state worth seeing before a viva: the server refusing the write.
    let profile = MockProfileService(latency: .zero)
    profile.forceFailure(.writeRejected(reference: "profile-write-denied"))

    return ProfileSetupStudyGoalsView(profile: profile) { _ in }
}
