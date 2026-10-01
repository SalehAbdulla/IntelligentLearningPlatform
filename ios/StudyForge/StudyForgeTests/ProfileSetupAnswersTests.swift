//
//  ProfileSetupAnswersTests.swift
//  StudyForgeTests
//
//  The accumulator the wizard fills as its steps are answered. The load-bearing property is
//  that a PARTIAL set is expressible: the DEBUG step hatch opens the wizard partway, so the
//  type must be able to say "study goals, and nothing before them" without forcing a fake
//  academic profile into being.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Profile setup — answers")
struct ProfileSetupAnswersTests {

    @Test("An untouched answer set is empty")
    func startsEmpty() {
        let answers = ProfileSetupAnswers.empty

        #expect(answers.academic == nil)
        #expect(answers.learningStyle == nil)
        #expect(answers.studyGoals == nil)
    }

    @Test("A partial set is expressible, so a partway wizard needs no invented answers")
    func partialSetIsExpressible() {
        let goals = StudyGoals(weeklyStudyGoalHours: 8, targetGrade: .b)
        let answers = ProfileSetupAnswers(studyGoals: goals)

        #expect(answers.academic == nil)
        #expect(answers.learningStyle == nil)
        #expect(answers.studyGoals == goals)
    }

    @Test("Two answer sets are equal only when every field agrees")
    func equalityComparesEveryField() {
        let goals = StudyGoals(weeklyStudyGoalHours: 12, targetGrade: .a)

        #expect(ProfileSetupAnswers(studyGoals: goals) == ProfileSetupAnswers(studyGoals: goals))
        #expect(ProfileSetupAnswers(studyGoals: goals) != ProfileSetupAnswers(learningStyle: .visual))
    }

    @Test("Answers can be seeded from a stored profile, so a resumed wizard can summarise it")
    func seedingFromAStoredProfile() {
        let answers = ProfileSetupAnswers(stored: .preview)

        #expect(answers.academic == StoredProfile.preview.academicProfile)
        #expect(answers.learningStyle == .visual)
        #expect(answers.studyGoals == StoredProfile.preview.studyGoals)
    }

    @Test("Seeding takes only what is there, and invents nothing")
    func seedingOnlyTakesWhatExists() {
        #expect(ProfileSetupAnswers(stored: nil) == .empty)

        let partial = ProfileSetupAnswers(stored: StoredProfile(
            university: "Bahrain Polytechnic",
            major: "Programming",
            year: 2,
            courseIds: ["IT8108"]
        ))

        #expect(partial.academic != nil)
        #expect(partial.learningStyle == nil)
        #expect(partial.studyGoals == nil)
    }
}
