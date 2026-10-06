//
//  ProfileSetupAcademicViewModel.swift
//  StudyForge
//
//  Presentation logic for B01 (`11_ProfileSetup_Academic_{M1}`, docs/03 §B, P0) — the
//  first step of the profile wizard.
//
//  WHY EVERY PROBLEM IS REPORTED AT ONCE
//  ------------------------------------
//  A wizard step that reports one missing field per tap makes the student discover the
//  form by iteration. `submit()` validates everything and returns the whole set, so the
//  four fields are corrected in one pass.
//
//  WHY IT DOES NOT NAVIGATE
//  ------------------------
//  On success this calls `onSaved` and stops. Where the student goes next is a routing
//  decision — B02/B03 follow, and B04 is the completion screen — and a screen that both
//  saves and decides its own successor is the reason navigation becomes untestable.
//  Same split as A06, which refreshes the session and lets `RootView` route.
//
//  WHY THE FORM IS THE SOURCE OF THE WRITE
//  --------------------------------------
//  The profile built here contains exactly the fields in `ProfileField` — see that file for
//  why the names live in one shared list rather than next to this screen. That is
//  not tidiness: the server's allowlist rejects the WHOLE update if it carries anything
//  else, so a field added "for later" would break saving entirely rather than be ignored.
//

import Foundation

@MainActor
@Observable
final class ProfileSetupAcademicViewModel {

    /// Which control a validation message belongs under.
    enum Field: Hashable {
        case university
        case major
        case year
        case courses
    }

    /// B01 is step one of three: academic (B01) → learning style (B02) → study goals (B03).
    /// B04 is the completion screen, not a step. The numbering itself lives in
    /// `ProfileSetupStep`, so every step reports its position from one place.
    // MARK: Bound state

    /// `nil` means "nothing chosen yet", which is a different state from any real choice.
    /// Defaulting to the first university would make an untouched form look complete and
    /// would save a value the student never picked.
    var university: String?

    var major = ""

    var year: Int?

    /// Course ids rather than `CourseOption`s, because the id is what is stored and a
    /// reference to a catalogue entry would not survive the catalogue being replaced by
    /// the real one in F02.
    var selectedCourseIds: Set<String> = []

    // MARK: Derived state

    private(set) var isSubmitting = false
    private(set) var error: AppError?
    private(set) var fieldErrors: [Field: String] = [:]

    /// What the pickers choose from. Injected so tests can use a two-course catalogue and
    /// so C01 can supply the real one without touching this type.
    let catalogue: AcademicCatalogue

    private let profile: any ProfileService
    private let onSaved: (AcademicProfile) -> Void

    init(
        profile: any ProfileService,
        catalogue: AcademicCatalogue = .placeholder,
        onSaved: @escaping (AcademicProfile) -> Void
    ) {
        self.profile = profile
        self.catalogue = catalogue
        self.onSaved = onSaved
    }

    // MARK: Live feedback

    var universityError: String? { fieldErrors[.university] }
    var majorError: String? { fieldErrors[.major] }
    var yearError: String? { fieldErrors[.year] }
    var coursesError: String? { fieldErrors[.courses] }

    /// The wizard position. The numbering lives in `ProfileSetupStep`, shared with B02 —
    /// see that file for why the total is the design's 3 rather than the number of steps
    /// built so far.
    var stepLabel: String { ProfileSetupStep.academic.label }

    /// Selected courses in CATALOGUE order, not selection order.
    ///
    /// Two students who picked the same courses must produce the same array, or the write
    /// is not idempotent and every read has to sort before comparing. The chips are drawn
    /// from this, so the display and the stored value agree as well.
    var selectedCourses: [CourseOption] {
        catalogue.courses.filter { selectedCourseIds.contains($0.id) }
    }

    var isSubmitEnabled: Bool { !isSubmitting }

    func isSelected(_ course: CourseOption) -> Bool {
        selectedCourseIds.contains(course.id)
    }

    // MARK: Actions

    /// Clears a field's error as soon as the student edits it, so the message does not
    /// outlive the mistake. Only that field — the others may still be wrong.
    func didEdit(_ field: Field) {
        guard fieldErrors[field] != nil else { return }
        fieldErrors[field] = nil
    }

    func toggle(_ course: CourseOption) {
        if selectedCourseIds.contains(course.id) {
            selectedCourseIds.remove(course.id)
        } else {
            selectedCourseIds.insert(course.id)
        }
        didEdit(.courses)
    }

    func submit() async {
        // Guards a second tap while the first is still in flight. The button is disabled
        // too, but a screen that relies only on that is one state update away from a
        // double write.
        guard !isSubmitting else { return }

        error = nil
        fieldErrors = [:]

        guard let draft = validatedProfile() else { return }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await profile.saveAcademicProfile(draft)
            onSaved(draft)
        } catch {
            // The typed values stay in place: the student's input is not the problem, and
            // clearing the form on a network failure would be its own bug report.
            self.error = AppError.from(error)
        }
    }

    // MARK: Validation

    /// Validates everything and returns the write to perform, or `nil` after filling in
    /// `fieldErrors`. Every problem is collected rather than returning at the first one —
    /// see the note at the top of this file.
    private func validatedProfile() -> AcademicProfile? {
        var problems: [Field: String] = [:]

        let chosenUniversity = university?.trimmingCharacters(in: .whitespacesAndNewlines)
        if chosenUniversity?.isEmpty != false {
            problems[.university] = L10n.profileAcademicErrorUniversity.string
        }

        let trimmedMajor = major.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedMajor.isEmpty {
            problems[.major] = L10n.profileAcademicErrorMajor.string
        }

        if year == nil {
            problems[.year] = L10n.profileAcademicErrorYear.string
        }

        if selectedCourseIds.isEmpty {
            problems[.courses] = L10n.profileAcademicErrorCourses.string
        }

        guard problems.isEmpty, let chosenUniversity, let year else {
            fieldErrors = problems
            return nil
        }

        return AcademicProfile(
            university: chosenUniversity,
            major: trimmedMajor,
            year: year,
            courseIds: selectedCourses.map(\.id)
        )
    }
}
