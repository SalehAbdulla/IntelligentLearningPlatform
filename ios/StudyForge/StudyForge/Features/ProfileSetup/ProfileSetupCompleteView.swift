//
//  ProfileSetupCompleteView.swift
//  StudyForge
//
//  B04 — `14_ProfileSetup_Complete_{M1}` (docs/03 §B, P1). The wizard's confirmation screen:
//  a short success message, a summary of what the student chose, and one way out.
//
//  WHY IT SUMMARISES THE ANSWERS THE FLOW CARRIED
//  ---------------------------------------------
//  It reads `ProfileSetupAnswers` from the wizard — the values the steps actually saved — so
//  the summary cannot disagree with what was written to `users/{uid}`. Re-reading the profile
//  would make a slow screen; re-deriving the defaults would let the summary say something the
//  student never chose.
//
//  DEVIATION FROM THE DESIGN, RECORDED HERE
//  ---------------------------------------
//  docs/03 §B draws "Go to dashboard" as the primary button. The dashboard (B05) is F07's
//  screen and does not exist yet, so the button lands the student on the signed-in home — the
//  honest destination today. The label stays as designed, because that is where this flow
//  goes the moment B05 lands, and changing it now would only mean changing it back.
//

import SwiftUI

// Accessibility: the confirmation heading reads as one element and the celebratory glyph is hidden.

struct ProfileSetupCompleteView: View {

    @State private var viewModel: ProfileSetupCompleteViewModel

    /// Raised when the student leaves the confirmation screen — the true end of the wizard.
    /// `RootView` decides what "finished" means.
    let onGoToDashboard: () -> Void

    init(
        answers: ProfileSetupAnswers,
        catalogue: AcademicCatalogue = .placeholder,
        onGoToDashboard: @escaping () -> Void
    ) {
        _viewModel = State(
            initialValue: ProfileSetupCompleteViewModel(answers: answers, catalogue: catalogue)
        )
        self.onGoToDashboard = onGoToDashboard
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {

                celebration

                if viewModel.hasRows {
                    summary
                }

                SFPrimaryButton(
                    title: viewModel.goToDashboardTitle,
                    action: onGoToDashboard
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

    private var celebration: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {

            // Decorative: the heading below carries the meaning, so this is hidden from
            // VoiceOver rather than announced as an unnamed image.
            Image(systemName: "checkmark.circle.fill")
                .font(.sfDisplayL)
                .foregroundStyle(ColorTokens.successText)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.s2) {
                Text(viewModel.title)
                    .font(.sfTitleL)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(viewModel.subtitle)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            // One statement, and a header: VoiceOver should reach the confirmation as a single
            // heading, not as two loose sentences.
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {

            Text(viewModel.summaryHeading)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: Spacing.s3) {
                ForEach(viewModel.rows) { row in
                    SFDetailRow(row: row)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.s4)
            .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
        }
    }
}

// MARK: - Previews

#Preview("B04 Profile setup — complete") {
    ProfileSetupCompleteView(
        answers: ProfileSetupAnswers(
            academic: AcademicProfile(
                university: "Bahrain Polytechnic",
                major: "Programming",
                year: 2,
                courseIds: ["IT8108", "c_104"]
            ),
            learningStyle: .readWrite,
            studyGoals: StudyGoals(weeklyStudyGoalHours: 12, targetGrade: .a)
        )
    ) {}
}

#Preview("B04 Profile setup — only the last step answered") {
    // What `-profileSetupStep 3` reaches: the goals are known and the earlier steps were
    // never shown, so the summary states the goals and stays silent about the rest.
    ProfileSetupCompleteView(
        answers: ProfileSetupAnswers(
            studyGoals: StudyGoals(weeklyStudyGoalHours: 8, targetGrade: .b)
        )
    ) {}
}
