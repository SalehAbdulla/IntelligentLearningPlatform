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
enum OutputLanguage: String, Sendable, CaseIterable, Codable {
    case english
    case arabic
}

// NOTE: `LearningStyle` lives in `Core/Profile/LearningStyle.swift`. It moved there when
// B02 made it something the student chooses and the app stores — that file explains why the
// profile owns it and this layer reads it. It is NOT defined here any more, so a prompt
// change that needs the style should import it from Core/Profile.
enum SummaryLength: String, Sendable, CaseIterable, Codable {
    case short, standard, examReady
}

enum SummaryStyle: String, Sendable, CaseIterable, Codable {
    case bullets, narrative, cornell
}

enum FlashcardDifficulty: String, Sendable, CaseIterable {
    case recall, understanding, mixed
}

enum QuizQuestionType: String, Sendable, CaseIterable, Codable {
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

    /// The shape the student asked for (E02's card-type selector).
    ///
    /// Defaulted to `.qa`, so a request that omits it produces the question-and-answer cards the
    /// app shipped with — and every existing call site keeps its behaviour. `var` rather than `let`
    /// on purpose: a `let` with a default is dropped from the memberwise initialiser, which would
    /// leave no way to ask for any other shape.
    var cardType: CardType = .qa
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

