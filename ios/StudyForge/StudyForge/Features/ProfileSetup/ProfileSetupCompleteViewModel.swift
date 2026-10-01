//
//  ProfileSetupCompleteViewModel.swift
//  StudyForge
//
//  Presentation logic for B04 (`14_ProfileSetup_Complete_{M1}`, docs/03 §B, P1) — the
//  wizard's confirmation screen.
//
//  WHAT IT IS FOR
//  --------------
//  The screen's job is to prove the app heard the student, so it builds one summary line per
//  answer the wizard actually collected — nothing more and nothing invented. A line whose
//  answer is missing (a wizard opened partway through) is simply not built, which is why
//  every field of `ProfileSetupAnswers` is optional.
//
//  WHY COURSE NAMES COME THROUGH THE CATALOGUE
//  ------------------------------------------
//  `AcademicProfile` stores course IDS, not names: the id is the durable key and the name is
//  institutional, so a rename must never orphan a student's material. To SHOW the choice the
//  id has to be resolved back through the same catalogue B01 offered. When an id is not in
//  the catalogue the id itself is shown — a code is honest, a guessed name is not, and it is
//  the same convention docs/03 §B already uses where a course has no known title.
//

import Foundation

@MainActor
@Observable
final class ProfileSetupCompleteViewModel {

    /// One line of the summary.
    struct Row: Identifiable, Equatable, Sendable {

        /// Stable identity derived from the field rather than the position, so the list does
        /// not re-animate when an unrelated row appears or disappears.
        let id: String

        let label: String
        let value: String
    }

    /// The lines, in the order the wizard asked the questions.
    let rows: [Row]

    init(answers: ProfileSetupAnswers, catalogue: AcademicCatalogue = .placeholder) {
        var rows: [Row] = []

        if let academic = answers.academic {
            rows.append(Row(
                id: "university",
                label: L10n.profileCompleteUniversity.string,
                value: academic.university
            ))
            rows.append(Row(
                id: "major",
                label: L10n.profileCompleteMajor.string,
                value: academic.major
            ))
            rows.append(Row(
                id: "year",
                label: L10n.profileCompleteYear.string,
                value: String(academic.year)
            ))
            // Shown even when the list is empty: "no courses chosen" is itself something a
            // student would want to correct, and silently dropping the row would hide it.
            // B01 requires at least one course, so the empty case only appears via the DEBUG
            // step hatch — but it is handled rather than asserted away.
            rows.append(Row(
                id: "courses",
                label: L10n.profileCompleteCourses.string,
                value: Self.courseNames(academic.courseIds, in: catalogue)
            ))
        }

        if let style = answers.learningStyle {
            rows.append(Row(
                id: "learningStyle",
                label: L10n.profileCompleteLearningStyle.string,
                value: LearningStyleName.string(for: style)
            ))
        }

        if let goals = answers.studyGoals {
            rows.append(Row(
                id: "hours",
                label: L10n.profileCompleteHours.string,
                // The SAME readout B03's slider shows, including the Arabic plural form —
                // the summary must not read back a different number from the one the student
                // set.
                value: WeekHoursReadout.string(for: goals.weeklyStudyGoalHours)
            ))
            rows.append(Row(
                id: "grade",
                label: L10n.profileCompleteGrade.string,
                // A grade letter is notation, not prose, so it comes from the type rather
                // than the catalogue — exactly as on B03.
                value: goals.targetGrade.displayName
            ))
        }

        self.rows = rows
    }

    // MARK: Derived

    /// Whether there is anything to summarise. False only when the screen is reached with no
    /// answers at all, which the view uses to omit an empty card rather than draw a heading
    /// over nothing.
    var hasRows: Bool { !rows.isEmpty }

    var title: String { L10n.profileCompleteTitle.string }
    var subtitle: String { L10n.profileCompleteSubtitle.string }
    var summaryHeading: String { L10n.profileCompleteSummaryHeading.string }
    var goToDashboardTitle: String { L10n.profileCompleteGoToDashboard.string }

    // MARK: Helpers

    /// Course names for the stored ids, in the order B01 wrote them (catalogue order).
    ///
    /// A missing id falls back to the id — see the note at the top of the file.
    private static func courseNames(_ ids: [String], in catalogue: AcademicCatalogue) -> String {
        ids
            .map { catalogue.course(for: $0)?.name ?? $0 }
            .joined(separator: ", ")
    }
}
