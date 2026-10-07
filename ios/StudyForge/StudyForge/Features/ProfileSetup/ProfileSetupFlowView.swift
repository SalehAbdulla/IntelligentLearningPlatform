//
//  ProfileSetupFlowView.swift
//  StudyForge
//
//  The wizard's container: it shows the current step, collects each step's answer, and
//  finishes on its confirmation screen (B04).
//
//  WHY A CONTAINER RATHER THAN NAVIGATION INSIDE THE STEPS
//  ------------------------------------------------------
//  Each step's view model deliberately refuses to decide its own successor — on success it
//  calls back and stops, because a screen that both saves and chooses what comes next is
//  the reason flows become untestable. Something has to own the sequence; this is that
//  something. The sequence itself lives in `ProfileSetupFlowModel`, so it can be tested;
//  this view is the wiring and nothing more.
//
//  It knows nothing about what the wizard is FOR. B03 joins by being added to
//  `ProfileSetupStep`, and B04 by answering "is the flow complete?"; whether a signed-in
//  student sees this flow at all stays a routing decision in `RootView`, which is where the
//  "profile complete" question belongs.
//

import SwiftUI

// Accessibility: the wizard is a container of step views, each of which carries its own labels; the step
// transition goes through `Motion.respecting`, so Reduce Motion shortens it rather than removing it.

struct ProfileSetupFlowView: View {

    let profile: any ProfileService

    /// What B01's pickers choose from, shared with B04 so the confirmation can resolve the
    /// course ids it stored back to names. One catalogue, one call site.
    let catalogue: AcademicCatalogue

    /// Called once the student leaves the confirmation screen (B04). The caller decides what
    /// that means.
    let onFinish: () -> Void

    @State private var model: ProfileSetupFlowModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - startingAt: where the wizard opens. A part-way student resumes at the first step
    ///     they have not answered (`ProfileSetupStep.resumePoint(for:)`); the DEBUG
    ///     `-profileSetupStep` hatch overrides it.
    ///   - answers: what the student answered on an EARLIER visit, so the confirmation screen
    ///     summarises the whole profile rather than only this session's steps.
    init(
        profile: any ProfileService,
        catalogue: AcademicCatalogue,
        startingAt step: ProfileSetupStep = .first,
        answers: ProfileSetupAnswers = .empty,
        onFinish: @escaping () -> Void
    ) {
        self.profile = profile
        self.catalogue = catalogue
        self.onFinish = onFinish
        _model = State(initialValue: ProfileSetupFlowModel(startingAt: step, answers: answers))
    }

    var body: some View {
        Group {
            if model.isComplete {
                // The flow ends here, but the WIZARD does not: the student reads back what
                // they chose and dismisses it themselves on `onGoToDashboard`.
                ProfileSetupCompleteView(
                    answers: model.answers,
                    catalogue: catalogue,
                    onGoToDashboard: onFinish
                )
            } else {
                switch model.step {
                case .academic:
                    ProfileSetupAcademicView(profile: profile, catalogue: catalogue) {
                        model.record($0)
                    }
                case .learningStyle:
                    ProfileSetupLearningStyleView(profile: profile) { model.record($0) }
                case .studyGoals:
                    ProfileSetupStudyGoalsView(profile: profile) { model.record($0) }
                }
            }
        }
        // A hard swap between steps reads as a glitch, for the same reason `RootView`
        // cross-fades its branches. Reduce Motion shortens it rather than removing it, so
        // the step change stays legible. Animated on both the step and the completion flag,
        // because the last transition is step -> confirmation rather than step -> step.
        .animation(Motion.respecting(Motion.quick, reduceMotion: reduceMotion), value: model.step)
        .animation(Motion.respecting(Motion.quick, reduceMotion: reduceMotion), value: model.isComplete)
    }
}

// MARK: - Previews

#Preview("Profile wizard — from the first step") {
    ProfileSetupFlowView(
        profile: MockProfileService(latency: .zero),
        catalogue: SeededCourseCatalogueStore.starter
    ) {}
}

#Preview("Profile wizard — on the learning-style step") {
    ProfileSetupFlowView(
        profile: MockProfileService(latency: .zero),
        catalogue: SeededCourseCatalogueStore.starter,
        startingAt: .learningStyle
    ) {}
}

#Preview("Profile wizard — one step from the confirmation") {
    // Finishing B03 lands on B04, which is the part of the flow a screenshot cannot reach by
    // waiting: it is shown once the step saves.
    ProfileSetupFlowView(
        profile: MockProfileService(latency: .zero),
        catalogue: SeededCourseCatalogueStore.starter,
        startingAt: .studyGoals
    ) {}
}
