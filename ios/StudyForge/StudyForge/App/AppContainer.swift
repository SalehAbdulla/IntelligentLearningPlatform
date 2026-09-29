//
//  AppContainer.swift
//  StudyForge
//
//  Lightweight dependency injection. No singletons: every dependency is constructed
//  here and passed down, so nothing is reachable from a view.
//  Convention: docs/04-TECH-ARCHITECTURE-COST.md §8
//

import Foundation
import Synchronization

/// The build environment. Secrets are injected per-environment via xcconfig,
/// never committed (see .gitignore).
enum AppEnvironment: String, Sendable, CaseIterable {
    case dev
    case staging
    case prod

    /// The environment this build runs as.
    ///
    /// Debug builds are Development, which is what permits the local-emulator Firebase
    /// configuration. A Release build is Production and therefore REQUIRES a real
    /// `GoogleService-Info.plist` — `FirebaseBootstrap` stops the app at launch rather
    /// than let a release build run against a fake project.
    static var current: AppEnvironment {
        #if DEBUG
        .dev
        #else
        .prod
        #endif
    }

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

    /// Which Firebase configuration the app started with. Shown in diagnostics, so
    /// "why can't I see my data?" has a one-line answer.
    let firebaseSource: FirebaseConfigurationSource

    /// Authentication. Protocol-backed, so screens can be previewed and tested with
    /// `MockAuthService` and no Firebase project at all.
    let auth: any AuthService

    /// The signed-in user, or `nil` before authentication completes.
    /// Drives `RootView`'s routing.
    var session: UserSession?

    /// True once auth has answered for the first time. Distinguishes "not signed in"
    /// from "we don't know yet" — the difference between a correct launch and a
    /// sign-in screen that flashes and disappears.
    var hasResolvedAuth: Bool

    /// The auth-state observation task.
    ///
    /// Held behind a `Mutex` and marked `nonisolated` so `deinit` — which is not
    /// main-actor isolated — can cancel it. A plain `@MainActor var` cannot be touched
    /// from `deinit` under strict concurrency.
    private nonisolated let authObservation = Mutex<Task<Void, Never>?>(nil)

    init(
        environment: AppEnvironment,
        firebaseSource: FirebaseConfigurationSource,
        auth: any AuthService
    ) {
        self.environment = environment
        self.firebaseSource = firebaseSource
        self.auth = auth
        self.hasResolvedAuth = false
        self.session = auth.currentSession()
    }

    /// Begins observing authentication state.
    ///
    /// Called once from the app's launch, not from an initialiser, so that a container
    /// built for a preview or a test does not silently start a background subscription.
    func start() {
        guard authObservation.withLock({ $0 == nil }) else { return }

        let task = Task { [weak self] in
            guard let stream = self?.auth.stateChanges() else { return }
            for await state in stream {
                guard let self else { return }
                self.session = state.session
                if state.isResolved { self.hasResolvedAuth = true }
            }
        }
        authObservation.withLock { $0 = task }
    }

    deinit {
        // Cancelled explicitly: without this, a container created and discarded — as
        // previews and tests do — would leave a task awaiting a stream forever.
        authObservation.withLock { $0?.cancel() }
    }
}

// MARK: - Convenience factories

extension AppContainer {

    /// The container the app launches with.
    ///
    /// Configures Firebase and selects the real auth service — except in a unit-test
    /// host, where Firebase is not configured at all and the mock is used instead. That
    /// keeps tests fast and hermetic: they assert on protocols and mocks, never on a
    /// live project or a running emulator.
    static func live(environment: AppEnvironment) -> AppContainer {
        let source = FirebaseBootstrap.configure(environment: environment)
        let auth: any AuthService = source == .skippedForTests
            ? MockAuthService(latency: .zero)
            : FirebaseAuthService()

        return AppContainer(environment: environment, firebaseSource: source, auth: auth)
    }

    /// A container backed entirely by mocks, for previews and for tests that need a
    /// session but no backend.
    ///
    /// This is the ONLY way a preview should obtain a container. Reaching for
    /// `FirebaseAuthService()` inside a `#Preview` would make previews depend on a
    /// Firebase project — precisely the coupling the protocol exists to prevent.
    static func previewing(session: UserSession? = .preview) -> AppContainer {
        let auth = MockAuthService(
            initialState: session.map { AuthState.signedIn($0) } ?? .signedOut,
            latency: .zero
        )
        let container = AppContainer(
            environment: .dev,
            firebaseSource: .localEmulator,
            auth: auth
        )
        // Set directly rather than by calling `start()`: a preview should render its
        // resolved state immediately, not flash a loading state first.
        container.hasResolvedAuth = true
        return container
    }
}

