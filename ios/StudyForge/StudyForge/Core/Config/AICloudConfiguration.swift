//
//  AICloudConfiguration.swift
//  StudyForge
//
//  Where tier 1 gets its key — and why the key is NOT in this file.
//
//  WHY THIS EXISTS
//  ---------------
//  Tier 1 is the only AI engine that can run in the Simulator: tier 0 (Apple Foundation
//  Models) needs Apple Intelligence hardware, so on a simulator the router falls through to
//  tier 1 for every AI screen. The demo therefore depends on this tier working.
//
//  Tier 1 is a plain HTTPS call to the Gemini API, which means it needs an API key — and a
//  key compiled into a repository is a key that is already leaked. So the key is read at
//  RUNTIME and never written into source. Two nets back that up: this file's precedence
//  order below, and `tools/commit.sh`, which scans every staged file for anything key-shaped
//  and refuses the commit.
//
//  HOW TO SET IT — either, first match wins
//  ----------------------------------------
//  1. **Scheme → Run → Arguments → Environment Variables**: `GEMINI_API_KEY = <your key>`.
//     Preferred, because an Xcode scheme's user data (`xcuserdata/`) is gitignored, so the
//     key is in no repository and in no diff.
//  2. **An `GEMINI_API_KEY` entry in `Info.plist`**, if you want the key to survive a launch
//     that did not come from Xcode. Read through `Bundle`, so it needs no rebuild-time wiring.
//
//  With neither set, `isConfigured` is false, the provider reports
//  `.unavailable(.notImplemented)`, and the router falls through with a NAMED reason instead
//  of failing at the tap. That is deliberate: a missing key is a configuration state, not a
//  crash, and the UI already knows how to explain every reason exhaustively.
//
//  THE MODEL NAME IS CONFIGURABLE ON PURPOSE
//  -----------------------------------------
//  Google renames and retires models. `GEMINI_MODEL` (environment or Info.plist) overrides
//  the default, so a rename is a setting rather than a code change — and a wrong name fails
//  with the API's own message rather than a mystery, because `GeminiCloudProvider` maps a
//  4xx through with the body it received.
//

import Foundation

/// The runtime configuration for the tier-1 cloud engine.
///
/// `Sendable`, so the provider can hold one and still satisfy `AIProvider`'s `Sendable`
/// requirement without an actor hop.
struct AICloudConfiguration: Sendable {

    /// Process-wide configuration. A `static let` on a `Sendable` value is race-free.
    static let shared = AICloudConfiguration()

    /// The key, or `nil` when the app has not been configured. Never logged, never rendered.
    let apiKey: String?

    /// Which model to call. Overridable so a model rename is a setting, not a code change.
    let model: String

    /// The API's base URL, held here so a test can point the provider at a stub server.
    let baseURL: URL

    init(
        apiKey: String? = AICloudConfiguration.readValue(for: "GEMINI_API_KEY"),
        model: String = AICloudConfiguration.readValue(for: "GEMINI_MODEL") ?? "gemini-2.5-flash",
        baseURL: URL = URL(string: "https://generativelanguage.googleapis.com/v1beta")!
    ) {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
    }

    /// Whether a usable key is present. The provider's `availability` is this and nothing else,
    /// so "why is the cloud tier unavailable" has exactly one answer to check.
    var isConfigured: Bool {
        guard let key = apiKey?.trimmingCharacters(in: .whitespacesAndNewlines) else { return false }
        return !key.isEmpty
    }

    // MARK: - Reading

    /// Environment first (local and gitignored), then `Info.plist` (survives a non-Xcode launch).
    ///
    /// Blank values are treated as absent rather than as an empty key, so a half-filled scheme
    /// variable reports "unconfigured" instead of sending an empty header and getting a 401.
    private static func readValue(for key: String) -> String? {
        if let fromEnvironment = ProcessInfo.processInfo.environment[key],
           !fromEnvironment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return fromEnvironment
        }
        if let fromBundle = Bundle.main.object(forInfoDictionaryKey: key) as? String,
           !fromBundle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return fromBundle
        }
        return nil
    }
}
