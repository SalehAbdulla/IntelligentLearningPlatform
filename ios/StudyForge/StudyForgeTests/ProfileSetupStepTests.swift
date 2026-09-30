//
//  ProfileSetupStepTests.swift
//  StudyForgeTests
//
//  The wizard's sequence, which is small enough to look obvious and is exactly where an
//  off-by-one hides: "Step 2 of 3" is either right for every student or wrong for all of
//  them, and nothing else in the app would notice.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Profile wizard steps")
struct ProfileSetupStepTests {

    @Test("The wizard starts on the academic step")
    func startsAtAcademic() {
        #expect(ProfileSetupStep.first == .academic)
        #expect(ProfileSetupStep.academic.number == 1)
    }

    @Test("Steps are numbered from 1, in design order")
    func stepsAreNumberedInOrder() {
        // Order is the design's (docs/03 §B). If a case is ever inserted rather than
        // appended, this fails rather than silently shifting every student's position.
        #expect(ProfileSetupStep.allCases.map(\.number) == Array(1...ProfileSetupStep.allCases.count))
        #expect(ProfileSetupStep.allCases.first == .academic)
    }

    @Test("The total is the design's three, not the number of steps built so far")
    func totalIsTheDesignsCount() {
        // The distinction is deliberate. B03 is not built yet, and deriving the total from
        // the cases present would make B01 and B02 read "1 of 2" / "2 of 2" today and
        // renumber themselves to "of 3" the day B03 lands — changing a number students had
        // already been shown, with nothing failing.
        #expect(ProfileSetupStep.designedCount == 3)
        #expect(ProfileSetupStep.allCases.count <= ProfileSetupStep.designedCount)
    }

    @Test("Each step labels its own position")
    func labelsComeFromTheStep() {
        #expect(ProfileSetupStep.academic.label == L10n.profileStep.string(1, 3))
        #expect(ProfileSetupStep.learningStyle.label == L10n.profileStep.string(2, 3))
    }

    @Test("B01 advances to B02, and B02 ends the flow while B03 is unbuilt")
    func nextStepEndsTheFlowAtTheLastBuiltStep() {
        #expect(ProfileSetupStep.academic.next == .learningStyle)
        // `nil` is what ends the wizard. This assertion flips the moment B03 is added,
        // which is the point: the flow's end is a decision, not an accident.
        #expect(ProfileSetupStep.learningStyle.next == nil)
    }
}
