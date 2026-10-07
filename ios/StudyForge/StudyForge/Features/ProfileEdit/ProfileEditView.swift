//
//  ProfileEditView.swift
//  StudyForge
//
//  B07 — `17_Profile_Edit_{M1}` (docs/03 §B, P1). Editable name and academic fields, Save and
//  Cancel in the navigation bar, and a warning before unsaved changes are lost.
//
//  WHY THE SYSTEM BACK BUTTON IS REPLACED BY CANCEL
//  -----------------------------------------------
//  The design puts Cancel in the nav bar, and the unsaved-change warning is the reason: a
//  swipe-back gesture cannot be intercepted, so a student who edited their programme and
//  swiped away would lose it without being asked. Hiding the back button and routing every
//  exit through Cancel makes one place responsible for that question.
//
//  THE AVATAR IS DEFERRED, AND SAYS SO
//  ----------------------------------
//  `avatarUrl` is in the write allowlist, but there is nowhere to PUT a photo: Cloud Storage
//  needs the Blaze plan and is deliberately bypassed (D24, docs/09 R21). So the screen shows a
//  monogram derived from the name and states plainly that a photo is still to come, rather
//  than offering a control that cannot work.
//

import SwiftUI

// Accessibility: each field is labelled (the university picker announces its value), the decorative glyphs
// are hidden, and the sections read as one element.

struct ProfileEditView: View {

    @State private var viewModel: ProfileEditViewModel
    @State private var isConfirmingDiscard = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The subject being typed into the add field: throwaway UI state, so it lives here
    /// rather than in the view model that owns the saved profile.
    @State private var draftCourse = ""

    init(container: AppContainer) {
        _viewModel = State(
            initialValue: ProfileEditViewModel(
                initialName: container.session?.displayName ?? "",
                // The academic half comes from the document the gate already read, so opening
                // the editor costs no extra round trip.
                initialAcademic: container.storedProfile?.academicProfile,
                auth: container.auth,
                profile: container.profile
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {

                avatar

                if let error = viewModel.error {
                    SFErrorBanner(error: error, onRecover: { Task { await save() } })
                }

                SFTextField(
                    label: L10n.profileEditName.string,
                    text: $viewModel.name,
                    hint: L10n.profileEditNameHint.string,
                    error: viewModel.nameError,
                    submitLabel: .next,
                    // A person's name is a proper noun, so capitalisation is right here where
                    // it is wrong for an email address.
                    autocapitalization: .words,
                    autocorrectionDisabled: false,
                    onSubmit: {}
                )

                academicFields
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(ColorTokens.surface)
        .navigationTitle(L10n.profileEditTitle.string)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.commonCancel.string) { cancel() }
                    .disabled(viewModel.isSaving)
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(
                    viewModel.isSaving ? L10n.profileEditSaving.string : L10n.profileEditSave.string
                ) {
                    Task { await save() }
                }
                .disabled(!viewModel.isSaveEnabled)
            }
        }
        .confirmationDialog(
            L10n.profileEditDiscardTitle.string,
            isPresented: $isConfirmingDiscard,
            titleVisibility: .visible
        ) {
            Button(L10n.profileEditDiscard.string, role: .destructive) { dismiss() }
            Button(L10n.profileEditKeepEditing.string, role: .cancel) {}
        } message: {
            Text(L10n.profileEditDiscardMessage.string)
        }
    }

    // MARK: Sections

    private var avatar: some View {
        HStack(spacing: Spacing.s4) {

            SFMonogram(name: viewModel.name)

            Text(L10n.profileEditAvatarNote.string)
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        // One statement, because the monogram IS the name's initials — announcing both would
        // read the name twice.
        .accessibilityElement(children: .combine)
    }

    private var academicFields: some View {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            universityField
            majorField
            yearField
            coursesField
        }
    }

    /// A `Menu` rather than a `Picker`, for the reason B01 documents: a menu makes the whole row
    /// the control, so the field is tappable and its chrome matches the text fields beside it.
    /// A free-text field with the known institutions as quick-picks, not a closed menu: a global
    /// product cannot enumerate every university, so the list can only suggest. What the student
    /// types is what is stored.
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

            if !viewModel.universityOptions.isEmpty {
                SFChipFlow {
                    ForEach(viewModel.universityOptions, id: \.self) { name in
                        SFChoiceChip(title: name, isSelected: viewModel.university == name) {
                            viewModel.university = name
                            viewModel.didEdit(.university)
                        }
                    }
                }
            }
        }
    }

    /// `university` is optional: nil means "nothing chosen", while a text field needs a plain
    /// `String`, so an all-whitespace value round-trips back to nil.
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
            // "Year of study, 3" survives AX5 where four spelled-out labels would truncate.
            title: { String($0) },
            error: viewModel.yearError
        )
    }

    private var coursesField: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {

            fieldLabel(L10n.profileAcademicCourses.string)

            SFChipFlow {
                ForEach(viewModel.courseOptions) { course in
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
                value: viewModel.selectedCourseIds
            )

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

    /// The caption above a control, hidden from VoiceOver because the control carries the same
    /// string as its own accessibility label — otherwise the caption is read out and then the
    /// control reads itself.
    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.sfSubhead)
            .foregroundStyle(ColorTokens.textSecondary)
            .accessibilityHidden(true)
    }

    // MARK: Actions

    private func cancel() {
        // The one place that decides whether leaving needs a confirmation. Without unsaved
        // changes the question would be noise, so it is not asked.
        if viewModel.hasUnsavedChanges {
            isConfirmingDiscard = true
        } else {
            dismiss()
        }
    }

    private func save() async {
        await viewModel.save()
        // Leaving is the view's decision; the view model only reports that the write landed.
        if viewModel.didSave { dismiss() }
    }
}

// MARK: - Previews

#Preview("B07 Edit profile") {
    NavigationStack {
        ProfileEditView(
            container: .previewing(
                session: UserSession(
                    id: "uid_preview",
                    displayName: "Sara Ali",
                    role: .student,
                    plan: .free,
                    groupIds: [],
                    email: "sara@studyforge.test",
                    isEmailVerified: true
                )
            )
        )
    }
}
