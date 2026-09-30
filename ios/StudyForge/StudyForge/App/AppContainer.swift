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

    /// Remembers whether the user has finished onboarding (A02–A04). Protocol-backed so a
    /// test can put it in a known state, and so `UserDefaults.standard` is never touched
    /// from the view layer.
    let onboarding: any OnboardingStore

    /// Profile writes for the signed-in student (B01). Protocol-backed for the same reason
    /// as `auth`: the wizard is previewable and testable with no Firebase project.
    let profile: any ProfileService

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
        auth: any AuthService,
        profile: any ProfileService,
        onboarding: any OnboardingStore = UserDefaultsOnboardingStore()
    ) {
        self.environment = environment
        self.firebaseSource = firebaseSource
        self.auth = auth
        self.profile = profile
        self.onboarding = onboarding
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
        // Same rule as auth: with no project configured there is nothing to write to, so
        // the mock keeps the app runnable rather than failing at the first save.
        let profile: any ProfileService = source == .skippedForTests
            ? MockProfileService(latency: .zero)
            : FirebaseProfileService()

        #if DEBUG
        // `-seedProfileSetup` opens B01 (the profile wizard's academic step).
        //
        // B01 is arguably the hardest screen in F01 to reach by hand: it sits BEHIND a
        // verified account, so getting there honestly means creating an account against a
        // live project and then opening a real verification email. It also seeds a
        // VERIFIED session, which is what `.preview` is for — hence a separate flag from
        // `-seedUnverifiedSession`, whose whole point is the unverified state.
        //
        // Both use the mock service, so nothing is written to any project, and both are
        // compiled out of Release: a shipping build must never fabricate a session for a
        // screen that writes to `users/{uid}`.
        if ProcessInfo.processInfo.arguments.contains("-seedProfileSetup") {
            return AppContainer(
                environment: environment,
                firebaseSource: source,
                auth: MockAuthService(initialState: .signedIn(.preview), latency: .zero),
                profile: MockProfileService(latency: .zero)
            )
        }

        // `-seedUnverifiedSession` opens the app directly on A06.
        //
        // A06 is otherwise the hardest screen in F01 to look at: reaching it honestly means
        // completing sign-up against a live project and then finding a real verification
        // email. This is the same kind of escape hatch as `-onboardingPage`, and it is
        // compiled out of Release for the same reason — it FABRICATES a session, and a
        // shipping build must never do that.
        //
        // It swaps in the mock rather than mutating a Firebase session, so no account is
        // created and nothing is written to the project.
        if ProcessInfo.processInfo.arguments.contains("-seedUnverifiedSession") {
            return AppContainer(
                environment: environment,
                firebaseSource: source,
                auth: MockAuthService(
                    initialState: .signedIn(unverifiedPreviewSession),
                    latency: .zero
                ),
                profile: MockProfileService(latency: .zero)
            )
        }
        #endif

        return AppContainer(
            environment: environment,
            firebaseSource: source,
            auth: auth,
            profile: profile
        )
    }

    #if DEBUG
    /// A signed-in session whose email is NOT verified — the state A06 exists to render.
    ///
    /// Uses `example.test` rather than a real domain so a screenshot of this screen cannot
    /// be mistaken for a real student's address.
    static let unverifiedPreviewSession = UserSession(
        id: "uid_unverified_preview",
        displayName: "New Student",
        role: .student,
        plan: .free,
        groupIds: [],
        email: "new.student@example.test",
        isEmailVerified: false
    )
    #endif

    /// A container backed entirely by mocks, for previews and for tests that need a
    /// session but no backend.
    ///
    /// This is the ONLY way a preview should obtain a container. Reaching for
    /// `FirebaseAuthService()` inside a `#Preview` would make previews depend on a
    /// Firebase project — precisely the coupling the protocol exists to prevent.
    ///
    /// - Parameter hasCompletedOnboarding: defaults to `true`, so a preview of a
    ///   post-onboarding screen does not suddenly show the pager. Pass `false` to preview
    ///   the onboarding flow itself.
    static func previewing(
        session: UserSession? = .preview,
        hasCompletedOnboarding: Bool = true
    ) -> AppContainer {
        let auth = MockAuthService(
            initialState: session.map { AuthState.signedIn($0) } ?? .signedOut,
            latency: .zero
        )
        let container = AppContainer(
            environment: .dev,
            firebaseSource: .localEmulator,
            auth: auth,
            // No latency and no failure: a preview should show its final state, not a
            // spinner it has to be waited out.
            profile: MockProfileService(latency: .zero),
            // In-memory, never UserDefaults: a preview must not mutate the developer's
            // real onboarding flag.
            onboarding: InMemoryOnboardingStore(hasCompletedOnboarding: hasCompletedOnboarding)
        )
        // Set directly rather than by calling `start()`: a preview should render its
        // resolved state immediately, not flash a loading state first.
        container.hasResolvedAuth = true
        return container
    }
}

