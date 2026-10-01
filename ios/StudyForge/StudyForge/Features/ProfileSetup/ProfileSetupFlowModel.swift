//
//  ProfileSetupFlowModel.swift
//  StudyForge
//
//  The wizard's state: which step is showing, what has been answered, and whether the flow
//  has reached its confirmation screen.
//
//  WHY THE SEQUENCE MOVED OUT OF THE VIEW
//  -------------------------------------
//  `ProfileSetupFlowView` used to own the step as a single `@State`, which was fine while
//  the flow did one thing — advance. It now does three: advance, accumulate the answers B04
//  summarises, and decide when the flow is over. A view that owns that much logic cannot be
//  unit-tested, so the state lives here. `OnboardingViewModel` is the same split for the
//  pager.
//
//  WHY RECORDING AND ADVANCING ARE ONE CALL
//  ---------------------------------------
//  A step could hand its answer back and be told separately to advance, but then the two can
//  drift: an answer recorded without an advance strands the student on a step they have
//  already completed, and an advance without a record produces a confirmation screen missing
//  a line. `record(_:)` does both, so the answers and the position cannot disagree.
//

import Foundation

@MainActor
@Observable
final class ProfileSetupFlowModel {

    /// The step currently on screen.
    private(set) var step: ProfileSetupStep

    /// What the steps have collected so far.
    private(set) var answers = ProfileSetupAnswers.empty

    /// Set once the last step has saved, at which point the flow shows its confirmation
    /// screen. Only the student's dismissal of that screen ends the wizard.
    private(set) var isComplete = false

    /// - Parameter step: where the wizard opens. Overridden in DEBUG by
    ///   `-profileSetupStep` so a step can be shown without walking the ones before it.
    init(startingAt step: ProfileSetupStep = .first) {
        self.step = step
    }

    // MARK: Recording each step's answer

    /// Records B01's answer and moves on.
    func record(_ academic: AcademicProfile) {
        answers.academic = academic
        advance()
    }

    /// Records B02's answer and moves on.
    func record(_ style: LearningStyle) {
        answers.learningStyle = style
        advance()
    }

    /// Records B03's answer and finishes the steps.
    func record(_ goals: StudyGoals) {
        answers.studyGoals = goals
        advance()
    }

    // MARK: Sequence

    /// Moves to the next step, or to the confirmation screen when there is none.
    ///
    /// This is the only place the sequence is decided, and it has not changed since the flow
    /// had two steps — which was the point of putting the order in `ProfileSetupStep`: B03
    /// joined by being added to the enum, and the end of the wizard moved from "step 2 is the
    /// last one built" to "step 3 is the design's last step", then to "B04 follows it",
    /// without this method noticing the difference.
    private func advance() {
        guard !isComplete else { return }

        if let next = step.next {
            step = next
        } else {
            isComplete = true
        }
    }
}
