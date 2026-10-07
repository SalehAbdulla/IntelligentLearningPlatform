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

    /// Watches connectivity so M06's banner can appear and disappear. Started once, from the view's
    /// lifetime, because this view lives for as long as the app does.
    @State private var offline = OfflineMonitor()

    /// Mirrors the persisted onboarding flag into view state, so finishing the pager
    /// re-renders immediately. The store is not observable (it is a plain protocol), and
    /// it does not need to be: onboarding happens once, and `onFinish` is the single
    /// moment the value changes.
    @State private var hasCompletedOnboarding: Bool

    /// Set once the student has left the wizard's confirmation screen in this session.
    ///
    /// A session latch, not a persisted flag, and it does two jobs: it stops the wizard
    /// re-opening if the server's answer is momentarily stale right after the student
    /// finishes, and it is what lets the DEBUG `-seedProfileSetup` hatch — which fabricates an
    /// account with no profile — return to the home screen instead of looping.
    @State private var hasCompletedProfileSetup = false

    init(container: AppContainer) {
        self.container = container
        _hasCompletedOnboarding = State(initialValue: container.onboarding.hasCompletedOnboarding)
    }

    /// Whether the profile wizard should be showing in place of the home screen.
    ///
    /// This is the gate, and it asks the SERVER (`container.profileStatus`), because a flag on
    /// the device cannot survive a reinstall or a second device — the two moments a
    /// locally-remembered answer is wrong. Two things override it:
    ///
    ///  · a DEBUG launch argument, so the wizard can be opened for a screenshot or a viva
    ///    without first registering and verifying an empty account:
    ///
    ///        xcrun simctl launch <device> com.saleh.studyforge -seedProfileSetup
    ///
    ///    with `-profileSetupStep N` to open on a later step. Compiled out of Release, so a
    ///    shipping build can never fabricate a profile-setup state — which matters here,
    ///    because the screen writes to `users/{uid}`.
    ///  · `hasCompletedProfileSetup`, so finishing the wizard stays finished for the session.
    private var showsProfileSetup: Bool {
        if hasCompletedProfileSetup { return false }

        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-seedProfileSetup") { return true }
        #endif

        return container.profileStatus == .incomplete
    }

    var body: some View {
        VStack(spacing: 0) {
            // M06 — the offline banner sits above every branch, because the state it describes
            // applies to all of them: local-first means everything already downloaded still works.
            if offline.isOffline {
                SFOfflineBanner(message: L10n.notificationOfflineBanner.string)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            Group {
            if !container.hasResolvedAuth {
                SplashView()
            } else if let session = container.session {
                // Signed in. Verification is checked BEFORE the home screen, because F01's
                // stated goal is to get a VERIFIED user onto a role home — so an
                // unverified session has not finished the feature, it has skipped a step.
                if session.isEmailVerified {
                    if showsProfileSetup {
                        // Reaching the wizard honestly means registering, verifying and
                        // filling the form — none of it scriptable here, because there is no
                        // tap automation installed — so `-seedProfileSetup` opens it directly
                        // and `-profileSetupStep` chooses which step, letting B02 or B03 be
                        // reviewed without the steps before them.
                        //
                        // Otherwise the wizard RESUMES: it opens at the first step the stored
                        // profile has not answered, and is seeded with what HAS been answered
                        // so B04 summarises the whole profile rather than this session alone.
                        ProfileSetupFlowView(
                            profile: container.profile,
                            startingAt: debugProfileSetupStep
                                ?? ProfileSetupStep.resumePoint(for: container.storedProfile),
                            answers: ProfileSetupAnswers(stored: container.storedProfile)
                        ) {
                            // B04 (the confirmation screen) is what calls this, so the wizard
                            // ends when the STUDENT dismisses the summary rather than the
                            // instant the last field saves. Latch it for this session AND ask
                            // the server again, so the NEXT launch knows without being told.
                            hasCompletedProfileSetup = true
                            Task { await container.resolveProfile() }
                        }
                    } else if container.profileStatus.isResolved || hasCompletedProfileSetup {
                        SignedInHomeView(container: container)
                    } else {
                        // Signed in and verified, but the profile read has not answered yet.
                        // The home screen would flash at a student who is about to be asked to
                        // build a profile, and the wizard would do the reverse; the splash is
                        // the honest wait, exactly as it is while auth resolves.
                        SplashView()
                    }
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
        }
        .animation(Motion.respecting(Motion.quick, reduceMotion: reduceMotion), value: offline.isOffline)
        .task { offline.start() }
        // A hard swap between two full-screen branches reads as a glitch, so the change is
        // cross-faded. Reduce Motion shortens it rather than removing it, keeping the
        // branch change legible without animating.
        .animation(Motion.respecting(Motion.quick, reduceMotion: reduceMotion), value: branch)
        .environment(container)
        .tint(ColorTokens.primary)
    }

    /// Which branch should be showing. Derived rather than stored, so there is exactly one
    /// source of truth for what RootView renders.
    ///
    /// The numbers are animation identities, not the render order: the cross-fade below fires
    /// only when this changes, so every distinct screen needs its own value. The profile gate
    /// adds two — the wizard, and the splash shown while the profile read is in flight.
    private var branch: Int {
        if !container.hasResolvedAuth { return 0 }
        guard let session = container.session else {
            return hasCompletedOnboarding ? 2 : 4
        }
        if !session.isEmailVerified { return 1 }
        if showsProfileSetup { return 5 }
        return (container.profileStatus.isResolved || hasCompletedProfileSetup) ? 3 : 6
    }

    /// DEBUG-only: which step `-seedProfileSetup` should open on.
    ///
    ///     xcrun simctl launch <device> com.saleh.studyforge -seedProfileSetup -profileSetupStep 2
    ///
    /// 1-based, for the same reason `-onboardingPage` is: whoever types it is reading step
    /// numbers off a design. It exists because there is no tap automation in this
    /// environment, so reaching step 2 by hand would mean filling in step 1 and tapping
    /// Continue first — which is exactly the thing that cannot be scripted. Compiled out of
    /// Release, like the other two hatches, and it cannot skip the wizard: it only chooses
    /// which step is shown first.
    private var debugProfileSetupStep: ProfileSetupStep? {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let flag = arguments.firstIndex(of: "-profileSetupStep"),
           arguments.index(after: flag) < arguments.endIndex,
           let humanNumber = Int(arguments[arguments.index(after: flag)]),
           let step = ProfileSetupStep(rawValue: humanNumber - 1) {
            return step
        }
        #endif
        return nil
    }

    /// DEBUG-only: opens the onboarding pager on a given slide.
    ///
    ///     xcrun simctl launch <device> com.saleh.studyforge -onboardingPage 2
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
            profile: MockProfileService(latency: .zero),
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
    // `.preview` carries `isEmailVerified: true` and the preview container seeds a COMPLETE
    // profile, so this lands on the home screen after passing the gate.
    RootView(container: .previewing())
}

#Preview("Root — signed in, profile incomplete (B01)") {
    // The gate: a verified student with no complete profile is sent to the wizard rather than
    // the home screen. Only a preview can reach this by asking, which is the point — the
    // honest route is to register and verify a real account.
    RootView(container: .previewing(profileStatus: .incomplete))
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

