//
//  ProfileSetupStudyGoalsViewModel.swift
//  StudyForge
//
//  Presentation logic for B03 (`13_ProfileSetup_StudyGoals_{M1}`, docs/03 §B, P0) — the
//  wizard's last step.
//
//  WHY THIS STEP HAS A STARTING VALUE WHEN THE FIRST TWO DO NOT
//  -----------------------------------------------------------
//  B01 and B02 start empty because "nothing chosen yet" has to be distinguishable from a
//  choice the student made. A slider cannot be empty — it has a position from the moment it
//  is drawn — so the honest version is different: the starting position is shown on screen
//  with its value written out, and what gets saved is the number the student was looking at
//  when they pressed Finish. That is a visible default, not a silent one.
//
//  The target grade DOES start empty, and is validated on Finish, because a grade is a
//  choice rather than a position and has no honest default.
//

import Foundation

@MainActor
@Observable
final class ProfileSetupStudyGoalsViewModel {

    /// The slider's bounds.
    ///
    /// Forty hours is a full working week: beyond it the field stops being a study plan and
    /// becomes a data-entry error, and the rules deliberately do not range-check the value
    /// (they guard WHICH field is written, not what it says), so the bound belongs here.
    ///
    /// `nonisolated` because it is a constant rather than state: the view builds the slider
    /// from it and the tests read it, and neither should have to hop to the main actor to
    /// find out where the slider starts and ends.
    nonisolated static let hoursRange = 1...40

    /// Where the slider starts.
    ///
    /// Twelve, because that is the value docs/05 §3 documents for this field — the same
    /// discipline as the course catalogue: take the number from the repository rather than
    /// inventing one.
    nonisolated static let defaultHours = 12

    // MARK: Bound state

    var hours: Int

    /// `nil` until the student chooses. See the note above.
    var grade: TargetGrade?

    // MARK: Derived state

    private(set) var isSubmitting = false
    private(set) var error: AppError?
    private(set) var gradeError: String?

    private let profile: any ProfileService
    private let onSaved: (StudyGoals) -> Void

    init(profile: any ProfileService, onSaved: @escaping (StudyGoals) -> Void) {
        self.profile = profile
        self.onSaved = onSaved
        self.hours = Self.defaultHours
    }

    // MARK: Derived

    var stepLabel: String { ProfileSetupStep.studyGoals.label }

    /// The slider's readout, in the right plural form for the count — four keys in Arabic,
    /// two in English. See `WeekHoursReadout`.
    var hoursReadout: String { WeekHoursReadout.string(for: hours) }

    /// The grade options in scale order, highest first.
    var gradeOptions: [TargetGrade] { TargetGrade.allCases }

    var isSubmitEnabled: Bool { !isSubmitting }

    func isSelected(_ grade: TargetGrade) -> Bool { self.grade == grade }

    /// Segment title for a grade.
    ///
    /// From the type rather than the catalogue, because a grade letter is notation rather
    /// than prose — an Arabic transcript writes A, B, C, D too. See `TargetGrade`.
    func title(for grade: TargetGrade) -> String { grade.displayName }

    // MARK: Actions

    func select(_ grade: TargetGrade) {
        self.grade = grade
        gradeError = nil
    }

    func submit() async {
        guard !isSubmitting else { return }

        error = nil
        gradeError = nil

        guard let grade else {
            gradeError = L10n.profileStudyGoalsGradeError.string
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        // Both fields in one update: they answer one question, and a rejection that landed
        // half of them would leave a planner acting on a mismatched pair.
        let goals = StudyGoals(weeklyStudyGoalHours: hours, targetGrade: grade)

        do {
            try await profile.saveStudyGoals(goals)
            onSaved(goals)
        } catch {
            // Both answers stay on screen: neither is what the server objected to.
            self.error = AppError.from(error)
        }
    }
}
