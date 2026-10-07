//
//  ProfileEditViewModel.swift
//  StudyForge
//
//  Presentation logic for B07 (`17_Profile_Edit_{M1}`, docs/03 §B, P1) — editing the name and
//  the academic fields of an EXISTING profile.
//
//  WHY THIS IS NOT B01's VIEW MODEL REUSED
//  --------------------------------------
//  The two screens share a field SET and that is all. Both now accept values the catalogue
//  does not know, because a global app cannot enumerate every institution or course. The
//  catalogue is a set of quick-picks, not a boundary: a student types their own, and its
//  name is its id. An EDIT screen additionally has to SHOW values already stored: a real
//  institution, a real course id, which is why `universityOptions` and `courseOptions`
//  below can contain values the catalogue lacks, and why a save keeps them instead of
//  quietly replacing them with the catalogue's contents.
//
//  WHY IT TRACKS THE ORIGINAL VALUES
//  --------------------------------
//  Two behaviours depend on them: the unsaved-change warning (a comparison against what the
//  screen opened with, not against "is the form valid"), and the save, which writes only the
//  parts that actually changed — a rename should not rewrite the academic document, and vice
//  versa.
//

import Foundation

@MainActor
@Observable
final class ProfileEditViewModel {

    /// Which control a validation message belongs under.
    enum Field: Hashable {
        case name
        case university
        case major
        case year
        case courses
    }

    // MARK: Bound state

    var name: String
    var university: String?
    var major: String
    var year: Int?
    var selectedCourseIds: Set<String>

    // MARK: Derived state

    private(set) var isSaving = false
    private(set) var error: AppError?
    private(set) var fieldErrors: [Field: String] = [:]

    /// Set once a save succeeds. The view dismisses on it, which keeps the decision to leave
    /// the screen out of the view model.
    private(set) var didSave = false

    let catalogue: AcademicCatalogue

    // MARK: What the screen opened with

    private let initialName: String
    private let initialAcademicProfile: AcademicProfile?

    private let auth: any AuthService
    private let profile: any ProfileService

    init(
        initialName: String,
        initialAcademic: AcademicProfile?,
        catalogue: AcademicCatalogue = SeededCourseCatalogueStore.starter,
        auth: any AuthService,
        profile: any ProfileService
    ) {
        // Trimmed on the way in, so a name that only differs by whitespace does not read as an
        // unsaved change the moment the screen opens.
        self.name = initialName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.university = initialAcademic?.university
        self.major = initialAcademic?.major ?? ""
        self.year = initialAcademic?.year
        self.selectedCourseIds = Set(initialAcademic?.courseIds ?? [])

        self.initialName = initialName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.initialAcademicProfile = initialAcademic

        self.catalogue = catalogue
        self.auth = auth
        self.profile = profile
    }

    // MARK: Live feedback

    var nameError: String? { fieldErrors[.name] }
    var universityError: String? { fieldErrors[.university] }
    var majorError: String? { fieldErrors[.major] }
    var yearError: String? { fieldErrors[.year] }
    var coursesError: String? { fieldErrors[.courses] }

    /// Institutions to offer: the catalogue, plus the stored one when the catalogue does not
    /// carry it. Without that, a student whose institution is not in the placeholder list
    /// would find it missing from the menu — and saving would silently replace it.
    var universityOptions: [String] {
        guard let university, !catalogue.universities.contains(university) else {
            return catalogue.universities
        }
        return [university] + catalogue.universities
    }

    /// Courses to draw as chips: the catalogue, plus any selected id it does not know, shown
    /// by its id. A stored course must never be invisible — a student cannot remove what they
    /// cannot see, and the save would then keep it forever.
    var courseOptions: [CourseOption] {
        let knownIds = Set(catalogue.courses.map(\.id))
        let unknown = selectedCourseIds
            .subtracting(knownIds)
            .sorted()
            .map { CourseOption(id: $0, name: $0) }
        return catalogue.courses + unknown
    }

    /// Whether the form differs from what it opened with.
    var hasUnsavedChanges: Bool {
        trimmedName != initialName
            || university != initialAcademicProfile?.university
            || trimmedMajor != (initialAcademicProfile?.major ?? "")
            || year != initialAcademicProfile?.year
            || selectedCourseIds != Set(initialAcademicProfile?.courseIds ?? [])
    }

    /// Save is offered only when there is something to save, which makes the button itself the
    /// answer to "have I changed anything?" — cheaper to read than a warning.
    var isSaveEnabled: Bool { !isSaving && hasUnsavedChanges }

    func isSelected(_ course: CourseOption) -> Bool {
        selectedCourseIds.contains(course.id)
    }

    // MARK: Actions

    /// Clears a field's message as soon as it is edited, so the message does not outlive the
    /// mistake. Only that field — the others may still be wrong.
    func didEdit(_ field: Field) {
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

    /// Adds a subject the catalogue does not know: the same self-description B01 offers, so
    /// an edit screen is not a more limited place than the wizard that created the profile.
    /// The typed name IS the stored id; a name matching a known course selects it instead.
    func addCustomCourse(_ raw: String) {
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        if let known = catalogue.courses.first(where: {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }) {
            selectedCourseIds.insert(known.id)
        } else {
            selectedCourseIds.insert(name)
        }
        didEdit(.courses)
    }

    func save() async {
        guard !isSaving else { return }

        error = nil
        fieldErrors = [:]

        guard let draft = validatedAcademicProfile() else { return }

        isSaving = true
        defer { isSaving = false }

        do {
            // Only what changed. A write for nothing is more than wasteful here: the name
            // write has a side effect — it re-issues auth state — so sending it on every save
            // would churn the session of a student who only corrected their major.
            if trimmedName != initialName {
                try await auth.updateDisplayName(trimmedName)
            }
            if draft != initialAcademicProfile {
                try await profile.saveAcademicProfile(draft)
            }
            didSave = true
        } catch {
            // The typed values stay: the student's input is not what went wrong, and clearing
            // the form on a network failure would be its own bug report.
            self.error = AppError.from(error)
        }
    }

    // MARK: Validation

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedMajor: String { major.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Validates everything and returns the write to perform, or `nil` after filling in
    /// `fieldErrors`. Every problem is collected rather than returning at the first — the same
    /// reasoning as B01: a form that reports one fault per tap is discovered by iteration.
    ///
    /// The academic fields are required even when only the name is being changed. Deliberate:
    /// B07 is the student's chance to finish a profile the wizard left part-built, and letting a
    /// blank one through would store a document the gate calls incomplete.
    private func validatedAcademicProfile() -> AcademicProfile? {
        var problems: [Field: String] = [:]

        if trimmedName.isEmpty {
            problems[.name] = L10n.profileEditNameError.string
        }

        let chosenUniversity = university?.trimmingCharacters(in: .whitespacesAndNewlines)
        if chosenUniversity?.isEmpty != false {
            problems[.university] = L10n.profileAcademicErrorUniversity.string
        }

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

        // Catalogue order first — so two students picking the same courses produce the same
        // array and the write is idempotent — then any stored id the catalogue does not know,
        // kept rather than dropped.
        let known = catalogue.courses.map(\.id).filter { selectedCourseIds.contains($0) }
        let unknown = selectedCourseIds.subtracting(known).sorted()

        return AcademicProfile(
            university: chosenUniversity,
            major: trimmedMajor,
            year: year,
            courseIds: known + unknown
        )
    }
}
