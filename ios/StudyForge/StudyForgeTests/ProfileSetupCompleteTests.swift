//
//  ProfileSetupCompleteTests.swift
//  StudyForgeTests
//
//  Tests for B04, the wizard's confirmation screen.
//
//  What is being pinned is that the summary states exactly what the wizard collected and
//  nothing else: one line per answer that exists, nothing invented for an answer that does
//  not, course ids resolved back to names through the same catalogue B01 offered, and the
//  hours readout identical to the one B03's slider showed.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Profile setup — confirmation (B04)")
@MainActor
struct ProfileSetupCompleteTests {

    private func fullAnswers() -> ProfileSetupAnswers {
        ProfileSetupAnswers(
            academic: AcademicProfile(
                university: "Bahrain Polytechnic",
                major: "Programming",
                year: 2,
                courseIds: ["IT8108", "c_104"]
            ),
            learningStyle: .readWrite,
            studyGoals: StudyGoals(weeklyStudyGoalHours: 12, targetGrade: .a)
        )
    }

    @Test("Every answer is summarised, in the order the wizard asked for it")
    func summarisesEveryAnswer() {
        let viewModel = ProfileSetupCompleteViewModel(answers: fullAnswers())

        #expect(viewModel.rows.map(\.id) == [
            "university", "major", "year", "courses", "learningStyle", "hours", "grade",
        ])
        #expect(viewModel.rows.map(\.value) == [
            "Bahrain Polytechnic",
            "Programming",
            "2",
            "IT8108, Data Structures",
            LearningStyleName.string(for: .readWrite),
            WeekHoursReadout.string(for: 12),
            "A",
        ])
        #expect(viewModel.hasRows)
    }

    @Test("Course ids are resolved to names through the catalogue")
    func courseIdsBecomeNames() {
        let viewModel = ProfileSetupCompleteViewModel(answers: fullAnswers())

        #expect(viewModel.rows.first { $0.id == "courses" }?.value == "IT8108, Data Structures")
    }

    @Test("An id that is not in the catalogue is shown as the id, never a guessed name")
    func unknownCourseIdFallsBackToTheId() {
        // The catalogue is placeholder data in F01 and C01 replaces it; an id the catalogue
        // does not know must degrade to the code rather than to a fabricated course name.
        let answers = ProfileSetupAnswers(
            academic: AcademicProfile(
                university: "University of Bahrain",
                major: "Physics",
                year: 1,
                courseIds: ["c_999"]
            )
        )

        let viewModel = ProfileSetupCompleteViewModel(answers: answers)

        #expect(viewModel.rows.first { $0.id == "courses" }?.value == "c_999")
    }

    @Test("A partway wizard summarises only what it has")
    func missingAnswersAreOmitted() {
        // What `-profileSetupStep 3` produces: goals only. The screen states the goals and
        // stays silent about the steps that were never shown.
        let viewModel = ProfileSetupCompleteViewModel(
            answers: ProfileSetupAnswers(
                studyGoals: StudyGoals(weeklyStudyGoalHours: 3, targetGrade: .b)
            )
        )

        #expect(viewModel.rows.map(\.id) == ["hours", "grade"])
    }

    @Test("No answers at all is an empty summary, not a blank row")
    func noAnswersMeansNoRows() {
        let viewModel = ProfileSetupCompleteViewModel(answers: .empty)

        #expect(viewModel.rows.isEmpty)
        #expect(viewModel.hasRows == false)
    }

    @Test("The hours line uses the same plural readout as the slider it came from")
    func hoursReuseTheReadout() {
        let viewModel = ProfileSetupCompleteViewModel(
            answers: ProfileSetupAnswers(
                studyGoals: StudyGoals(weeklyStudyGoalHours: 2, targetGrade: .b)
            )
        )

        #expect(viewModel.rows.first { $0.id == "hours" }?.value == WeekHoursReadout.string(for: 2))
    }

    @Test("The grade line is the stored letter, which is notation and not translated")
    func gradeIsTheStoredLetter() {
        let viewModel = ProfileSetupCompleteViewModel(
            answers: ProfileSetupAnswers(
                studyGoals: StudyGoals(weeklyStudyGoalHours: 6, targetGrade: .c)
            )
        )

        #expect(viewModel.rows.first { $0.id == "grade" }?.value == "C")
    }

    @Test("Screen copy comes from the catalogue rather than being hard-coded")
    func copyIsLocalised() {
        let viewModel = ProfileSetupCompleteViewModel(answers: .empty)

        #expect(viewModel.title == L10n.profileCompleteTitle.string)
        #expect(viewModel.subtitle == L10n.profileCompleteSubtitle.string)
        #expect(viewModel.summaryHeading == L10n.profileCompleteSummaryHeading.string)
        #expect(viewModel.goToDashboardTitle == L10n.profileCompleteGoToDashboard.string)
    }
}
