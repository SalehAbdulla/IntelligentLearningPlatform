//
//  AuthFlowView.swift
//  StudyForge
//
//  Navigation for the signed-out branch: log in ↔ sign up ↔ forgot password.
//
//  WHY A NAVIGATION STACK RATHER THAN A BOOLEAN
//  -------------------------------------------
//  The three screens form a small graph, not a sequence: from log-in you can reach either
//  of the other two, and both return to log-in. Modelling that as `@State var showingSignUp`
//  booleans produces the classic bug where two flags are true and the wrong screen wins.
//  A typed path is composable and the back gesture works for free.
//
//  NOTE ON `AppContainer.auth` vs `AuthService` STATE
//  -------------------------------------------------
//  Signing in does not navigate here. It mutates auth state, `AppContainer` observes it,
//  and `RootView` swaps the whole branch. This view never needs to know that it succeeded,
//  which is why there is no completion callback anywhere in this file.
//

import SwiftUI

struct AuthFlowView: View {

    let container: AppContainer

    /// Screens reachable from the log-in root.
    enum Route: Hashable {
        case signUp
        case forgotPassword
    }

    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            LoginView(
                auth: container.auth,
                onForgotPassword: { path.append(.forgotPassword) },
                onCreateAccount: { path.append(.signUp) }
            )
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .signUp:
                    SignUpView(
                        auth: container.auth,
                        // Replace the whole path so "Log in" from sign-up does not leave
                        // a sign-up screen one back-gesture away.
                        onLogInInstead: { path.removeAll() }
                    )
                case .forgotPassword:
                    ForgotPasswordView(
                        auth: container.auth,
                        onBackToLogin: { path.removeAll() }
                    )
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Auth flow — signed out") {
    AuthFlowView(container: .previewing(session: nil))
}
