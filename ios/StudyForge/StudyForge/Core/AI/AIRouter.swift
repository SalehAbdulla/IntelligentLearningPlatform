//
//  AIRouter.swift
//  StudyForge
//
//  The **three-tier AI router**. One place decides which engine runs a task, so no
//  feature ever hard-codes an engine.
//
//  THE POLICY IN ONE PARAGRAPH
//  ---------------------------
//  Each task declares a preference order (docs/04 §4). The router walks that order,
//  skipping any tier that is unavailable and any cloud tier whose budget is spent,
//  then executes on the first that works. If a tier fails MID-call it falls through
//  to the next, so a dropped connection degrades rather than breaking.
//
//  What this buys us:
//    · **Free**    — tier 0 covers the common case, so the tier-1 free quota lasts.
//    · **Offline** — with no network, tier 0 still generates.
//    · **Honest**  — the decision, and the reason for any fallback, is inspectable.
//

import Foundation

@MainActor
@Observable
final class AIRouter {

    /// Registered engines, keyed by tier. A missing entry means "not built yet".
    private let providers: [AITier: any AIProvider]
    private let governor: AICostGovernor

    /// The most recent routing decision, so the UI can explain what happened — for
    /// example why a generation went to the cloud rather than staying on device.
    private(set) var lastDecision: AIRoutingDecision?

    init(providers: [AITier: any AIProvider], governor: AICostGovernor) {
        self.providers = providers
        self.governor = governor
    }

    /// Convenience factory: the real engine set for this build.
    static func standard(governor: AICostGovernor) -> AIRouter {
        AIRouter(
            providers: [
                .onDevice: OnDeviceProvider(),
                // Tier 1 arrives with the Firebase SDK in S1. Until then the mock
                // stands in, so every AI screen stays developable in the Simulator
                // instead of being blocked until Sprint 3.
                .firebaseAI: MockProvider(tier: .firebaseAI, latency: .milliseconds(400)),
            ],
            governor: governor
        )
    }

    // MARK: - Status

    /// Every tier this build knows about, with its live availability. Drives the
    /// spike screen and any future diagnostics view.
    var tierStatus: [(tier: AITier, availability: AIAvailability)] {
        AITier.allCases.map { tier in
            (tier, providers[tier]?.availability ?? .unavailable(.notImplemented))
        }
    }

    /// Predicts the routing outcome WITHOUT running anything — used to disable a
    /// button with an honest reason rather than letting the user tap into a failure.
    func decide(for task: AITask) -> AIRoutingDecision {
        var reasons: [AITier: AIUnavailableReason] = [:]

        for tier in task.tierPreference {
            guard let provider = providers[tier] else {
                reasons[tier] = .notImplemented
                continue
            }
            if case .unavailable(let reason) = provider.availability {
                reasons[tier] = reason
                continue
            }
            if tier != .onDevice, !governor.hasBudget {
                reasons[tier] = .quotaExhausted
                continue
            }
            return .preferred(tier)
        }
        return .noneAvailable(reasons)
    }

    // MARK: - Generation

    func summarize(_ request: SummaryRequest) async throws -> AIGenerated<AISummary> {
        try await execute(task: .summarize) { try await $0.summarize(request) }
    }

    func makeFlashcards(_ request: FlashcardRequest) async throws -> AIGenerated<[AIFlashcard]> {
        try await execute(task: .makeFlashcards) { try await $0.makeFlashcards(request) }
    }

    func makeQuiz(_ request: QuizRequest) async throws -> AIGenerated<[AIQuizQuestion]> {
        try await execute(task: .makeQuiz) { try await $0.makeQuiz(request) }
    }

    func makeStudyPath(_ request: StudyPathRequest) async throws -> AIGenerated<[AIStudyStep]> {
        try await execute(task: .studyPath) { try await $0.makeStudyPath(request) }
    }
}

// MARK: - The policy

extension AIRouter {

    /// Walks the task's tier preference and executes on the first workable tier.
    ///
    /// Inherits the type's `@MainActor` isolation. Generation is `await`ed, so the
    /// main actor is yielded during the call rather than blocked by it.
    fileprivate func execute<T: Sendable & Equatable>(
        task: AITask,
        using operation: (any AIProvider) async throws -> AIGenerated<T>
    ) async throws -> AIGenerated<T> {

        var reasons: [AITier: AIUnavailableReason] = [:]
        var fallbackFrom: AITier?

        for tier in task.tierPreference {
            guard let provider = providers[tier] else {
                reasons[tier] = .notImplemented
                fallbackFrom = fallbackFrom ?? tier
                continue
            }

            if case .unavailable(let reason) = provider.availability {
                reasons[tier] = reason
                fallbackFrom = fallbackFrom ?? tier
                continue
            }

            // Only cloud tiers consume budget. Tier 0 is free and unlimited, which is
            // the whole point of routing to it first.
            if tier != .onDevice, !governor.hasBudget {
                reasons[tier] = .quotaExhausted
                fallbackFrom = fallbackFrom ?? tier
                continue
            }

            do {
                let result = try await operation(provider)
                governor.record(tier: tier, task: task)
                lastDecision = decision(served: tier, fallbackFrom: fallbackFrom, reasons: reasons)
                return result

            } catch let error as AIError {
                // An engine that dies MID-call is skipped rather than fatal, so a
                // dropped connection becomes a fallback instead of a failure.
                if case .unavailable(let reason) = error {
                    reasons[tier] = reason
                    fallbackFrom = fallbackFrom ?? tier
                    continue
                }
                throw error
            }
        }

        lastDecision = .noneAvailable(reasons)
        // Surface the most actionable reason, preferring the on-device explanation
        // because it is the one the user can usually act on.
        throw AIError.unavailable(reasons[.onDevice] ?? reasons.values.first ?? .notImplemented)
    }

    /// Reports a fallback honestly rather than claiming the preferred tier was used.
    /// The UI shows this, and a false claim about where material went would
    /// undermine the privacy promise.
    private func decision(
        served tier: AITier,
        fallbackFrom: AITier?,
        reasons: [AITier: AIUnavailableReason]
    ) -> AIRoutingDecision {
        if let from = fallbackFrom, let reason = reasons[from] {
            return .fellBack(from: from, to: tier, because: reason)
        }
        return .preferred(tier)
    }
}

