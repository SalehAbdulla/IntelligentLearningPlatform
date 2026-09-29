//
//  AIProvider.swift
//  StudyForge
//
//  The contract every AI engine conforms to, plus the request vocabulary.
//
//  WHY A PROTOCOL
//  --------------
//  Three engines must be swappable behind one interface: on-device (tier 0),
//  Firebase AI Logic (tier 1), and a Cloud Function (tier 2). A protocol also lets
//  every feature be developed and previewed against a mock — which is how the app
//  stays buildable in the Simulator, where tier 0 cannot run.
//

import Foundation

// MARK: - Output shaping

/// Output language. Arabic is first-class, not an afterthought (SDG 10).
enum OutputLanguage: String, Sendable, CaseIterable {
    case english
    case arabic
}

/// The learning-style profile that changes the SHAPE of generated content, not
/// just its wording — the concrete answer to the brief's "support different
/// learning styles" question (docs/00 §2).
///
/// This belongs with the user profile long-term; it lives here for now because it
/// is expressed through prompt templates.
enum LearningStyle: String, Sendable, CaseIterable {
    case visual
    case verbal
    case readWrite
    case kinesthetic

    var displayName: String {
        switch self {
        case .visual: "Visual"
        case .verbal: "Verbal"
        case .readWrite: "Read / write"
        case .kinesthetic: "Hands-on"
        }
    }

    /// How this style changes the generated output. Injected into every prompt.
    var promptDirective: String {
        switch self {
        case .visual:
            "Favour structure the reader can picture: grouped lists, comparisons, and spatial relationships. Where a process is described, present it as ordered steps."
        case .verbal:
            "Favour explanations that read as natural speech, as if explaining aloud to a classmate. Avoid dense notation."
        case .readWrite:
            "Favour well-organised written prose and precise definitions. Include the source's own terminology."
        case .kinesthetic:
            "Favour concrete examples, worked scenarios and 'what would happen if' applications rather than abstract statements."
        }
    }
}

enum SummaryLength: String, Sendable, CaseIterable {
    case short, standard, examReady
}

enum SummaryStyle: String, Sendable, CaseIterable {
    case bullets, narrative, cornell
}

enum FlashcardDifficulty: String, Sendable, CaseIterable {
    case recall, understanding, mixed
}

enum QuizQuestionType: String, Sendable, CaseIterable {
    case multipleChoice, trueFalse, shortAnswer, mixed
}

/// A mastery score for one topic, produced by the assessment engine (F05/F07).
struct TopicScore: Sendable, Equatable {
    let topic: String
    /// 0…1, where 1 is fully mastered. Drives the weakness radar and, in turn, the
    /// adaptive study path for the advanced feature F15.
    let mastery: Double
}

// MARK: - Requests

/// Context shared by every generation request.
struct AIGenerationContext: Sendable {
    let materialId: String
    /// The extracted TEXT. Never the file — tier 0 cannot see images, which is why
    /// multimodal tasks skip it in the router.
    let text: String
    let language: OutputLanguage
    let learningStyle: LearningStyle

    var isTooShortToGenerate: Bool { text.count < 200 }
}

struct SummaryRequest: Sendable {
    let context: AIGenerationContext
    let length: SummaryLength
    let style: SummaryStyle
}

struct FlashcardRequest: Sendable {
    let context: AIGenerationContext
    let count: Int
    let difficulty: FlashcardDifficulty
}

struct QuizRequest: Sendable {
    let context: AIGenerationContext
    let questionCount: Int
    let questionType: QuizQuestionType
}

struct StudyPathRequest: Sendable {
    let weakTopics: [TopicScore]
    let minutesAvailable: Int
    let language: OutputLanguage
    let learningStyle: LearningStyle
}

// MARK: - Result wrapper

/// A generated value plus the metadata needed to explain it.
///
/// Carrying `tier` and `duration` means the UI can honestly show "On-device · 1.2 s",
/// and the spike report can be produced from real measurements rather than guesses.
struct AIGenerated<Value: Sendable & Equatable>: Sendable, Equatable {
    let value: Value
    let provenance: AIProvenance
    let tier: AITier
    let duration: Duration
}

// MARK: - Errors

enum AIError: Error, Equatable {
    /// The engine cannot run — carries the exhaustive reason, not a string.
    case unavailable(AIUnavailableReason)
    /// The engine ran but failed.
    case generationFailed(String)
    /// Nothing worth generating from.
    case emptySource
    /// The source exceeds the engine's context window.
    case sourceTooLong(tokens: Int, limit: Int)
    /// The model returned something structurally invalid.
    case invalidOutput(String)
    case cancelled

    /// Maps onto the app's single user-facing error type, so no raw AI error ever
    /// reaches a screen (docs/04 §8).
    var asAppError: AppError {
        switch self {
        case .unavailable(.quotaExhausted):
            .aiQuotaExceeded(resetsAt: Self.nextMidnight())
        case .unavailable(.simulatorUnsupported),
             .unavailable(.deviceNotEligible),
             .unavailable(.appleIntelligenceNotEnabled),
             .unavailable(.modelNotReady):
            .onDeviceAIUnavailable
        case .unavailable(.offline):
            .offline
        case .unavailable(.notImplemented), .generationFailed, .invalidOutput:
            .server(reference: "ai-\(UUID().uuidString.prefix(6))")
        case .emptySource:
            .materialUnreadable(reason: "There wasn't enough text in that material to work with.")
        case .sourceTooLong:
            .materialUnreadable(reason: "That material is longer than this engine can take in one go.")
        case .cancelled:
            .unknown
        }
    }

    private static func nextMidnight() -> Date {
        Calendar.current.startOfDay(for: Date()).addingTimeInterval(86_400)
    }
}

// MARK: - The provider contract

/// An AI engine. Conformers are `Sendable`, so generation can move off the main
/// actor without data races.
protocol AIProvider: Sendable {

    /// Which tier this engine represents.
    var tier: AITier { get }

    /// Whether it can run right now. The router checks this before every call, so a
    /// dead engine is skipped rather than allowed to fail mid-generation.
    var availability: AIAvailability { get }

    func summarize(_ request: SummaryRequest) async throws -> AIGenerated<AISummary>

    func makeFlashcards(_ request: FlashcardRequest) async throws -> AIGenerated<[AIFlashcard]>

    func makeQuiz(_ request: QuizRequest) async throws -> AIGenerated<[AIQuizQuestion]>

    func makeStudyPath(_ request: StudyPathRequest) async throws -> AIGenerated<[AIStudyStep]>
}

extension AIProvider {

    /// Default guard so every engine fails the same honest way on empty input,
    /// instead of each inventing its own behaviour.
    func validate(_ context: AIGenerationContext) throws {
        guard !context.isTooShortToGenerate else { throw AIError.emptySource }
    }

    /// Builds provenance. Deliberately centralised: if provenance were assembled
    /// per engine, one engine would eventually forget it, and the citation feature
    /// would become unreliable exactly where it matters most.
    func provenance(for context: AIGenerationContext,
                    pageNumbers: [Int] = [],
                    confidence: AIConfidence) -> AIProvenance {
        AIProvenance(materialId: context.materialId,
                     pageNumbers: pageNumbers,
                     confidence: confidence)
    }
}

