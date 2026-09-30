//
//  RootView.swift
//  StudyForge
//
//  The app's routing entry point (docs/03 §5).
//
//  THREE BRANCHES, AND WHY THE FIRST ONE MATTERS
//  --------------------------------------------
//      unknown   -> A01 Splash     (auth has not answered yet)
//      signedOut -> auth flow      (log in / sign up / reset)
//      signedIn  -> role home      (currently the capability read-out)
//
//  Branch one is the one people skip, and skipping it is a real bug. Firebase resolves a
//  persisted session asynchronously, so for a moment the app genuinely does not know
//  whether anyone is signed in. Treating `session == nil` as "signed out" makes a
//  returning student see the log-in screen flash before being bounced to their home —
//  the most common launch defect in Firebase apps. `hasResolvedAuth` is what separates
//  "no" from "not yet", and it is set the first time `AuthState` reports anything other
//  than `.unknown`.
//
//  Sprint S0's development surfaces (design gallery, AI spike) are no longer top-level
//  tabs; they now live behind the signed-in screen in DEBUG. The product path is the auth
//  flow, which is what F01 exists for.
//

import SwiftUI

struct RootView: View {

    let container: AppContainer

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Mirrors the persisted onboarding flag into view state, so finishing the pager
    /// re-renders immediately. The store is not observable (it is a plain protocol), and
    /// it does not need to be: onboarding happens once, and `onFinish` is the single
    /// moment the value changes.
    @State private var hasCompletedOnboarding: Bool

    init(container: AppContainer) {
        self.container = container
        _hasCompletedOnboarding = State(initialValue: container.onboarding.hasCompletedOnboarding)
    }

    var body: some View {
        Group {
            if !container.hasResolvedAuth {
                SplashView()
            } else if let session = container.session {
                // Signed in. Verification is checked BEFORE the home screen, because F01's
                // stated goal is to get a VERIFIED user onto a role home — so an
                // unverified session has not finished the feature, it has skipped a step.
                if session.isEmailVerified {
                    SignedInHomeView(container: container)
                } else {
                    // `session.email`, NOT `displayName` — this is the address the link was
                    // sent to, and showing a name here both reads wrong and hides the
                    // mistyped address that is the most common reason the email never
                    // arrives. A screenshot caught this; the unit tests could not, because
                    // they build the view model directly and never exercise this line.
                    EmailVerificationView(auth: container.auth, email: session.email)
                }
            } else if !hasCompletedOnboarding {
                // Onboarding sits BEFORE sign-in on purpose. It has to explain what the
                // app is and what happens to your files before asking for an email
                // address, otherwise the privacy claim arrives after the commitment.
                OnboardingView(
                    store: container.onboarding,
                    startingPage: debugStartingPage,
                    onFinish: { hasCompletedOnboarding = true }
                )
            } else {
                AuthFlowView(container: container)
            }
        }
        // A hard swap between two full-screen branches reads as a glitch, so the change is
        // cross-faded. Reduce Motion shortens it rather than removing it, keeping the
        // branch change legible without animating.
        .animation(Motion.respecting(Motion.quick, reduceMotion: reduceMotion), value: branch)
        .environment(container)
        .tint(ColorTokens.primary)
    }

    /// Which branch should be showing. Derived rather than stored, so there is exactly one
    /// source of truth for what RootView renders.
    private var branch: Int {
        if !container.hasResolvedAuth { return 0 }
        if let session = container.session { return session.isEmailVerified ? 3 : 1 }
        return hasCompletedOnboarding ? 2 : 4
    }

    /// DEBUG-only: opens the onboarding pager on a given slide.
    ///
    ///     xcrun simctl launch <device> com.studyforge.app -onboardingPage 2
    ///
    /// Exists so a slide can be demonstrated or screenshotted without swiping — useful for
    /// a viva, and for checking a specific slide in Arabic or at AX5 without walking the
    /// whole flow. Compiled out of Release entirely, and it cannot skip onboarding: it only
    /// chooses which slide is shown first.
    private var debugStartingPage: OnboardingPage {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let flag = arguments.firstIndex(of: "-onboardingPage"),
           arguments.index(after: flag) < arguments.endIndex,
           let humanNumber = Int(arguments[arguments.index(after: flag)]),
           // 1-based, because the person typing it is reading slide numbers off a design.
           let page = OnboardingPage(rawValue: humanNumber - 1) {
            return page
        }
        #endif
        return .valueProp
    }
}

// MARK: - Previews

#Preview("Root — unresolved (splash)") {
    // `.unknown` never resolves here because nothing calls `start()`, which is exactly the
    // launch moment this preview documents.
    RootView(
        container: AppContainer(
            environment: .dev,
            firebaseSource: .localEmulator,
            auth: MockAuthService(initialState: .unknown, latency: .zero),
            onboarding: InMemoryOnboardingStore()
        )
    )
}

#Preview("Root — signed out, onboarding first") {
    RootView(container: .previewing(session: nil, hasCompletedOnboarding: false))
}

#Preview("Root — signed out, onboarding done") {
    RootView(container: .previewing(session: nil, hasCompletedOnboarding: true))
}

#Preview("Root — signed in, verified") {
    // `.preview` carries `isEmailVerified: true`, so this lands on the home screen. The
    // unverified counterpart is below.
    RootView(container: .previewing())
}

#Preview("Root — signed in, NOT verified (A06)") {
    // The branch that enforces F01's goal: a signed-in but unverified user must not reach
    // the home screen. Without a preview for it the routing rule is invisible in the
    // canvas, and a regression that let them through would look like nothing had changed.
    RootView(
        container: .previewing(
            session: UserSession(
                id: "uid_new",
                displayName: "New Student",
                role: .student,
                plan: .free,
                groupIds: [],
                email: "new@studyforge.test",
                isEmailVerified: false
            )
        )
    )
}

