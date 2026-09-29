//
//  FirebaseBootstrap.swift
//  StudyForge
//
//  Configures Firebase at launch.
//
//  THE PROBLEM THIS SOLVES
//  -----------------------
//  `FirebaseApp.configure()` normally requires `GoogleService-Info.plist`, which ties
//  the app to a real Firebase project. That makes every Firebase-backed feature
//  undevelopable until somebody creates a project in the console — a human step that
//  can be blocked for days (a billing-profile failure, for example, as happened here).
//
//  The Firebase **Emulator Suite needs no project at all**. So this file supports two
//  configurations:
//
//    1. **Real**  — `GoogleService-Info.plist` is present → use the actual project.
//    2. **Local** — no plist → synthesise options against the demo project and point
//                   Auth + Firestore at the emulators on localhost.
//
//  Local is permitted ONLY in `.dev`. A staging or release build with no plist calls
//  `fatalError`, because silently running a release build against a fake project would
//  be far worse than failing immediately at launch.
//
//  WHY NOT JUST COMMIT A PLACEHOLDER PLIST?
//  ----------------------------------------
//  Because a placeholder plist is indistinguishable from a real one to a future
//  reader, and it is the exact file `.gitignore` exists to prevent leaking. Making the
//  fallback explicit in CODE means the configuration in use is always knowable.
//

import Foundation
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

/// Which configuration the app actually started with. Surfaced in diagnostics so
/// "why am I not seeing my data?" has a one-line answer.
enum FirebaseConfigurationSource: String, Sendable {
    /// A real Firebase project, driven by `GoogleService-Info.plist`.
    case realProject = "real-project"
    /// The local Emulator Suite, with no Firebase project involved.
    case localEmulator = "local-emulator"
    /// Deliberately not configured, because this process is a unit-test host.
    case skippedForTests = "skipped-for-tests"

    var displayName: String {
        switch self {
        case .realProject: "Firebase project"
        case .localEmulator: "Local emulator"
        case .skippedForTests: "Not configured (unit tests)"
        }
    }
}

enum FirebaseBootstrap {

    /// Must match the `--project` value the emulators are started with, and the
    /// `demo-` prefix is what tells Firebase this project is fully offline.
    static let localProjectID = "demo-studyforge"

    /// Emulator ports. Kept in step with `backend/firebase.json` by hand — they are
    /// configuration, not secrets.
    enum EmulatorPort {
        static let auth = 9099
        static let firestore = 8080
        static let storage = 9199
    }

    /// The host the emulators are reachable on.
    ///
    /// The Simulator shares the Mac's loopback interface, so `127.0.0.1` works there.
    /// A **physical device** does not — it needs the Mac's LAN IP, which is why this is
    /// overridable rather than hard-coded.
    static var emulatorHost: String {
        ProcessInfo.processInfo.environment["STUDYFORGE_EMULATOR_HOST"] ?? "127.0.0.1"
    }

    /// True when this process is a unit-test host.
    ///
    /// The tests use a host application, so `@main` runs and this bootstrap would
    /// otherwise configure Firebase for every test run — making each test inherit a
    /// connection attempt to a project or emulator it never uses. That is slow and
    /// non-hermetic: the tests deliberately exercise protocols and mocks instead.
    static var isRunningTests: Bool {
        NSClassFromString("XCTestCase") != nil
            || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || ProcessInfo.processInfo.environment["XCTestBundlePath"] != nil
    }

    /// Configures Firebase. Call once, before any other Firebase API.
    @discardableResult
    static func configure(environment: AppEnvironment) -> FirebaseConfigurationSource {
        if isRunningTests {
            return .skippedForTests
        }

        if hasRealConfiguration {
            FirebaseApp.configure()
            return .realProject
        }

        guard environment == .dev else {
            // Not a fallback: a deliberate hard stop. See the file header.
            fatalError("""
                GoogleService-Info.plist is missing and this is a \(environment.rawValue) \
                build. The local-emulator configuration is only permitted in Development.
                Add the plist to ios/StudyForge/StudyForge/ for staging and release builds.
                """)
        }

        FirebaseApp.configure(options: syntheticOptions())
        connectEmulators()
        return .localEmulator
    }

    private static var hasRealConfiguration: Bool {
        Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
    }

    /// Options for an emulator-only session.
    ///
    /// The API key is intentionally a placeholder: the emulators do not validate it.
    /// The values still have to be *shaped* correctly, because the SDK parses the
    /// `googleAppID` and fails early if it does not look like a real one.
    private static func syntheticOptions() -> FirebaseOptions {
        let options = FirebaseOptions(
            googleAppID: "1:000000000000:ios:0000000000000000",
            gcmSenderID: "000000000000"
        )
        options.projectID = localProjectID
        options.apiKey = "local-emulator-placeholder-key"
        options.bundleID = Bundle.main.bundleIdentifier ?? "com.studyforge.app"
        return options
    }

    /// Points every emulator-backed service at localhost.
    ///
    /// MUST be called after `configure`, and before the first Firestore read — calling
    /// `useEmulator` after Firestore has already opened a connection has no effect and
    /// fails silently, which is a genuinely nasty way to waste an afternoon.
    private static func connectEmulators() {
        let host = emulatorHost

        Auth.auth().useEmulator(withHost: host, port: EmulatorPort.auth)

        let settings = Firestore.firestore().settings
        settings.host = "\(host):\(EmulatorPort.firestore)"
        settings.cacheSettings = MemoryCacheSettings()
        // SSL is off because the emulator serves plain HTTP; leaving it on produces
        // an opaque connection failure rather than a clear one.
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings
    }
}
