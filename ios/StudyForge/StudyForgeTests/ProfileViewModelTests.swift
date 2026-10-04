//
//  ProfileViewModelTests.swift
//  StudyForgeTests
//
//  Tests for B06, the profile view.
//
//  The screen is a READ, so what matters is that it shows what is stored and stays silent about
//  what is not: a profile reached with no document must omit its sections rather than invent
//  rows, and a course the catalogue does not know must be shown by its id rather than replaced.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Profile view (B06)")
@MainActor
struct ProfileViewModelTests {

    private func session(
        name: String = "Sara Ali",
        email: String = "sara@studyforge.test"
    ) -> UserSession {
        UserSession(
            id: "uid_test",
            displayName: name,
            role: .student,
            plan: .free,
            groupIds: [],
            email: email,
            isEmailVerified: true
        )
    }

    @Test("The header carries the name and the account address")
    func headerComesFromTheSession() {
        let viewModel = ProfileViewModel(session: session(), stored: .preview)

        #expect(viewModel.name == "Sara Ali")
        #expect(viewModel.email == "sara@studyforge.test")
    }

    @Test("The study section reads the document back, with courses resolved to names")
    func studySectionReadsTheDocument() {
        let viewModel = ProfileViewModel(session: session(), stored: .preview)

        #expect(viewModel.studyRows.map(\.id) == ["university", "major", "year", "courses"])
        #expect(viewModel.studyRows.map(\.value) == [
            "Bahrain Polytechnic",
            "Programming",
            "2",
            "IT8108, Data Structures",
        ])
    }

    @Test("A course the catalogue does not know is shown by its id")
    func unknownCourseFallsBackToTheId() {
        let stored = StoredProfile(
            university: "Bahrain Polytechnic",
            major: "Programming",
            year: 2,
            courseIds: ["IT8108", "c_999"]
        )

        let viewModel = ProfileViewModel(session: session(), stored: stored)

        #expect(viewModel.studyRows.first { $0.id == "courses" }?.value == "IT8108, c_999")
    }

    @Test("The plan section carries the hours and the target grade")
    func planSectionReadsTheGoals() {
        let viewModel = ProfileViewModel(session: session(), stored: .preview)

        #expect(viewModel.planRows.map(\.id) == ["hours", "grade"])
        #expect(
            viewModel.planRows.first { $0.id == "hours" }?.value
                == WeekHoursReadout.string(for: 12)
        )
        #expect(viewModel.planRows.first { $0.id == "grade" }?.value == "A")
    }

    @Test("With no document, both sections are omitted rather than filled in")
    func noDocumentMeansNoSections() {
        // Only reachable via a failed gate read, but the honest answer is the header and
        // nothing else — invented rows would be worse than an empty screen.
        let viewModel = ProfileViewModel(session: session(), stored: nil)

        #expect(viewModel.hasStudyRows == false)
        #expect(viewModel.hasPlanRows == false)
        #expect(viewModel.studyRows.isEmpty)
        #expect(viewModel.planRows.isEmpty)
    }

    @Test("A part-way document shows the half it has")
    func partwayDocumentShowsTheHalfItHas() {
        let viewModel = ProfileViewModel(
            session: session(),
            stored: StoredProfile(weeklyStudyGoalHours: 8, targetGrade: .b)
        )

        #expect(viewModel.hasStudyRows == false)
        #expect(viewModel.planRows.map(\.id) == ["hours", "grade"])
    }

    @Test("Every string comes from the catalogue")
    func copyIsLocalised() {
        let viewModel = ProfileViewModel(session: session(), stored: .preview)

        #expect(viewModel.title == L10n.profileViewTitle.string)
        #expect(viewModel.studiesHeading == L10n.profileViewStudiesHeading.string)
        #expect(viewModel.planHeading == L10n.profileViewPlanHeading.string)
        #expect(viewModel.progressTitle == L10n.profileViewProgressTitle.string)
        #expect(viewModel.progressBody == L10n.profileViewProgressBody.string)
        // The shortcut reuses B07's copy rather than a second string that could drift from it.
        #expect(viewModel.editTitle == L10n.profileEditTitle.string)
    }
}
