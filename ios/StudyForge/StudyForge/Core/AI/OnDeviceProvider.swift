//
//  OnDeviceProvider.swift
//  StudyForge
//
//  **Tier 0** — Apple Foundation Models, running on the device.
//
//  This is the engine that makes StudyForge free, private and usable offline
//  (docs/04 §4). It is also the engine with the most caveats, and this file is
//  deliberately explicit about every one of them rather than hiding them behind a
//  generic "AI unavailable" message.
//
//  WHAT THIS FILE ASSUMES (proven by the S0 spike — research/spikes/)
//  ----------------------------------------------------------------
//  1. `SystemLanguageModel.default.availability` reports whether the on-device
//     model can run, and WHY not.
//  2. `LanguageModelSession.respond(to:generating:)` performs GUIDED GENERATION,
//     filling a `@Generable` type with structural guarantees.
//  3. The model does NOT run in the Simulator — so this provider reports
//     `.simulatorUnsupported` there and the router falls through to tier 1.
//

import Foundation
import FoundationModels

final class OnDeviceProvider: AIProvider {

    let tier: AITier = .onDevice

    // MARK: - Availability

    var availability: AIAvailability {
        #if targetEnvironment(simulator)
        // Apple's on-device model needs real hardware. Distinguishing this from a
        // device limitation matters: the demo runs on a device, but all development
        // happens in the Simulator, so this is the branch seen most often.
        return .unavailable(.simulatorUnsupported)
        #else
        switch SystemLanguageModel.default.availability {
        case .available:
            return .available

        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return .unavailable(.deviceNotEligible)
            case .appleIntelligenceNotEnabled:
                return .unavailable(.appleIntelligenceNotEnabled)
            case .modelNotReady:
                return .unavailable(.modelNotReady)
            @unknown default:
                // A future iOS could add a reason we do not know about. Treating it as
                // "not ready" is the honest option: it may resolve on its own.
                return .unavailable(.modelNotReady)
            }
        }
        #endif
    }

    // MARK: - Generation

    func summarize(_ request: SummaryRequest) async throws -> AIGenerated<AISummary> {
        try validate(request.context)
        let (value, duration) = try await respond(
            AISummary.self,
            instructions: PromptTemplates.instructions(for: request.context),
            prompt: PromptTemplates.summarize(request)
        )
        return wrap(value, duration: duration, context: request.context)
    }

    func makeFlashcards(_ request: FlashcardRequest) async throws -> AIGenerated<[AIFlashcard]> {
        try validate(request.context)
        let (value, duration) = try await respond(
            [AIFlashcard].self,
            instructions: PromptTemplates.instructions(for: request.context),
            prompt: PromptTemplates.flashcards(request)
        )
        return wrap(value, duration: duration, context: request.context)
    }

    func makeQuiz(_ request: QuizRequest) async throws -> AIGenerated<[AIQuizQuestion]> {
        try validate(request.context)
        let (value, duration) = try await respond(
            [AIQuizQuestion].self,
            instructions: PromptTemplates.instructions(for: request.context),
            prompt: PromptTemplates.quiz(request)
        )
        return wrap(value, duration: duration, context: request.context)
    }

    func makeStudyPath(_ request: StudyPathRequest) async throws -> AIGenerated<[AIStudyStep]> {
        // A study path describes the learner rather than quoting a document, so the
        // grounding rule is replaced with an explicit "do not invent topics" rule.
        let instructions = """
        You are StudyForge, planning a student's revision.

        Use only the topics the student listed. Do not introduce new topics. \
        \(request.learningStyle.promptDirective)
        """
        let (value, duration) = try await respond(
            [AIStudyStep].self,
            instructions: instructions,
            prompt: PromptTemplates.studyPath(request)
        )
        // No source document, so provenance is a plan reference rather than a page.
        return AIGenerated(
            value: value,
            provenance: AIProvenance(materialId: "study-plan", pageNumbers: [], confidence: .medium),
            tier: tier,
            duration: duration
        )
    }

    // MARK: - Plumbing

    /// Runs one guided generation and measures it.
    ///
    /// The session is created per call on purpose: a shared session would carry the
    /// previous material's context into the next request, which is exactly how a
    /// grounded app starts leaking content between courses.
    private func respond<T: Generable & Sendable>(
        _ type: T.Type,
        instructions: String,
        prompt: String
    ) async throws -> (value: T, duration: Duration) {
        try requireAvailable()

        let session = LanguageModelSession(instructions: instructions)
        let clock = ContinuousClock()
        let started = clock.now

        do {
            let response = try await session.respond(to: prompt, generating: T.self)
            return (response.content, clock.now - started)
        } catch {
            throw map(error)
        }
    }

    private func requireAvailable() throws {
        if case .unavailable(let reason) = availability {
            throw AIError.unavailable(reason)
        }
    }

    /// Confidence is derived from extraction quality, never from the model's own
    /// opinion of itself. With no page numbers we cannot cite, so confidence drops
    /// and the item is flagged for review rather than silently trusted.
    private func wrap<T: Sendable & Equatable>(
        _ value: T,
        duration: Duration,
        context: AIGenerationContext
    ) -> AIGenerated<T> {
        AIGenerated(
            value: value,
            provenance: provenance(for: context, pageNumbers: [], confidence: .medium),
            tier: tier,
            duration: duration
        )
    }

    /// Maps framework errors onto our vocabulary so no screen ever has to know
    /// about `GenerationError`.
    private func map(_ error: any Error) -> AIError {
        if error is CancellationError { return .cancelled }

        guard let generationError = error as? LanguageModelSession.GenerationError else {
            return .generationFailed(String(describing: error))
        }

        switch generationError {
        case .exceededContextWindowSize:
            return .sourceTooLong(tokens: 0, limit: 0)
        case .guardrailViolation:
            return .generationFailed("That request was blocked by the on-device safety filter.")
        case .assetsUnavailable:
            return .unavailable(.modelNotReady)
        case .unsupportedLanguageOrLocale:
            return .generationFailed("The on-device model does not support this language yet.")
        case .decodingFailure:
            return .invalidOutput("The model produced a response that did not match the expected shape.")
        default:
            return .generationFailed(String(describing: generationError))
        }
    }
}

