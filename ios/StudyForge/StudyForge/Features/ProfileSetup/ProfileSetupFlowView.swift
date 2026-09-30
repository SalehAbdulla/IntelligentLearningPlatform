//
//  ProfileSetupFlowView.swift
//  StudyForge
//
//  The wizard's container: it holds which step is showing and advances when a step says it
//  saved.
//
//  WHY A CONTAINER RATHER THAN NAVIGATION INSIDE THE STEPS
//  ------------------------------------------------------
//  Each step's view model deliberately refuses to decide its own successor — on success it
//  calls back and stops, because a screen that both saves and chooses what comes next is
//  the reason flows become untestable. Something has to own the sequence; this is that
//  something, and it owns exactly one piece of state.
//
//  It knows nothing about what the wizard is FOR. B03 joins by being added to
//  `ProfileSetupStep`; whether a signed-in student sees this flow at all stays a routing
//  decision in `RootView`, which is where the "profile complete" question belongs.
//

import SwiftUI

struct ProfileSetupFlowView: View {

    let profile: any ProfileService

    /// Called once the last BUILT step is saved. The caller decides what that means.
    let onFinish: () -> Void

    @State private var step: ProfileSetupStep

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        profile: any ProfileService,
        startingAt step: ProfileSetupStep = .first,
        onFinish: @escaping () -> Void
    ) {
        self.profile = profile
        self.onFinish = onFinish
        _step = State(initialValue: step)
    }

    var body: some View {
        Group {
            switch step {
            case .academic:
                ProfileSetupAcademicView(profile: profile) { _ in advance() }
            case .learningStyle:
                ProfileSetupLearningStyleView(profile: profile) { _ in advance() }
            }
        }
        // A hard swap between steps reads as a glitch, for the same reason `RootView`
        // cross-fades its branches. Reduce Motion shortens it rather than removing it, so
        // the step change stays legible.
        .animation(Motion.respecting(Motion.quick, reduceMotion: reduceMotion), value: step)
    }

    /// Advances to the next step, or ends the flow when there is none.
    ///
    /// Ending early is correct today: B03 does not exist, so B02 is the last step there is.
    /// `ProfileSetupStep.next` becomes non-nil for B02 the moment B03's case is added, and
    /// this method needs no change — which is why the "what if B03 is missing" question is
    /// answered in one place instead of at every call site.
    private func advance() {
        if let next = step.next {
            step = next
        } else {
            onFinish()
        }
    }
}

// MARK: - Previews

#Preview("Profile wizard — from the first step") {
    ProfileSetupFlowView(profile: MockProfileService(latency: .zero)) {}
}

#Preview("Profile wizard — on the learning-style step") {
    ProfileSetupFlowView(
        profile: MockProfileService(latency: .zero),
        startingAt: .learningStyle
    ) {}
}
