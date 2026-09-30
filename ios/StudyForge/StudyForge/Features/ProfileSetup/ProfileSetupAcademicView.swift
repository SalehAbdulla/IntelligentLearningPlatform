//
//  ProfileSetupAcademicView.swift
//  StudyForge
//
//  B01 — `11_ProfileSetup_Academic_{M1}` (docs/03 §B, P0). Step one of the profile
//  wizard: university picker, major field, year segmented control, enrolled-course
//  chips, Continue.
//
//  DEVIATION FROM THE DESIGN, RECORDED HERE
//  ---------------------------------------
//  The frame's course row includes an **add button**, which implies a searchable course
//  catalogue behind it. There is no catalogue to search: `courses/{courseId}` is readable
//  only by an enrolled student, and a student mid-wizard is enrolled in nothing (see the
//  note in `AcademicCatalogue`). So the chips ARE the picker in F01 — every known course
//  is shown and tap-toggles — and the add/search flow arrives with C01 in F02, when there
//  is a real list to search. docs/03's description column records the same deviation.
//
//  Free-text type input is deliberately NOT accepted instead of the missing button: it
//  would let a student store a course id that no `courses/{id}` document backs, which
//  surfaces much later as material filed under a course that does not exist.
//

import SwiftUI

struct ProfileSetupAcademicView: View {

    @State private var viewModel: ProfileSetupAcademicViewModel

    /// Chip selection animates, so it has to respect Reduce Motion like everything else.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        profile: any ProfileService,
        catalogue: AcademicCatalogue = .placeholder,
        onContinue: @escaping (AcademicProfile) -> Void
    ) {
        _viewModel = State(
            initialValue: ProfileSetupAcademicViewModel(
                profile: profile,
                catalogue: catalogue,
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

                universityField
                majorField
                yearField
                coursesField

                SFPrimaryButton(
                    title: L10n.commonContinue.string,
                    isLoading: viewModel.isSubmitting,
                    isEnabled: viewModel.isSubmitEnabled,
                    action: { Task { await viewModel.submit() } },
                    loadingTitle: L10n.profileAcademicSubmitting.string
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

            // The wizard position, so a four-screen flow never feels open-ended.
            Text(viewModel.stepLabel)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.primary)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: Spacing.s2) {
                Text(L10n.profileAcademicTitle.string)
                    .font(.sfTitleL)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(L10n.profileAcademicSubtitle.string)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
        }
    }

    /// A `Menu` rather than a `Picker`: a menu renders the whole row as the control, so
    /// the entire field is tappable and the chrome matches the text fields beside it. A
    /// `.menu` picker sizes to its own label and leaves the rest of the row inert, which
    /// reads as a broken field.
    private var universityField: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {

            fieldLabel(L10n.profileAcademicUniversity.string)

            Menu {
                ForEach(viewModel.catalogue.universities, id: \.self) { name in
                    Button {
                        viewModel.university = name
                        viewModel.didEdit(.university)
                    } label: {
                        // A tick against the current value, because a menu gives no other
                        // feedback about what is already chosen.
                        if viewModel.university == name {
                            Label(name, systemImage: "checkmark")
                        } else {
                            Text(name)
                        }
                    }
                }
            } label: {
                HStack(spacing: Spacing.s3) {
                    Text(viewModel.university ?? L10n.profileAcademicUniversityPlaceholder.string)
                        .font(.sfBody)
                        .foregroundStyle(
                            viewModel.university == nil
                                ? ColorTokens.textSecondary
                                : ColorTokens.textPrimary
                        )
                        // Wraps rather than truncating: an institution name is a value,
                        // and a clipped value at AX5 is unreadable for the people who
                        // need AX5.
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.sfFootnote)
                        .foregroundStyle(ColorTokens.textTertiary)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .sfFieldBackground(hasError: viewModel.universityError != nil)
            .accessibilityLabel(L10n.profileAcademicUniversity.string)
            .accessibilityValue(
                viewModel.university ?? L10n.profileAcademicUniversityPlaceholder.string
            )

            SFFieldFeedback(error: viewModel.universityError, hint: nil)
        }
    }

    private var majorField: some View {
        SFTextField(
            label: L10n.profileAcademicMajor.string,
            text: $viewModel.major,
            hint: L10n.profileAcademicMajorHint.string,
            error: viewModel.majorError,
            submitLabel: .next,
            // Programme names are proper nouns, so automatic capitalisation is right here
            // where it is wrong for an email address.
            autocapitalization: .words,
            autocorrectionDisabled: false,
            onSubmit: {}
        )
    }

    private var yearField: some View {
        SFSegmentedField(
            label: L10n.profileAcademicYear.string,
            selection: $viewModel.year,
            options: viewModel.catalogue.years,
            // Just the numeral: the field's own label is what makes it read as a year, so
            // "Year of study, 3" is announced without four spelled-out segments
            // truncating at AX5.
            title: { String($0) },
            error: viewModel.yearError
        )
    }

    private var coursesField: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {

            fieldLabel(L10n.profileAcademicCourses.string)

            if viewModel.catalogue.courses.isEmpty {
                // An empty catalogue is a real state, not an impossible one: the list is
                // placeholder data in F01 and comes from C01 later. An empty row with no
                // explanation would read as a bug in the screen.
                Text(L10n.profileAcademicCoursesEmpty.string)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                SFChipFlow {
                    ForEach(viewModel.catalogue.courses) { course in
                        SFChoiceChip(
                            title: course.name,
                            isSelected: viewModel.isSelected(course)
                        ) {
                            viewModel.toggle(course)
                        }
                    }
                }
                .animation(
                    Motion.respecting(Motion.quick, reduceMotion: reduceMotion),
                    value: viewModel.selectedCourses
                )
            }

            SFFieldFeedback(error: viewModel.coursesError, hint: nil)
        }
    }

    /// The caption above a control, hidden from VoiceOver because the control carries the
    /// same string as its own accessibility label — otherwise the caption is read out and
    /// then the control reads itself.
    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.sfSubhead)
            .foregroundStyle(ColorTokens.textSecondary)
            .accessibilityHidden(true)
    }
}

// MARK: - Previews

#Preview("B01 Profile setup — academic") {
    ProfileSetupAcademicView(profile: MockProfileService(latency: .zero)) { _ in }
}

#Preview("B01 Profile setup — save rejected") {
    // The state that matters most on this screen and the hardest to reach by hand: the
    // server refusing the write, which is what a field outside the allowlist produces.
    let profile = MockProfileService(latency: .zero)
    profile.forceFailure(.writeRejected(reference: "profile-write-denied"))

    return ProfileSetupAcademicView(profile: profile) { _ in }
}

#Preview("B01 Profile setup — empty catalogue") {
    // Proves the screen degrades to an explanation instead of an empty row when the
    // placeholder catalogue is replaced by the real, still-loading one in F02.
    ProfileSetupAcademicView(
        profile: MockProfileService(latency: .zero),
        catalogue: AcademicCatalogue(universities: [], years: [1, 2, 3, 4], courses: [])
    ) { _ in }
}
