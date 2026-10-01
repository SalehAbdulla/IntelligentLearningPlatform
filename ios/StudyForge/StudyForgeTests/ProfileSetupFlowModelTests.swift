//
//  ProfileSetupFlowModelTests.swift
//  StudyForgeTests
//
//  The wizard's sequence and its accumulated answers. The two that matter: recording an
//  answer ADVANCES (a step that saved but did not move on would strand the student), and
//  recording the last answer ENDS the steps by moving to the confirmation screen rather than
//  calling the caller — the student dismisses B04 themselves.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Profile wizard flow")
@MainActor
struct ProfileSetupFlowModelTests {

    private let academic = AcademicProfile(
        university: "Bahrain Polytechnic",
        major: "Programming",
        year: 2,
        courseIds: ["IT8108"]
    )

    @Test("The flow opens on the first step with nothing answered")
    func startsAtTheFirstStep() {
        let model = ProfileSetupFlowModel()

        #expect(model.step == .academic)
        #expect(model.answers == .empty)
        #expect(model.isComplete == false)
    }

    @Test("Recording B01 advances to B02 and keeps the answer")
    func recordingAcademicAdvances() {
        let model = ProfileSetupFlowModel()

        model.record(academic)

        #expect(model.step == .learningStyle)
        #expect(model.answers.academic == academic)
        #expect(model.isComplete == false)
    }

    @Test("Recording B02 advances to B03 and keeps both answers")
    func recordingStyleAdvances() {
        let model = ProfileSetupFlowModel()
        model.record(academic)

        model.record(.visual)

        #expect(model.step == .studyGoals)
        #expect(model.answers.academic == academic)
        #expect(model.answers.learningStyle == .visual)
        #expect(model.isComplete == false)
    }

    @Test("Recording B03 completes the flow with all three answers")
    func recordingGoalsCompletes() {
        let model = ProfileSetupFlowModel()
        let goals = StudyGoals(weeklyStudyGoalHours: 12, targetGrade: .a)
        model.record(academic)
        model.record(.visual)

        model.record(goals)

        #expect(model.isComplete)
        #expect(model.answers.studyGoals == goals)
        // The last step stays the last step; there is no fourth screen hiding behind it.
        #expect(model.step == .studyGoals)
    }

    @Test("A flow opened on the last step completes on its first answer")
    func startingAtTheLastStepCompletesImmediately() {
        // What `-profileSetupStep 3` produces. The earlier answers are absent, and the
        // confirmation screen has to cope with that rather than have them fabricated.
        let model = ProfileSetupFlowModel(startingAt: .studyGoals)

        model.record(StudyGoals(weeklyStudyGoalHours: 4, targetGrade: .c))

        #expect(model.isComplete)
        #expect(model.answers.academic == nil)
        #expect(model.answers.learningStyle == nil)
    }
}
