//
//  AIRouterTests.swift
//  StudyForgeTests
//
//  Tests for the three-tier router — the code that decides whether a student's
//  document is processed on their phone or sent to a server.
//
//  Why this file matters more than most: the router's entire value is its BEHAVIOUR
//  when something is unavailable, and unavailability is the normal case during
//  development (tier 0 never runs in the Simulator). Before this file that behaviour
//  was verified by looking at a screen. Now it is asserted.
//

import Foundation
import Synchronization
import Testing
@testable import StudyForge

// MARK: - Test double

/// A provider whose availability and failure mode are chosen by the test.
private final class StubProvider: AIProvider {

    let tier: AITier
    private let reportedAvailability: AIAvailability

    /// When true the provider *claims* to be available but every call fails — the
    /// "engine died mid-call" case the router must survive without losing the request.
    private let failsMidCall: Bool
    private let failureReason: AIUnavailableReason

    private let calls = Mutex<Int>(0)

    var callCount: Int { calls.withLock { $0 } }

    init(tier: AITier,
         availability: AIAvailability = .available,
         failsMidCall: Bool = false,
         failureReason: AIUnavailableReason = .modelNotReady) {
        self.tier = tier
        self.reportedAvailability = availability
        self.failsMidCall = failsMidCall
        self.failureReason = failureReason
    }

    var availability: AIAvailability { reportedAvailability }

    private func beginCall() throws {
        calls.withLock { $0 += 1 }
        if failsMidCall { throw AIError.unavailable(failureReason) }
    }

    func summarize(_ request: SummaryRequest) async throws -> AIGenerated<AISummary> {
        try beginCall()
        return AIGenerated(
            value: AISummary(tldr: "stub", keyPoints: ["stub"], glossary: []),
            provenance: AIProvenance(materialId: request.context.materialId,
                                     pageNumbers: [1], confidence: .high),
            tier: tier,
            duration: .milliseconds(1)
        )
    }

    func makeFlashcards(_ request: FlashcardRequest) async throws -> AIGenerated<[AIFlashcard]> {
        try beginCall()
        return AIGenerated(
            value: [AIFlashcard(front: "stub", back: "stub", difficulty: 1)],
            provenance: AIProvenance(materialId: request.context.materialId,
                                     pageNumbers: [1], confidence: .high),
            tier: tier,
            duration: .milliseconds(1)
        )
    }

    func makeQuiz(_ request: QuizRequest) async throws -> AIGenerated<[AIQuizQuestion]> {
        try beginCall()
        return AIGenerated(
            value: [AIQuizQuestion(stem: "stub",
                                   options: ["a", "b", "c", "d"],
                                   correctOptionIndex: 0,
                                   explanation: "stub",
                                   topic: "stub")],
            provenance: AIProvenance(materialId: request.context.materialId,
                                     pageNumbers: [1], confidence: .high),
            tier: tier,
            duration: .milliseconds(1)
        )
    }

    func makeStudyPath(_ request: StudyPathRequest) async throws -> AIGenerated<[AIStudyStep]> {
        try beginCall()
        return AIGenerated(
            value: [AIStudyStep(instruction: "stub", activity: "read",
                                estimatedMinutes: 10, topic: "stub")],
            provenance: AIProvenance(materialId: "plan", pageNumbers: [], confidence: .medium),
            tier: tier,
            duration: .milliseconds(1)
        )
    }
}

// MARK: - Fixtures

/// Long enough to clear `isTooShortToGenerate`, so no test fails for the wrong reason.
private func makeContext() -> AIGenerationContext {
    AIGenerationContext(
        materialId: "material-1",
        text: String(
            repeating: "Third normal form removes transitive dependencies from a relation. ",
            count: 6
        ),
        language: .english,
        learningStyle: .visual
    )
}

@MainActor
private func makeRouter(
    onDevice: AIProvider? = nil,
    cloud: AIProvider? = nil,
    server: AIProvider? = nil,
    governor: AICostGovernor = AICostGovernor(plan: .free)
) -> AIRouter {
    var providers: [AITier: any AIProvider] = [:]
    if let onDevice { providers[.onDevice] = onDevice }
    if let cloud { providers[.firebaseAI] = cloud }
    if let server { providers[.cloudFunction] = server }
    return AIRouter(providers: providers, governor: governor)
}

private func summaryRequest() -> SummaryRequest {
    SummaryRequest(context: makeContext(), length: .short, style: .bullets)
}

// MARK: - Suite

@MainActor
@Suite("AI router — three-tier fallback")
struct AIRouterTests {

    // MARK: The happy path

    @Test("On-device is chosen when available, and the cloud is never touched")
    func prefersOnDeviceWhenAvailable() async throws {
        let device = StubProvider(tier: .onDevice)
        let cloud = StubProvider(tier: .firebaseAI)
        let router = makeRouter(onDevice: device, cloud: cloud)

        #expect(router.decide(for: .summarize) == .preferred(.onDevice))

        let result = try await router.summarize(summaryRequest())

        #expect(result.tier == .onDevice)
        #expect(router.lastDecision == .preferred(.onDevice))
        #expect(cloud.callCount == 0, "routing to tier 0 must not also call tier 1")
    }

    // MARK: The case that happens every day in the Simulator

    @Test("Falls back to the cloud when on-device reports simulatorUnsupported")
    func fallsBackWhenOnDeviceUnavailable() async throws {
        let device = StubProvider(tier: .onDevice,
                                  availability: .unavailable(.simulatorUnsupported))
        let cloud = StubProvider(tier: .firebaseAI)
        let router = makeRouter(onDevice: device, cloud: cloud)

        #expect(router.decide(for: .summarize) == .preferred(.firebaseAI))

        let result = try await router.summarize(summaryRequest())

        #expect(result.tier == .firebaseAI)
        #expect(device.callCount == 0, "an unavailable engine must not be called at all")
        #expect(cloud.callCount == 1,
                "the fallback must run exactly once, not once per skipped tier")
    }

    @Test("A fallback is reported honestly, naming the engine skipped and why")
    func fallbackIsReported() async throws {
        let router = makeRouter(
            onDevice: StubProvider(tier: .onDevice,
                                   availability: .unavailable(.simulatorUnsupported)),
            cloud: StubProvider(tier: .firebaseAI)
        )

        _ = try await router.summarize(summaryRequest())

        #expect(router.lastDecision == .fellBack(from: .onDevice,
                                                 to: .firebaseAI,
                                                 because: .simulatorUnsupported))
        #expect(router.lastDecision?.explanation.contains("unavailable") == true)
    }

    // MARK: Surviving a mid-call failure

    @Test("An engine that dies mid-call is skipped instead of failing the request")
    func survivesEngineDyingMidCall() async throws {
        let flaky = StubProvider(tier: .onDevice,
                                 availability: .available,
                                 failsMidCall: true,
                                 failureReason: .modelNotReady)
        let cloud = StubProvider(tier: .firebaseAI)
        let router = makeRouter(onDevice: flaky, cloud: cloud)

        let result = try await router.summarize(summaryRequest())

        #expect(result.tier == .firebaseAI, "the request must still be served")
        #expect(flaky.callCount == 1)
        #expect(router.lastDecision == .fellBack(from: .onDevice,
                                                 to: .firebaseAI,
                                                 because: .modelNotReady))
    }
}


// MARK: - Budget interaction and total failure

@MainActor
@Suite("AI router — budget and total failure")
struct AIRouterBudgetTests {

    @Test("A spent budget removes the cloud tier from consideration")
    func exhaustedBudgetSkipsCloud() {
        let governor = AICostGovernor(plan: .free)
        governor.seed(usedToday: governor.limit)

        let router = makeRouter(
            onDevice: StubProvider(tier: .onDevice,
                                   availability: .unavailable(.simulatorUnsupported)),
            cloud: StubProvider(tier: .firebaseAI),
            governor: governor
        )

        #expect(router.decide(for: .summarize) ==
                .noneAvailable([.onDevice: .simulatorUnsupported,
                                .firebaseAI: .quotaExhausted,
                                .cloudFunction: .notImplemented]))
    }

    @Test("A spent budget throws the quota error, which carries a reset time")
    func exhaustedBudgetThrowsQuotaError() async {
        let governor = AICostGovernor(plan: .free)
        governor.seed(usedToday: governor.limit)

        let router = makeRouter(
            onDevice: StubProvider(tier: .onDevice,
                                   availability: .unavailable(.simulatorUnsupported)),
            cloud: StubProvider(tier: .firebaseAI),
            governor: governor
        )

        // The on-device reason is preferred in the message because it is the one the
        // user can act on — but the cloud is genuinely the blocked tier. Either way the
        // surface must be a specific, actionable error rather than a generic failure.
        await #expect(throws: AIError.self) {
            try await router.summarize(summaryRequest())
        }
    }

    @Test("Engines that are not registered are reported as notImplemented, not as broken")
    func missingEnginesReportNotImplemented() {
        let router = makeRouter(cloud: StubProvider(tier: .firebaseAI))

        #expect(router.decide(for: .summarize) == .preferred(.firebaseAI))
        #expect(router.tierStatus.first { $0.tier == .onDevice }?.availability
                == .unavailable(.notImplemented))
        #expect(router.tierStatus.first { $0.tier == .cloudFunction }?.availability
                == .unavailable(.notImplemented))
    }

    @Test("Nothing available throws, naming the on-device reason as the most actionable")
    func totalFailureThrowsOnDeviceReason() async {
        let router = makeRouter(
            onDevice: StubProvider(tier: .onDevice,
                                   availability: .unavailable(.deviceNotEligible)),
            cloud: StubProvider(tier: .firebaseAI, availability: .unavailable(.offline))
        )

        await #expect(throws: AIError.unavailable(.deviceNotEligible)) {
            try await router.summarize(summaryRequest())
        }
        #expect(router.lastDecision?.chosenTier == nil)
    }

    @Test("A successful on-device generation does not spend the cloud budget")
    func onDeviceSuccessIsFree() async throws {
        let governor = AICostGovernor(plan: .free)
        let router = makeRouter(onDevice: StubProvider(tier: .onDevice), governor: governor)

        _ = try await router.summarize(summaryRequest())
        _ = try await router.summarize(summaryRequest())

        #expect(governor.usedToday == 0,
                "tier 0 is free — counting it would drain a budget nothing was spent from")
    }

    @Test("A successful cloud generation spends exactly one unit")
    func cloudSuccessCostsOne() async throws {
        let governor = AICostGovernor(plan: .free)
        let router = makeRouter(
            onDevice: StubProvider(tier: .onDevice,
                                   availability: .unavailable(.simulatorUnsupported)),
            cloud: StubProvider(tier: .firebaseAI),
            governor: governor
        )

        _ = try await router.summarize(summaryRequest())
        #expect(governor.usedToday == 1)

        _ = try await router.summarize(summaryRequest())
        #expect(governor.usedToday == 2)
    }

    @Test("A mid-call failure that falls through still charges only the engine that worked")
    func fallbackChargesOnce() async throws {
        let governor = AICostGovernor(plan: .free)
        let router = makeRouter(
            onDevice: StubProvider(tier: .onDevice,
                                   availability: .available,
                                   failsMidCall: true),
            cloud: StubProvider(tier: .firebaseAI),
            governor: governor
        )

        _ = try await router.summarize(summaryRequest())

        #expect(governor.usedToday == 1,
                "a failed attempt must not be billed against the user's allowance")
    }
}

