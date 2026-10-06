//
//  CourseEditorViewModel.swift
//  StudyForge
//
//  F11 — presentation logic for J03 (`101_Tutor_Course_Create_Edit_{M2}`).
//
//  WHY CREATE AND EDIT ARE ONE SCREEN
//  ----------------------------------
//  The design draws them as one frame too: the same fields, with the same validation, differing
//  only in whether there is an existing document behind them. Two screens would mean two chances
//  for the validation to disagree about what a valid course code is.
//
//  WHY SAVING CANNOT HALF-SUCCEED
//  ------------------------------
//  The draft fields are validated first and assembled into a `Course` in one step, so the store
//  is asked either to write a complete course or not to write at all. A course with a name and
//  no code is a row the roster screen cannot label.
//

import Foundation

@MainActor
@Observable
final class CourseEditorViewModel {

    // MARK: Bound state

    var name: String
    var code: String
    var termStart: Date
    var termEnd: Date
    var enrolmentMode: EnrolmentMode
    var colourIndex: Int

    private(set) var isSaving = false
    private(set) var error: AppError?

    private let uid: String
    private let store: any CourseStore
    private let existing: Course?

    init(uid: String, store: any CourseStore, existing: Course? = nil) {
        self.uid = uid
        self.store = store
        self.existing = existing

        self.name = existing?.name ?? ""
        self.code = existing?.code ?? ""
        self.termStart = existing?.termStart ?? .now
        self.termEnd = existing?.termEnd ?? Date.now.addingTimeInterval(60 * 60 * 24 * 120)
        self.enrolmentMode = existing?.enrolmentMode ?? .code
        self.colourIndex = existing?.colourIndex ?? 0
    }

    // MARK: Derived

    var isEditing: Bool { existing != nil }

    /// The trimmed values actually written, so trailing spaces never reach a document.
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedCode: String { code.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Why the form cannot be saved, or `nil` when it can.
    ///
    /// Returned as a message rather than used to disable the button silently, because a disabled
    /// Save with no explanation is the single most common dead end in a form.
    var validationMessage: String? {
        if trimmedName.isEmpty { return L10n.tutorNameRequired.string }
        if trimmedCode.isEmpty { return L10n.tutorCodeRequired.string }
        return nil
    }

    var canSave: Bool { validationMessage == nil }

    // MARK: Copy

    var title: String {
        isEditing ? L10n.tutorEditCourse.string : L10n.tutorNewCourse.string
    }

    var saveTitle: String { L10n.tutorSave.string }
    var savingTitle: String { L10n.tutorSaving.string }
    var nameLabel: String { L10n.tutorCourseNameLabel.string }
    var namePlaceholder: String { L10n.tutorCourseNamePlaceholder.string }
    var codeLabel: String { L10n.tutorCourseCodeLabel.string }
    var codePlaceholder: String { L10n.tutorCourseCodePlaceholder.string }
    var termStartLabel: String { L10n.tutorTermStartLabel.string }
    var termEndLabel: String { L10n.tutorTermEndLabel.string }
    var coverColourTitle: String { L10n.tutorCoverColour.string }
    var enrolmentLabel: String { L10n.tutorEnrolmentModeLabel.string }

    var modes: [EnrolmentMode] { EnrolmentMode.allCases }

    func modeName(_ mode: EnrolmentMode) -> String {
        switch mode {
        case .open: L10n.tutorEnrolmentOpen.string
        case .code: L10n.tutorEnrolmentCode.string
        case .approval: L10n.tutorEnrolmentApproval.string
        }
    }

    // MARK: Actions

    /// Writes the course. Returns whether it succeeded, so the view knows whether to pop.
    func save() async -> Bool {
        guard canSave, !isSaving else { return false }

        isSaving = true
        defer { isSaving = false }
        error = nil

        do {
            try await store.upsert(draftCourse())
            return true
        } catch {
            self.error = AppError.from(error)
            return false
        }
    }

    /// Assembles the course to write — an edited copy of the existing one, or a new one.
    private func draftCourse() -> Course {
        if var course = existing {
            course.name = trimmedName
            course.code = trimmedCode
            course.termStart = termStart
            course.termEnd = termEnd
            course.enrolmentMode = enrolmentMode
            course.colourIndex = colourIndex
            course.updatedAt = .now
            return course
        }

        return Course(
            name: trimmedName,
            code: trimmedCode,
            tutorUid: uid,
            termStart: termStart,
            termEnd: termEnd,
            enrolmentMode: enrolmentMode,
            colourIndex: colourIndex
        )
    }
}
