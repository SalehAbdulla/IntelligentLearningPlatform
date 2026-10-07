//
//  ProfileSetupAcademicView.swift
//  StudyForge
//
//  B01 — `11_ProfileSetup_Academic_{M1}` (docs/03 §B, P0). Step one of the profile
//  wizard: university picker, major field, year segmented control, enrolled-course
//  chips, Continue.
//
//  WHY THE PICKERS ALSO ACCEPT FREE TEXT
//  ------------------------------------
//  The catalogue is a starter set (see the note in `AcademicCatalogue`), and a global product
//  cannot enumerate every institution or course. So the catalogue's entries are offered as
//  quick-picks and the student can type their own: their institution, and any subject the list
//  lacks. A typed subject's NAME is its stored id, because there is no institutional catalogue
//  to key against: the student's own words are the source of truth, which is what makes this
//  screen usable outside one polytechnic. docs/03 §B records the same.
//

import SwiftUI

// Accessibility: each question's heading reads as one element, the illustrative glyph is hidden, and the
// university picker announces its value.

struct ProfileSetupAcademicView: View {

    @State private var viewModel: ProfileSetupAcademicViewModel

    /// Chip selection animates, so it has to respect Reduce Motion like everything else.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The subject being typed into the add field: throwaway UI state, so it lives here
    /// rather than in the view model that owns the saved profile.
    @State private var draftCourse = ""

    init(
        profile: any ProfileService,
        catalogue: AcademicCatalogue,
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

    /// A free-text field with the catalogue's institutions as quick-picks, not a closed menu:
    /// a global product cannot enumerate every university, so the list can only suggest. What
    /// the student types is what is stored.
    private var universityField: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {

            SFTextField(
                label: L10n.profileAcademicUniversity.string,
                text: universityBinding,
                placeholder: L10n.profileAcademicUniversityPlaceholder.string,
                error: viewModel.universityError,
                submitLabel: .next,
                autocapitalization: .words,
                autocorrectionDisabled: false,
                onSubmit: {}
            )

            if !viewModel.catalogue.universities.isEmpty {
                SFChipFlow {
                    ForEach(viewModel.catalogue.universities, id: \.self) { name in
                        SFChoiceChip(title: name, isSelected: viewModel.university == name) {
                            viewModel.university = name
                            viewModel.didEdit(.university)
                        }
                    }
                }
            }
        }
    }

    /// `university` is optional: nil means "nothing chosen", which is what validation and the
    /// quick-pick ticks want, while a text field needs a plain `String`, so an all-whitespace
    /// value round-trips back to nil.
    private var universityBinding: Binding<String> {
        Binding(
            get: { viewModel.university ?? "" },
            set: { newValue in
                viewModel.university = newValue.trimmingCharacters(in: .whitespaces).isEmpty
                    ? nil
                    : newValue
                viewModel.didEdit(.university)
            }
        )
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

            if viewModel.selectedCourses.isEmpty && viewModel.catalogue.courses.isEmpty {
                // Not a dead end: the add field below is the real way in, which is why this
                // only appears when there is neither a catalogue nor a typed subject.
                Text(L10n.profileAcademicCoursesEmpty.string)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !viewModel.selectedCourses.isEmpty || !viewModel.catalogue.courses.isEmpty {
                SFChipFlow {
                    // The catalogue's courses: each is a tap-to-toggle chip.
                    ForEach(viewModel.catalogue.courses) { course in
                        SFChoiceChip(
                            title: course.name,
                            isSelected: viewModel.isSelected(course)
                        ) {
                            viewModel.toggle(course)
                        }
                    }
                    // Subjects the student typed: shown chosen, and a tap removes one.
                    ForEach(viewModel.selectedCourses.filter { viewModel.catalogue.course(for: $0.id) == nil }) { course in
                        SFChoiceChip(title: course.name, isSelected: true) {
                            viewModel.toggle(course)
                        }
                    }
                }
                .animation(
                    Motion.respecting(Motion.quick, reduceMotion: reduceMotion),
                    value: viewModel.selectedCourses
                )
            }

            SFTextField(
                label: L10n.profileAcademicAddCourse.string,
                text: $draftCourse,
                placeholder: L10n.profileAcademicAddCoursePlaceholder.string,
                submitLabel: .done,
                autocorrectionDisabled: false,
                onSubmit: { addDraftCourse() }
            )

            SFFieldFeedback(error: viewModel.coursesError, hint: nil)
        }
    }

    /// Adds the typed subject on Return and clears the field, ready for the next one.
    private func addDraftCourse() {
        viewModel.addCustomCourse(draftCourse)
        draftCourse = ""
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
    ProfileSetupAcademicView(
        profile: MockProfileService(latency: .zero),
        catalogue: SeededCourseCatalogueStore.starter
    ) { _ in }
}

#Preview("B01 Profile setup — save rejected") {
    // The state that matters most on this screen and the hardest to reach by hand: the
    // server refusing the write, which is what a field outside the allowlist produces.
    let profile = MockProfileService(latency: .zero)
    profile.forceFailure(.writeRejected(reference: "profile-write-denied"))

    return ProfileSetupAcademicView(
        profile: profile,
        catalogue: SeededCourseCatalogueStore.starter
    ) { _ in }
}

#Preview("B01 Profile setup — empty catalogue") {
    // Proves the screen degrades to an explanation instead of an empty row, which is the state a
    // catalogue store that has not answered leaves the step in (`AcademicCatalogue.empty`).
    ProfileSetupAcademicView(
        profile: MockProfileService(latency: .zero),
        catalogue: .empty
    ) { _ in }
}
