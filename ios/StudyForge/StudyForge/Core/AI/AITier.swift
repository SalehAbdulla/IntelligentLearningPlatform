//
//  AITier.swift
//  StudyForge
//
//  The vocabulary of the AI layer: which engine runs a task, and whether it can.
//
//  WHY THIS FILE EXISTS
//  --------------------
//  On-device-first is the decision that makes StudyForge free, private and
//  offline-capable (docs/04 §4). But it only works if the app is honest about WHEN
//  the on-device model is unavailable — which it is in the Simulator, on older
//  devices, and whenever Apple Intelligence is switched off.
//
//  So unavailability is modelled as DATA, not as an error string, and every reason
//  carries user-facing copy plus a recovery action.
//

import Foundation

// MARK: - Tier

/// The three execution tiers, in preference order.
enum AITier: String, Sendable, CaseIterable, Comparable, Codable {
    /// **Tier 0** — Apple Foundation Models, on-device. Free, private, offline.
    case onDevice = "on-device"
    /// **Tier 1** — Firebase AI Logic / Gemini free tier. Works in the Simulator;
    /// handles images and scanned pages.
    case firebaseAI = "firebase-ai"
    /// **Tier 2** — Cloud Function proxy. Heavy or queued jobs only; keeps API keys
    /// server-side. The only tier that can produce a bill, so it is used last.
    case cloudFunction = "cloud-function"

    var displayName: String {
        switch self {
        case .onDevice: "On-device"
        case .firebaseAI: "Cloud (Firebase AI)"
        case .cloudFunction: "Cloud (server)"
        }
    }

    /// Shown in the UI so a student knows where their material went.
    /// Privacy is a feature here, not a footnote.
    var privacyNote: String {
        switch self {
        case .onDevice: "Runs privately on your device. Nothing is uploaded."
        case .firebaseAI: "Sends only the extracted text to Google's Gemini API."
        case .cloudFunction: "Processed on our server, then discarded."
        }
    }

    private var rank: Int {
        switch self {
        case .onDevice: 0
        case .firebaseAI: 1
        case .cloudFunction: 2
        }
    }

    static func < (lhs: AITier, rhs: AITier) -> Bool { lhs.rank < rhs.rank }
}

// MARK: - Availability

/// Whether an engine can run right now, and if not, precisely why.
enum AIAvailability: Equatable, Sendable {
    case available
    case unavailable(AIUnavailableReason)

    var isAvailable: Bool {
        if case .available = self { return true }
        return false
    }

    var reason: AIUnavailableReason? {
        if case .unavailable(let reason) = self { return reason }
        return nil
    }
}

/// Every way an engine can be unable to run. Modelled exhaustively so the UI never
/// has to invent a message or fall through to a generic error.
enum AIUnavailableReason: String, Sendable, CaseIterable {
    /// The device cannot run Apple Intelligence at all.
    case deviceNotEligible
    /// Eligible hardware, but Apple Intelligence is not enabled.
    case appleIntelligenceNotEnabled
    /// Enabled, but the model is still downloading or preparing.
    case modelNotReady
    /// Expected in the Simulator: on-device AI does not run there.
    case simulatorUnsupported
    /// The engine exists but is not wired up in this build.
    case notImplemented
    /// No connectivity, and the task needs a cloud tier.
    case offline
    /// The daily generation budget is spent.
    case quotaExhausted
    /// The admin's routing policy forbids the cloud, and this task cannot run on-device.
    case policyOfflineOnly

    /// Plain-language title. No jargon, no blame (docs/06 §4.3).
    var title: String {
        switch self {
        case .deviceNotEligible: "This device can't run StudyForge AI offline"
        case .appleIntelligenceNotEnabled: "Turn on Apple Intelligence to work offline"
        case .modelNotReady: "The offline model is still getting ready"
        case .simulatorUnsupported: "Offline AI isn't available in the Simulator"
        case .notImplemented: "Not available in this build"
        case .offline: "You're offline"
        case .quotaExhausted: "You've reached today's AI limit"
        case .policyOfflineOnly: "This task needs an internet connection"
        }
    }

    /// What happened, and what it means for the user's data.
    var message: String {
        switch self {
        case .deviceNotEligible:
            "Your iPhone can still use StudyForge AI over the internet, which sends only the text of the material you choose."
        case .appleIntelligenceNotEnabled:
            "With Apple Intelligence on, summaries and flashcards can be generated privately on your iPhone, even with no signal."
        case .modelNotReady:
            "iOS is still downloading the on-device model. This normally finishes within a few minutes on Wi-Fi."
        case .simulatorUnsupported:
            "Apple's on-device model needs real hardware. On a physical device with Apple Intelligence enabled, this runs privately with no network."
        case .notImplemented:
            "This engine is planned but not built yet — see the sprint plan."
        case .offline:
            "Reconnect to use the cloud engine, or switch to the on-device engine to keep working."
        case .quotaExhausted:
            "Your free generations reset tomorrow. On-device generation has no limit."
        case .policyOfflineOnly:
            "Your institution has set StudyForge to stay on-device. This task needs an internet connection, so it cannot run right now."
        }
    }

    /// The single best next step, or `nil` when there is nothing useful to offer.
    var recoveryAction: String? {
        switch self {
        case .deviceNotEligible: "Use the cloud engine"
        case .appleIntelligenceNotEnabled: "Open Settings"
        case .modelNotReady: "Try again shortly"
        case .simulatorUnsupported: "Use the cloud engine"
        case .notImplemented: nil
        case .offline: "Retry"
        case .quotaExhausted: "Use on-device instead"
        case .policyOfflineOnly: nil
        }
    }
}

// MARK: - Tasks

/// The generation tasks StudyForge supports. Each has its own preferred tier,
/// because the engines have genuinely different strengths (docs/04 §4).
enum AITask: String, Sendable, CaseIterable {
    case summarize
    case makeFlashcards
    case makeQuiz
    case coachAnswer
    case studyPath

    var displayName: String {
        switch self {
        case .summarize: "Summarise"
        case .makeFlashcards: "Make flashcards"
        case .makeQuiz: "Make a quiz"
        case .coachAnswer: "Answer a question"
        case .studyPath: "Build a study path"
        }
    }

    /// Nearest-first order of preference for this task.
    ///
    /// The short version: tier 0 is excellent at text transformation, while
    /// long-context reasoning and images belong on a cloud tier.
    var tierPreference: [AITier] {
        switch self {
        case .summarize, .makeFlashcards, .makeQuiz, .studyPath:
            [.onDevice, .firebaseAI, .cloudFunction]
        case .coachAnswer:
            // Answering needs a larger context window than tier 0 can promise, so
            // the cloud tier leads and on-device stays as the offline fallback.
            [.firebaseAI, .onDevice, .cloudFunction]
        }
    }

    /// Whether the task may need to see an image (a scan or a photograph).
    /// Tier 0 is text-only, so a multimodal task skips it entirely.
    var mayRequireMultimodalInput: Bool {
        switch self {
        case .summarize, .makeQuiz: true
        case .makeFlashcards, .coachAnswer, .studyPath: false
        }
    }

    /// Rough token estimate of the context this task needs, used by the router to
    /// avoid handing a 40-page document to a small on-device context window.
    var typicalContextTokens: Int {
        switch self {
        case .summarize: 4_000
        case .makeFlashcards: 3_000
        case .makeQuiz: 3_000
        case .coachAnswer: 8_000
        case .studyPath: 1_500
        }
    }
}

/// Why the router chose the tier it chose. Surfaced in the UI and in logs, so a
/// surprising result is explainable rather than mysterious.
enum AIRoutingDecision: Equatable, Sendable {
    case preferred(AITier)
    case fellBack(from: AITier, to: AITier, because: AIUnavailableReason)
    case noneAvailable([AITier: AIUnavailableReason])

    var chosenTier: AITier? {
        switch self {
        case .preferred(let tier): tier
        case .fellBack(_, let to, _): to
        case .noneAvailable: nil
        }
    }

    var explanation: String {
        switch self {
        case .preferred(let tier):
            "Using \(tier.displayName)."
        case .fellBack(let from, let to, let reason):
            "\(from.displayName) was unavailable (\(reason.rawValue)), so using \(to.displayName)."
        case .noneAvailable:
            "No AI engine is available right now."
        }
    }
}

