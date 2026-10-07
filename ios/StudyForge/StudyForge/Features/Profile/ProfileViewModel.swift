//
//  ProfileViewModel.swift
//  StudyForge
//
//  Presentation logic for B06 (`16_Profile_View_{M1}`, docs/03 §B, P1) — the student's own
//  profile, read back.
//
//  WHY NOTHING IS FETCHED
//  ---------------------
//  Everything shown is already in hand: the name and the account address from the session, and
//  the academic fields and study plan from the document the gate read
//  (`AppContainer.storedProfile`). Opening the profile therefore costs no round trip — which
//  matters for a screen a student taps into casually.
//
//  WHAT THE DESIGN DRAWS THAT THIS DOES NOT SHOW
//  --------------------------------------------
//  docs/03 §B lists a stat row (mastery %, streak) and a badge strip. Neither has a source:
//  mastery and streaks are gamification values a Cloud Function owns, and this project has no
//  Cloud Functions (D22). Rather than draw a row of invented zeros, the screen shows the one
//  statistic that IS real — the weekly study time from B03 — and states plainly that progress
//  and badges are still to come. Recorded here and in docs/03 §B rather than left as an
//  omission.
//

import Foundation

@MainActor
@Observable
final class ProfileViewModel {

    /// The name, trimmed. Empty only when there is no session, which the screen cannot be
    /// reached without.
    let name: String

    /// The address the account was registered with. Shown because a student recognises their
    /// own email and it identifies the account; an institutional student number is not
    /// collected yet (it arrives with enrolment — F02/C01).
    let email: String

    let studyRows: [DetailRow]
    let planRows: [DetailRow]

    var hasStudyRows: Bool { !studyRows.isEmpty }
    var hasPlanRows: Bool { !planRows.isEmpty }

    init(
        session: UserSession?,
        stored: StoredProfile?,
        catalogue: AcademicCatalogue = SeededCourseCatalogueStore.starter
    ) {
        self.name = (session?.displayName ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        self.email = session?.email ?? ""

        // Absent when the wizard has not been finished. Reached only via a failed gate read, so
        // the sections are omitted rather than shown empty — the same judgement B04 makes about
        // answers the wizard never collected.
        if let academic = stored?.academicProfile {
            studyRows = [
                DetailRow(
                    id: "university",
                    label: L10n.profileCompleteUniversity.string,
                    value: academic.university
                ),
                DetailRow(
                    id: "major",
                    label: L10n.profileCompleteMajor.string,
                    value: academic.major
                ),
                DetailRow(
                    id: "year",
                    label: L10n.profileCompleteYear.string,
                    value: String(academic.year)
                ),
                DetailRow(
                    id: "courses",
                    label: L10n.profileCompleteCourses.string,
                    // Resolved through the catalogue, so this screen and B04 cannot disagree
                    // about how an unknown id is shown.
                    value: catalogue.courseNames(for: academic.courseIds)
                ),
            ]
        } else {
            studyRows = []
        }

        if let goals = stored?.studyGoals {
            planRows = [
                DetailRow(
                    id: "hours",
                    label: L10n.profileCompleteHours.string,
                    value: WeekHoursReadout.string(for: goals.weeklyStudyGoalHours)
                ),
                DetailRow(
                    id: "grade",
                    label: L10n.profileCompleteGrade.string,
                    value: goals.targetGrade.displayName
                ),
            ]
        } else {
            planRows = []
        }
    }

    // MARK: Copy

    var title: String { L10n.profileViewTitle.string }
    var studiesHeading: String { L10n.profileViewStudiesHeading.string }
    var planHeading: String { L10n.profileViewPlanHeading.string }
    var progressTitle: String { L10n.profileViewProgressTitle.string }
    var progressBody: String { L10n.profileViewProgressBody.string }

    /// Reused from B07: the shortcut and the screen it opens are the same thing, so they share
    /// one string rather than one of them drifting.
    var editTitle: String { L10n.profileEditTitle.string }
}
