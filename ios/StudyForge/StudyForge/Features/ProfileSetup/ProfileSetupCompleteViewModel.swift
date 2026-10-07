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
//  id has to be resolved back through the same catalogue B01 offered —
//  `AcademicCatalogue.courseNames(for:)`, so this screen and B06's profile view cannot resolve
//  the same ids two different ways. When an id is not in the catalogue the id itself is shown:
//  a code is honest, a guessed name is not, and it is the same convention docs/03 §B already
//  uses where a course has no known title.
//

import Foundation

@MainActor
@Observable
final class ProfileSetupCompleteViewModel {

    /// The lines, in the order the wizard asked the questions.
    ///
    /// `DetailRow` rather than a type of this file's own: B06's profile view draws the same
    /// label/value lines, and two private `Row` structs that were meant to be identical is
    /// exactly the drift `SFDetailRow` exists to prevent.
    let rows: [DetailRow]

    init(answers: ProfileSetupAnswers, catalogue: AcademicCatalogue = SeededCourseCatalogueStore.starter) {
        var rows: [DetailRow] = []

        if let academic = answers.academic {
            rows.append(DetailRow(
                id: "university",
                label: L10n.profileCompleteUniversity.string,
                value: academic.university
            ))
            rows.append(DetailRow(
                id: "major",
                label: L10n.profileCompleteMajor.string,
                value: academic.major
            ))
            rows.append(DetailRow(
                id: "year",
                label: L10n.profileCompleteYear.string,
                value: String(academic.year)
            ))
            // Shown even when the list is empty: "no courses chosen" is itself something a
            // student would want to correct, and silently dropping the row would hide it.
            // B01 requires at least one course, so the empty case only appears via the DEBUG
            // step hatch — but it is handled rather than asserted away.
            rows.append(DetailRow(
                id: "courses",
                label: L10n.profileCompleteCourses.string,
                value: catalogue.courseNames(for: academic.courseIds)
            ))
        }

        if let style = answers.learningStyle {
            rows.append(DetailRow(
                id: "learningStyle",
                label: L10n.profileCompleteLearningStyle.string,
                value: LearningStyleName.string(for: style)
            ))
        }

        if let goals = answers.studyGoals {
            rows.append(DetailRow(
                id: "hours",
                label: L10n.profileCompleteHours.string,
                // The SAME readout B03's slider shows, including the Arabic plural form —
                // the summary must not read back a different number from the one the student
                // set.
                value: WeekHoursReadout.string(for: goals.weeklyStudyGoalHours)
            ))
            rows.append(DetailRow(
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
}
