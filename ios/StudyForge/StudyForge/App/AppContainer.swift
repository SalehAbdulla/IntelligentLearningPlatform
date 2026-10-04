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

/// Where a signed-in student is in the profile wizard, as far as the SERVER knows.
///
/// Modelled on `hasResolvedAuth` for the same reason: the app must be able to tell "we have
/// not asked yet" apart from "they have no profile". Collapsing the two is what makes an app
/// flash the wrong screen at launch — here, either the wizard at a student who finished it
/// months ago, or the home screen at one who has never seen it.
enum ProfileStatus: Sendable, Equatable {

    /// Not asked yet — a fresh container, or a user has just signed out.
    case unknown

    /// A read is in flight.
    case loading

    /// The account has no COMPLETE profile: the wizard should run.
    case incomplete

    /// The profile is complete: the student belongs on their home screen.
    case complete

    /// The read failed.
    ///
    /// Deliberately distinct from `.incomplete`, because the two call for opposite behaviour:
    /// a failed read must NOT send a student into a wizard that will try to write over a
    /// profile the app could not read. `RootView` treats this like `.complete` and lets the
    /// student through — being unable to confirm the profile must not lock anybody out of
    /// their own account.
    case failed

    /// True once an answer exists, including a failed one. The gate waits only while this is
    /// false.
    var isResolved: Bool { self == .complete || self == .incomplete || self == .failed }
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

    /// The student's materials (F02). LOCAL-FIRST, and the store owns where they live (D24): the
    /// app never uploads a source file, because the model that reads it runs here too.
    /// Protocol-backed so a screen can be previewed and tested with `InMemoryMaterialStore` and
    /// touch no disk at all.
    let materials: any MaterialStore

    /// The student's saved AI summaries (F03). LOCAL-FIRST, like `materials`, and owned by the
    /// same "no source file leaves the device" decision — a summary is derived from text that
    /// already lives here. Protocol-backed so a screen can be previewed and tested with
    /// `InMemorySummaryStore`.
    let summaries: any SummaryStore

    /// The three-tier AI router (F03). One place decides which engine runs a task, so no screen
    /// ever hard-codes an engine. Constructed here like every other service, so a preview or a
    /// test can swap in a router whose engines are all mocks.
    let ai: AIRouter

    /// The student's flashcard decks (F04). LOCAL-FIRST, like `materials` and `summaries`, so a
    /// review session works offline. Protocol-backed so screens can be previewed and tested with
    /// `InMemoryDeckStore`.
    let decks: any DeckStore

    /// The student's quizzes (F05). LOCAL-FIRST, like the other AI artefacts, so a quiz can be
    /// taken offline. Protocol-backed so screens can be previewed and tested with
    /// `InMemoryQuizStore`.
    let quizzes: any QuizStore

    /// The student's study plans (F06). LOCAL-FIRST, like the other derived artefacts, so the plan
    /// is viewable offline. Protocol-backed so screens can be previewed and tested with
    /// `InMemoryStudyPlanStore`.
    let studyPlans: any StudyPlanStore

    /// The student's shared study folders (F08). LOCAL-FIRST, like the other derived artefacts, so a
    /// folder is usable before a Firebase project is configured. Protocol-backed so screens can be
    /// previewed and tested with `InMemoryFolderStore`.
    let folders: any FolderStore

    /// The student's bookmark collections (F10). LOCAL-FIRST, like the other derived artefacts, so a
    /// collection is usable with no connection at all — which is the offline-first story I18 tells.
    /// Protocol-backed so screens can be previewed and tested with `InMemoryBookmarkStore`.
    let bookmarks: any BookmarkStore

    /// The student's group revision spaces (F09). LOCAL-FIRST, so the board, chat and live quiz are
    /// demonstrable before a realtime backend exists; the protocol is the seam that backend swaps in
    /// behind. Protocol-backed so screens can be previewed and tested with `InMemoryGroupStore`.
    let groups: any GroupStore

    /// The student's notification inbox and their notification choices (F14). LOCAL-FIRST, like the
    /// other derived stores, so the inbox renders with no project configured. Protocol-backed so
    /// screens can be previewed and tested with `InMemoryNotificationStore`.
    let notifications: any NotificationStore

    /// The system permission prompt, behind a protocol (F14, M02). Protocol-backed so the primer is
    /// previewable and testable without a real prompt appearing.
    let notificationAuthorizer: any NotificationAuthorizer

    /// The student's recent search queries (M05). Small and local, behind a protocol so the
    /// recent-searches rule is testable without touching the real `UserDefaults`.
    let recentSearches: any RecentSearchStore

    /// The platform's AI settings and the admin audit trail (F12, K07/K08). LOCAL-FIRST, so the admin
    /// panel is demonstrable before a backend serves `aiConfig`. Protocol-backed so screens can be
    /// previewed and tested with `InMemoryAIConfigurationStore`.
    let aiConfigurations: any AIConfigurationStore

    /// The platform directory (F12, K01–K03). A LOCAL STAND-IN for the cohort-wide `users` query: on
    /// device it starts empty and only a backend can fill it, which is why the roster screens are
    /// honest rather than invented. Protocol-backed so previews can seed `PlatformUser.samples`.
    let adminDirectory: any AdminDirectoryStore

    /// The account's entitlement and payment receipts (F13). LOCAL-FIRST, like the other
    /// derived stores, so the paywall and the manage screen are demonstrable before a Tap
    /// account and a Blaze plan exist (docs/09 D22). Protocol-backed so screens can be
    /// previewed and tested with `InMemorySubscriptionStore`.
    let subscriptions: any SubscriptionStore

    /// Whoever takes the money (F13). Protocol-backed so `SimulatedTapGateway` serves the
    /// demo and the tests while `TapPaymentsGateway` / `StoreKitGateway` remain the swap-in
    /// seam that docs/04 §6's App-Store-compliance argument depends on.
    let payments: any PaymentGateway

    /// The tutor studio's courses, roster, review queue and announcements (F11). LOCAL-FIRST,
    /// like the other derived stores, so the studio is demonstrable before a Firebase project and
    /// a tutor role claim exist (docs/09 D22). Protocol-backed so screens can be previewed and
    /// tested with `InMemoryCourseStore`.
    let courses: any CourseStore

    /// The student's coach conversations and their answer ratings (F15). LOCAL-FIRST, like the
    /// other derived stores, so the companion is demonstrable before a Firebase project exists.
    let coach: any CoachStore

    /// The on-device retrieval index (F15). The vectors never leave the device — see
    /// `LocalRetrievalService` for why that is a privacy decision rather than a storage one.
    let retrieval: any RetrievalService

    /// The adaptive study-path planner (F15, M3's layer).
    let coachPlanner: any CoachPlanningService

    /// Retrieval plus grounded answering (F15). Built here so the router and the library it reads
    /// through are the same ones every other feature uses.
    let coachService: CoachService

    /// The signed-in user, or `nil` before authentication completes.
    /// Drives `RootView`'s routing.
    var session: UserSession?

    /// True once auth has answered for the first time. Distinguishes "not signed in"
    /// from "we don't know yet" — the difference between a correct launch and a
    /// sign-in screen that flashes and disappears.
    var hasResolvedAuth: Bool

    /// Where the signed-in student is in the profile wizard, according to the server.
    /// Drives `RootView`'s choice between the wizard and the home screen.
    ///
    /// Settable so a preview or a test can put the app in a known state, exactly as
    /// `hasResolvedAuth` is, and because the DEBUG launch arguments need to.
    var profileStatus: ProfileStatus = .unknown

    /// The document the last `resolveProfile()` read, kept for the wizard.
    ///
    /// Two things need it and neither can ask for it again without a second round trip: the
    /// wizard opens at the first step this profile has NOT answered, and the confirmation
    /// screen summarises the steps it HAS.
    private(set) var storedProfile: StoredProfile?

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
        // Defaulted so a container built for a preview or a test needs no disk: see `materials`.
        materials: any MaterialStore = InMemoryMaterialStore(),
        summaries: any SummaryStore = InMemorySummaryStore(),
        ai: AIRouter = AIRouter.standard(governor: AICostGovernor()),
        decks: any DeckStore = InMemoryDeckStore(),
        quizzes: any QuizStore = InMemoryQuizStore(),
        studyPlans: any StudyPlanStore = InMemoryStudyPlanStore(),
        folders: any FolderStore = InMemoryFolderStore(),
        bookmarks: any BookmarkStore = InMemoryBookmarkStore(),
        groups: any GroupStore = InMemoryGroupStore(),
        notifications: any NotificationStore = InMemoryNotificationStore(),
        notificationAuthorizer: any NotificationAuthorizer = InMemoryNotificationAuthorizer(),
        recentSearches: any RecentSearchStore = InMemoryRecentSearchStore(),
        aiConfigurations: any AIConfigurationStore = InMemoryAIConfigurationStore(),
        adminDirectory: any AdminDirectoryStore = InMemoryAdminDirectoryStore(),
        // Defaulted so a preview or a test gets an in-memory entitlement store and a
        // simulated gateway — no disk, no network, no Firebase project.
        subscriptions: any SubscriptionStore = InMemorySubscriptionStore(),
        payments: (any PaymentGateway)? = nil,
        courses: any CourseStore = InMemoryCourseStore(),
        coach: any CoachStore = InMemoryCoachStore(),
        retrieval: any RetrievalService = LocalRetrievalService(),
        coachPlanner: any CoachPlanningService = LocalCoachPlanner(),
        coachService: CoachService? = nil,
        onboarding: any OnboardingStore = UserDefaultsOnboardingStore()
    ) {
        self.environment = environment
        self.firebaseSource = firebaseSource
        self.auth = auth
        self.profile = profile
        self.materials = materials
        self.summaries = summaries
        self.ai = ai
        self.decks = decks
        self.quizzes = quizzes
        self.studyPlans = studyPlans
        self.folders = folders
        self.bookmarks = bookmarks
        self.groups = groups
        self.notifications = notifications
        self.notificationAuthorizer = notificationAuthorizer
        self.recentSearches = recentSearches
        self.aiConfigurations = aiConfigurations
        self.adminDirectory = adminDirectory
        self.subscriptions = subscriptions
        // The gateway defaults to one that writes through THIS store, so an entitlement and
        // its receipt can never end up in different places.
        self.payments = payments ?? SimulatedTapGateway(store: subscriptions)
        self.courses = courses
        self.coach = coach
        self.retrieval = retrieval
        self.coachPlanner = coachPlanner
        // Built from the router and library above rather than injected, so a preview or a test that
        // swaps either one gets a coach that follows it.
        self.coachService = coachService
            ?? CoachService(retrieval: retrieval, router: ai, materials: materials)
        self.onboarding = onboarding
        self.hasResolvedAuth = false
        self.session = auth.currentSession()
    }

    /// Pushes the stored admin AI configuration into the live router and governor.
    ///
    /// Called at launch and again whenever the admin saves, so the settings are never only on disk.
    func applyAIConfiguration() async {
        guard let configuration = try? await aiConfigurations.configuration() else { return }
        ai.policy = configuration.policy
        ai.governor.limitOverride = configuration.dailyQuotaOverride
    }

    /// Begins observing authentication state.
    ///
    /// Called once from the app's launch, not from an initialiser, so that a container
    /// built for a preview or a test does not silently start a background subscription.
    func start() {
        guard authObservation.withLock({ $0 == nil }) else { return }

        // The admin's AI settings are applied once at launch, so the FIRST generation of the session
        // already obeys the policy the panel last saved (F12, K07) rather than only the next one.
        Task { await applyAIConfiguration() }

        let task = Task { [weak self] in
            guard let stream = self?.auth.stateChanges() else { return }
            for await state in stream {
                guard let self else { return }
                self.session = state.session
                if state.isResolved { self.hasResolvedAuth = true }
                // Re-checked on every auth event, not just the first: a sign-out has to
                // clear the answer, and signing in as somebody else has to re-ask.
                await self.refreshProfileStatus(for: state.session)
            }
        }
        authObservation.withLock { $0 = task }
    }

    /// Asks the server whether the signed-in student has a profile, and records the answer.
    ///
    /// Called when a verified session appears and again when the student leaves the wizard's
    /// confirmation screen, so the next launch knows without being told. A call while a read
    /// is already in flight is ignored, so the two callers cannot produce two reads of the
    /// same document.
    func resolveProfile() async {
        guard profileStatus != .loading else { return }

        profileStatus = .loading
        do {
            let stored = try await profile.fetchProfile()
            storedProfile = stored
            profileStatus = (stored?.isComplete == true) ? .complete : .incomplete
        } catch {
            // "We could not ask" is an answer, not a reason to wait forever. The gate
            // deliberately does not block on it — see `ProfileStatus.failed`.
            storedProfile = nil
            profileStatus = .failed
        }
    }

    /// Keeps `profileStatus` honest as the session changes.
    ///
    /// The reset to `.unknown` when there is no verified user is load-bearing: leaving the
    /// previous answer in place would let the next person to sign in on this device launch
    /// straight past the wizard on the strength of somebody else's profile.
    private func refreshProfileStatus(for session: UserSession?) async {
        guard let session, session.isEmailVerified else {
            profileStatus = .unknown
            // The document goes with it: the next person to sign in must not inherit the
            // previous student's answers as the starting point of their wizard.
            storedProfile = nil
            return
        }
        await resolveProfile()
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

        // The library is local either way — there is no project to configure for it, because
        // D24 keeps materials on the device. `-seedLibrary` fills it with sample materials so the
        // screen can be shown without importing anything by hand (DEBUG only, like the other
        // hatches: a shipping build must never fabricate content).
        let materials: any MaterialStore = {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-seedLibrary") {
                return InMemoryMaterialStore(seededWith: Material.samples)
            }
            #endif
            return FileMaterialStore()
        }()

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
            profile: profile,
            materials: materials,
            summaries: FileSummaryStore(),
            decks: FileDeckStore(),
            quizzes: FileQuizStore(),
            studyPlans: FileStudyPlanStore(),
            folders: FileFolderStore(),
            bookmarks: FileBookmarkStore(),
            groups: FileGroupStore(),
            notifications: FileNotificationStore(),
            notificationAuthorizer: SystemNotificationAuthorizer(),
            recentSearches: UserDefaultsRecentSearchStore(),
            aiConfigurations: FileAIConfigurationStore(),
            adminDirectory: FileAdminDirectoryStore(),
            // Real builds persist the entitlement on device. The gateway stays the simulated
            // one until a Tap account exists; swapping it is the one-line change `payments:`
            // exists for.
            subscriptions: FileSubscriptionStore(),
            courses: FileCourseStore(),
            coach: FileCoachStore()
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
        hasCompletedOnboarding: Bool = true,
        profileStatus: ProfileStatus = .complete
    ) -> AppContainer {
        let auth = MockAuthService(
            initialState: session.map { AuthState.signedIn($0) } ?? .signedOut,
            latency: .zero
        )
        // No latency and no failure: a preview should show its final state, not a spinner it
        // has to be waited out.
        let profile = MockProfileService(latency: .zero)
        // The gate reads the profile service, so a preview that claims `.complete` must have a
        // document behind it. Otherwise the preview would render one screen while the gate
        // logic saw another — a preview that lies about the state it is demonstrating.
        if profileStatus == .complete { profile.seed(.preview) }

        let container = AppContainer(
            environment: .dev,
            firebaseSource: .localEmulator,
            auth: auth,
            profile: profile,
            // In-memory, never UserDefaults: a preview must not mutate the developer's
            // real onboarding flag.
            onboarding: InMemoryOnboardingStore(hasCompletedOnboarding: hasCompletedOnboarding)
        )
        // Set directly rather than by calling `start()`: a preview should render its
        // resolved state immediately, not flash a loading state first.
        container.hasResolvedAuth = true
        container.profileStatus = profileStatus
        // The document goes with the status: a preview of a screen that READS the profile —
        // B07's editor — would otherwise open empty while the gate claimed it was complete.
        if profileStatus == .complete { container.storedProfile = .preview }
        return container
    }
}

