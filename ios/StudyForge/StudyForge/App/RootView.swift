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

    var body: some View {
        Group {
            if !container.hasResolvedAuth {
                SplashView()
            } else if container.session == nil {
                AuthFlowView(container: container)
            } else {
                SignedInHomeView(container: container)
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
        return container.session == nil ? 1 : 2
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
            auth: MockAuthService(initialState: .unknown, latency: .zero)
        )
    )
}

#Preview("Root — signed out") {
    RootView(container: .previewing(session: nil))
}

#Preview("Root — signed in") {
    RootView(container: .previewing())
}

