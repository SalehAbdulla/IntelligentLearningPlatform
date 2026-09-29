//
//  AppContainer.swift
//  StudyForge
//
//  Lightweight dependency injection. No singletons: every dependency is constructed
//  here and passed down, so nothing is reachable from a view.
//  Convention: docs/04-TECH-ARCHITECTURE-COST.md §8
//

import Foundation

/// The build environment. Secrets are injected per-environment via xcconfig,
/// never committed (see .gitignore).
enum AppEnvironment: String, Sendable, CaseIterable {
    case dev
    case staging
    case prod

    var displayName: String {
        switch self {
        case .dev: "Development"
        case .staging: "Staging"
        case .prod: "Production"
        }
    }
}

/// Root dependency container.
///
/// Services are added here as they are built (AuthService, AIRouter, PaymentGateway, …).
/// Each must be protocol-backed so it can be replaced with a mock in tests and previews.
@MainActor
@Observable
final class AppContainer {

    let environment: AppEnvironment

    /// The signed-in user, or `nil` before authentication completes.
    /// Drives `RootView`'s routing.
    var session: UserSession?

    init(environment: AppEnvironment, session: UserSession? = nil) {
        self.environment = environment
        self.session = session
    }
}
