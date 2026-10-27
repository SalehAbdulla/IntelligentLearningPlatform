//
//  GeminiCloudProvider.swift
//  StudyForge
//
//  **Tier 1** — the Gemini Developer API, over HTTPS. This is the engine that makes the app
//  work in the Simulator, where tier 0 cannot run.
//
//  WHY THIS FILE EXISTS
//  --------------------
//  Until now tier 1 was `MockProvider`: deterministic stand-in output, wired in
//  `AIRouter.standard`. `MockProvider`'s own header explains why it existed — *"tier 0 cannot
//  run in the Simulator, and tier 1 needs Firebase credentials"* — and that was fine while the
//  AI screens were being built. It stops being fine the moment the app is demoed, because the
//  demo runs in the Simulator and every summary, card and quiz would be stand-in content.
//
//  WHY A REST CALL AND NOT THE FIREBASE AI LOGIC SDK
//  -------------------------------------------------
//  The plan said *"Firebase AI Logic, replacing the mock in S1"*. **That route is closed to
//  this team, not just to one member:** adding the `firebase-ai` product means editing
//  `StudyForge.xcodeproj`, and `tools/check-lane.sh` makes `*.xcodeproj` forbidden to every
//  member *including the owner* — measured on 28 Oct 2026. The project links only
//  `FirebaseAuth`, `FirebaseFirestore` and `FirebaseFunctions`.
//
//  The Gemini Developer API is the same engine Firebase AI Logic fronts, and it is reachable
//  with `URLSession`: no package, no project edit, and it works in the Simulator. **What is
//  given up is App Check** — a client-held key can be extracted from a repackaged build, which
//  is exactly what `docs/04` wants App Check for. For a course prototype with a rate-limited
//  free key that is a stated trade, not an oversight; see the note in `docs/04` §3.
//
//  RECORDED LANE EXCEPTION
//  -----------------------
//  `Core/AI/` is M2's lane. This file was written by the owner on 28 Oct 2026 **as a recorded
//  exception**, not bypassed: the guard was run, it refused, its own instruction is *"ask the
//  team. Do not force it"*, and the team lead authorised the crossing because tier 1 is the
//  demo's blocker. The exception is recorded in `docs/TODOLIST.md` §0 beside the J02 entry.
//  M2 keeps the rest of F15, including the `AITier.swift` marker and the prompt-template store.
//
//  STRUCTURED OUTPUT
//  -----------------
//  Every call sends `responseMimeType: "application/json"` **and** a `responseSchema`, so the
//  model returns a shape rather than prose. The schemas below mirror the `@Generable` types in
//  `AIGenerationModels.swift` field for field — those types are the contract, and a `Codable`
//  mirror is what lets a REST response satisfy it without making them `Codable`.
//
//  PROVENANCE IS STILL OURS
//  ------------------------
//  As in every other tier: the model produces content, the app attaches the citation. Nothing
//  here lets the model name a page or a chunk it was not given.
//

import Foundation

final class GeminiCloudProvider: AIProvider {

    let tier: AITier = .firebaseAI

    private let configuration: AICloudConfiguration
    private let session: URLSession

    init(configuration: AICloudConfiguration = .shared, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    /// Available exactly when a key is configured.
    ///
    /// Not a network probe: a reachability check here would make the router's decision
    /// time-dependent, and `AITier.offline` already exists for the case where the call fails
    /// for want of a connection.
    var availability: AIAvailability {
        configuration.isConfigured ? .available : .unavailable(.notImplemented)
    }

    // MARK: - Generation

    func summarize(_ request: SummaryRequest) async throws -> AIGenerated<AISummary> {
        try validate(request.context)
        let (payload, duration) = try await generate(
            SummaryPayload.self,
            schema: Self.summarySchema,
            instructions: PromptTemplates.instructions(for: request.context),
            prompt: PromptTemplates.summarize(request)
        )
        return wrap(payload.summary, duration: duration, context: request.context)
    }

    func makeFlashcards(_ request: FlashcardRequest) async throws -> AIGenerated<[AIFlashcard]> {
        try validate(request.context)
        let (payload, duration) = try await generate(
            FlashcardsPayload.self,
            schema: Self.flashcardsSchema,
            instructions: PromptTemplates.instructions(for: request.context),
            prompt: PromptTemplates.flashcards(request)
        )
        return wrap(payload.cards.map(\.card), duration: duration, context: request.context)
    }

    func makeQuiz(_ request: QuizRequest) async throws -> AIGenerated<[AIQuizQuestion]> {
        try validate(request.context)
        let (payload, duration) = try await generate(
            QuizPayload.self,
            schema: Self.quizSchema,
            instructions: PromptTemplates.instructions(for: request.context),
            prompt: PromptTemplates.quiz(request)
        )
        return wrap(payload.questions.map(\.question), duration: duration, context: request.context)
    }

    func makeStudyPath(_ request: StudyPathRequest) async throws -> AIGenerated<[AIStudyStep]> {
        let (payload, duration) = try await generate(
            StudyPathPayload.self,
            schema: Self.studyPathSchema,
            instructions: Self.studyPathInstructions(for: request),
            prompt: PromptTemplates.studyPath(request)
        )
        // No source document, so provenance is a plan reference rather than a page — the same
        // shape tier 0 returns, so the UI cannot tell the tiers apart by their provenance.
        return AIGenerated(
            value: payload.steps.map(\.step),
            provenance: AIProvenance(materialId: "study-plan", pageNumbers: [], confidence: .medium),
            tier: tier,
            duration: duration
        )
    }

    // MARK: - Grounded answering (F15)

    /// Answers from ONLY the retrieved passages, and **drops any citation the model invents**.
    ///
    /// The protocol's default throws rather than improvising, for a good reason: an ungrounded
    /// answer that sounds confident is the worst thing this feature could ship. So this tier
    /// implements it properly — and then enforces the grounding, because a model can cite an id it
    /// was never given, and a citation that can be invented is decoration rather than proof.
    func answer(_ prompt: AICoachPrompt) async throws -> AIGenerated<AICoachAnswer> {
        let passages = prompt.chunks
            .map { "[\($0.id)] \($0.text)" }
            .joined(separator: "\n\n")

        let (payload, duration) = try await generate(
            CoachPayload.self,
            schema: Self.coachSchema,
            instructions: Self.coachInstructions(depth: prompt.depth, language: prompt.language),
            prompt: "Question: \(prompt.question)\n\nPassages:\n\(passages)"
        )

        // Enforcement, not trust: an id the model was not given is dropped.
        let allowed = Set(prompt.chunks.map(\.id))
        let answer = AICoachAnswer(
            answer: payload.answer,
            citedChunkIds: payload.citedChunkIds.filter { allowed.contains($0) }
        )

        let pages = prompt.chunks.compactMap(\.page)
        return AIGenerated(
            value: answer,
            provenance: AIProvenance(
                materialId: prompt.chunks.first?.materialId ?? "coach",
                pageNumbers: Array(Set(pages)).sorted(),
                confidence: .medium
            ),
            tier: tier,
            duration: duration
        )
    }

    // MARK: - Transport

    /// One call, one measured generation.
    ///
    /// Deliberately not retried: a retry that doubles a free-tier request is how a quota disappears
    /// mid-demo, and `AICostGovernor` already owns the decision about whether a call should happen
    /// at all.
    private func generate<T: Decodable>(
        _ type: T.Type,
        schema: [String: Any],
        instructions: String,
        prompt: String
    ) async throws -> (T, Duration) {
        try requireAvailable()

        guard let key = configuration.apiKey else { throw AIError.unavailable(.notImplemented) }

        let url = configuration.baseURL
            .appendingPathComponent("models")
            .appendingPathComponent("\(configuration.model):generateContent")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // The key travels in a HEADER, never in the query string: query strings are logged by
        // proxies and captured in crash reports.
        request.setValue(key, forHTTPHeaderField: "x-goog-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "systemInstruction": ["parts": [["text": instructions]]],
            "contents": [["role": "user", "parts": [["text": prompt]]]],
            "generationConfig": [
                "responseMimeType": "application/json",
                "responseSchema": schema,
                "temperature": 0.4,
            ],
        ])

        let clock = ContinuousClock()
        let started = clock.now

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw mapTransport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AIError.generationFailed("The AI service returned no HTTP response.")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw mapStatus(http.statusCode, body: data)
        }

        let text = try Self.extractText(from: data)
        do {
            let decoded = try JSONDecoder().decode(T.self, from: Data(text.utf8))
            return (decoded, clock.now - started)
        } catch {
            throw AIError.invalidOutput(
                "The model returned a shape this app could not read: \(error.localizedDescription)"
            )
        }
    }

    private func requireAvailable() throws {
        if case .unavailable(let reason) = availability { throw AIError.unavailable(reason) }
    }

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

    // MARK: - Reading the response

    /// Pulls the JSON the model produced out of the API's envelope, or explains why there is none.
    ///
    /// A blocked prompt has no candidates at all, so it is reported as the block it is rather than
    /// as a decoding failure — the two need different fixes.
    private static func extractText(from data: Data) throws -> String {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AIError.invalidOutput("The AI service returned something that was not JSON.")
        }
        if let feedback = root["promptFeedback"] as? [String: Any],
           let blocked = feedback["blockReason"] as? String {
            throw AIError.generationFailed("The request was blocked by the safety filter (\(blocked)).")
        }
        guard let candidates = root["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String,
              !text.isEmpty else {
            throw AIError.invalidOutput("The AI service returned no content.")
        }
        return text
    }

    /// Maps HTTP status onto the app's own vocabulary, so no screen ever sees a status code.
    private func mapStatus(_ status: Int, body: Data) -> AIError {
        switch status {
        case 429:
            // The free tier is rate-limited by RPM/RPD/TPM. `.quotaExhausted` is the reason the
            // governor already knows how to explain, including when the allowance resets.
            return .unavailable(.quotaExhausted)
        case 401, 403:
            return .generationFailed("The AI key was rejected. Check GEMINI_API_KEY.")
        default:
            var message: String?
            if let root = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
               let error = root["error"] as? [String: Any] {
                message = error["message"] as? String
            }
            return .generationFailed(message ?? "The AI service returned HTTP \(status).")
        }
    }

    /// Transport failures keep their meaning: no connection is `.offline`, which the UI has copy
    /// for, rather than a generic server error that tells the student nothing.
    private func mapTransport(_ error: any Error) -> AIError {
        if error is CancellationError { return .cancelled }
        guard let urlError = error as? URLError else {
            return .generationFailed(String(describing: error))
        }
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            return .unavailable(.offline)
        case .timedOut:
            return .generationFailed("The AI service took too long to answer.")
        default:
            return .generationFailed(String(describing: urlError))
        }
    }
}

// MARK: - Wire shapes
//
// `Codable` mirrors of the `@Generable` contract in `AIGenerationModels.swift`. They exist so a
// REST response can satisfy types that were designed for guided generation, without making those
// types `Codable`: the contract stays in one place, and a field added there fails to map here
// rather than silently going missing.

private struct SummaryPayload: Decodable {
    struct Glossary: Decodable {
        let term: String
        let definition: String
    }

    let tldr: String
    let keyPoints: [String]
    let glossary: [Glossary]

    var summary: AISummary {
        AISummary(
            tldr: tldr,
            keyPoints: keyPoints,
            glossary: glossary.map { AIGlossaryTerm(term: $0.term, definition: $0.definition) }
        )
    }
}

private struct FlashcardsPayload: Decodable {
    struct Card: Decodable {
        let front: String
        let back: String
        let difficulty: Int

        var card: AIFlashcard { AIFlashcard(front: front, back: back, difficulty: difficulty) }
    }

    let cards: [Card]
}

private struct QuizPayload: Decodable {
    struct Question: Decodable {
        let stem: String
        let options: [String]
        let correctOptionIndex: Int
        let explanation: String
        let topic: String

        var question: AIQuizQuestion {
            AIQuizQuestion(
                stem: stem,
                options: options,
                correctOptionIndex: correctOptionIndex,
                explanation: explanation,
                topic: topic
            )
        }
    }

    let questions: [Question]
}

private struct StudyPathPayload: Decodable {
    struct Step: Decodable {
        let instruction: String
        let activity: String
        let estimatedMinutes: Int
        let topic: String

        var step: AIStudyStep {
            AIStudyStep(
                instruction: instruction,
                activity: activity,
                estimatedMinutes: estimatedMinutes,
                topic: topic
            )
        }
    }

    let steps: [Step]
}

private struct CoachPayload: Decodable {
    let answer: String
    let citedChunkIds: [String]
}

// MARK: - Schemas and instructions

extension GeminiCloudProvider {

    /// The OpenAPI subset the API accepts: uppercase type names, nested `items`, `required` arrays.
    ///
    /// **Computed rather than stored.** A `static let` of `[String: Any]` is shared non-`Sendable`
    /// state, which strict concurrency refuses — and the usual escape (`nonisolated(unsafe)`) would
    /// be silencing a real rule to save microseconds. A schema rebuilt per call costs nothing
    /// measurable and leaves no question to answer.
    private static var summarySchema: [String: Any] {
        [
            "type": "OBJECT",
            "properties": [
                "tldr": [
                    "type": "STRING",
                    "description": "A single-sentence takeaway a student could read on a bus. No preamble.",
                ],
                "keyPoints": [
                    "type": "ARRAY",
                    "description": "Between 3 and 7 key points, each one sentence, each a claim the source makes.",
                    "items": ["type": "STRING"],
                ],
                "glossary": [
                    "type": "ARRAY",
                    "description": "Technical terms from the material a student might need to look up.",
                    "items": [
                        "type": "OBJECT",
                        "properties": [
                            "term": ["type": "STRING", "description": "The term as it appears in the source."],
                            "definition": ["type": "STRING", "description": "A one-line definition the source supports."],
                        ],
                        "required": ["term", "definition"],
                    ],
                ],
            ],
            "required": ["tldr", "keyPoints", "glossary"],
        ]
    }

    private static var flashcardsSchema: [String: Any] {
        [
            "type": "OBJECT",
            "properties": [
                "cards": [
                    "type": "ARRAY",
                    "items": [
                        "type": "OBJECT",
                        "properties": [
                            "front": ["type": "STRING", "description": "The question side."],
                            "back": ["type": "STRING", "description": "The answer side, one or two sentences."],
                            "difficulty": [
                                "type": "INTEGER",
                                "description": "1 = simple fact, 2 = understanding, 3 = applying the idea.",
                            ],
                        ],
                        "required": ["front", "back", "difficulty"],
                    ],
                ],
            ],
            "required": ["cards"],
        ]
    }

    private static var quizSchema: [String: Any] {
        [
            "type": "OBJECT",
            "properties": [
                "questions": [
                    "type": "ARRAY",
                    "items": [
                        "type": "OBJECT",
                        "properties": [
                            "stem": ["type": "STRING", "description": "Answerable from the source material alone."],
                            "options": [
                                "type": "ARRAY",
                                "description": "Exactly four options, exactly one correct.",
                                "items": ["type": "STRING"],
                            ],
                            "correctOptionIndex": ["type": "INTEGER", "description": "Zero-based index into options."],
                            "explanation": ["type": "STRING", "description": "Why the correct answer is correct."],
                            "topic": ["type": "STRING", "description": "The single topic this question tests."],
                        ],
                        "required": ["stem", "options", "correctOptionIndex", "explanation", "topic"],
                    ],
                ],
            ],
            "required": ["questions"],
        ]
    }

    private static var studyPathSchema: [String: Any] {
        [
            "type": "OBJECT",
            "properties": [
                "steps": [
                    "type": "ARRAY",
                    "items": [
                        "type": "OBJECT",
                        "properties": [
                            "instruction": ["type": "STRING", "description": "A short imperative instruction."],
                            "activity": ["type": "STRING", "description": "read, flashcards, quiz or review."],
                            "estimatedMinutes": ["type": "INTEGER", "description": "Between 5 and 45."],
                            "topic": ["type": "STRING", "description": "Must match one of the weak topics supplied."],
                        ],
                        "required": ["instruction", "activity", "estimatedMinutes", "topic"],
                    ],
                ],
            ],
            "required": ["steps"],
        ]
    }

    private static var coachSchema: [String: Any] {
        [
            "type": "OBJECT",
            "properties": [
                "answer": [
                    "type": "STRING",
                    "description": "The answer, using only facts stated in the provided passages.",
                ],
                "citedChunkIds": [
                    "type": "ARRAY",
                    "description": "Ids of the provided passages that support the answer. Cite only ids that were given.",
                    "items": ["type": "STRING"],
                ],
            ],
            "required": ["answer", "citedChunkIds"],
        ]
    }

    // MARK: - Instructions

    /// A study path has no source document, so this prompt carries the plan's constraints instead
    /// of the grounding rule the other tasks inherit from `PromptTemplates.instructions(for:)`.
    private static func studyPathInstructions(for request: StudyPathRequest) -> String {
        """
        You are a revision planner. Produce an ordered set of steps that fits \
        \(request.minutesAvailable) minutes in total. \
        Use only the topics the student's weakness radar listed. Do not introduce new topics. \
        \(request.learningStyle.promptDirective)
        """
    }

    /// The coach is grounded by construction: the only knowledge it is given is the passages.
    ///
    /// The citation line is the one that matters — the model is told to cite only ids it was
    /// handed, and `answer(_:)` then drops anything else, so an invented citation cannot survive.
    private static func coachInstructions(depth: String, language: OutputLanguage) -> String {
        """
        Answer the student's question using ONLY the passages provided. \
        Never introduce outside knowledge. If the passages do not answer the question, say so \
        plainly and return an empty citedChunkIds. \
        In citedChunkIds, list only the bracketed ids that were given to you. \
        Explain at this depth: \(depth). \
        Write in \(language.rawValue).
        """
    }
}
