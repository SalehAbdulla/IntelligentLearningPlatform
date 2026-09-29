//
//  MockProvider.swift
//  StudyForge
//
//  A deterministic AI engine for previews, tests and the Simulator.
//
//  WHY THIS IS NOT DEAD CODE
//  -------------------------
//  Tier 0 cannot run in the Simulator, and tier 1 needs Firebase credentials. Without
//  a mock, every AI screen would be un-developable and un-previewable until Sprint 3 —
//  which is exactly how a project ends up building UI it cannot test. The mock also
//  lets the AI cost governor and router be unit-tested without spending a token.
//
//  Output is DETERMINISTIC on purpose: the same source text always yields the same
//  cards, so a test can assert on them and a preview looks the same every time.
//

import Foundation

final class MockProvider: AIProvider {

    let tier: AITier

    /// Simulated latency, so the UI's loading states are exercised in previews.
    private let latency: Duration

    /// Lets a preview or test force the failure paths without special-casing UI code.
    private let forcedAvailability: AIAvailability

    init(tier: AITier = .firebaseAI,
         latency: Duration = .milliseconds(600),
         availability: AIAvailability = .available) {
        self.tier = tier
        self.latency = latency
        self.forcedAvailability = availability
    }

    var availability: AIAvailability { forcedAvailability }

    // MARK: - Generation

    func summarize(_ request: SummaryRequest) async throws -> AIGenerated<AISummary> {
        try validate(request.context)
        try await simulateWork()

        let sentences = Self.sentences(from: request.context.text)
        let summary = AISummary(
            tldr: sentences.first ?? "No extractable content was found in this material.",
            keyPoints: Array(sentences.prefix(5)),
            glossary: sentences.dropFirst(5).prefix(2).enumerated().map { index, sentence in
                AIGlossaryTerm(term: "Term \(index + 1)", definition: sentence)
            }
        )
        return wrap(summary, request.context, pageNumbers: [1])
    }

    func makeFlashcards(_ request: FlashcardRequest) async throws -> AIGenerated<[AIFlashcard]> {
        try validate(request.context)
        try await simulateWork()

        let sentences = Self.sentences(from: request.context.text)
        let cards = (0..<request.count).map { index in
            let sentence = sentences.isEmpty
                ? "Not enough source text to build this card."
                : sentences[index % sentences.count]
            return AIFlashcard(
                front: "Explain: \(sentence.prefix(60))",
                back: sentence,
                difficulty: (index % 3) + 1
            )
        }
        return wrap(cards, request.context, pageNumbers: [1])
    }

    func makeQuiz(_ request: QuizRequest) async throws -> AIGenerated<[AIQuizQuestion]> {
        try validate(request.context)
        try await simulateWork()

        let sentences = Self.sentences(from: request.context.text)
        let questions = (0..<request.questionCount).map { index in
            let correct = sentences.isEmpty ? "Not enough source text." : sentences[index % max(sentences.count, 1)]
            return AIQuizQuestion(
                stem: "Which statement matches the material? (\(index + 1))",
                options: [correct, "A plausible but unsupported claim.", "A contradiction.", "An unrelated fact."],
                correctOptionIndex: 0,
                explanation: "The material states: \(correct.prefix(80))",
                topic: "topic-\(index % 3)"
            )
        }
        return wrap(questions, request.context, pageNumbers: [1])
    }

    func makeStudyPath(_ request: StudyPathRequest) async throws -> AIGenerated<[AIStudyStep]> {
        try await simulateWork()

        // Weakest first — this is the behaviour under test in the adaptive planner,
        // so the mock reproduces it rather than returning arbitrary order.
        let ordered = request.weakTopics.sorted { $0.mastery < $1.mastery }
        var remaining = request.minutesAvailable
        var steps: [AIStudyStep] = []

        for topic in ordered where remaining >= 5 {
            let minutes = min(25, remaining)
            steps.append(AIStudyStep(
                instruction: "Review \(topic.topic) — currently \(Int(topic.mastery * 100))% mastery",
                activity: topic.mastery < 0.4 ? "read" : (topic.mastery < 0.7 ? "flashcards" : "quiz"),
                estimatedMinutes: minutes,
                topic: topic.topic
            ))
            remaining -= minutes
        }

        return AIGenerated(
            value: steps,
            provenance: AIProvenance(materialId: "study-plan", pageNumbers: [], confidence: .medium),
            tier: tier,
            duration: latency
        )
    }

    // MARK: - Helpers

    private func simulateWork() async throws {
        if case .unavailable(let reason) = forcedAvailability {
            throw AIError.unavailable(reason)
        }
        try await Task.sleep(for: latency)
    }

    private func wrap<T: Sendable & Equatable>(
        _ value: T,
        _ context: AIGenerationContext,
        pageNumbers: [Int]
    ) -> AIGenerated<T> {
        AIGenerated(
            value: value,
            provenance: provenance(for: context, pageNumbers: pageNumbers, confidence: .high),
            tier: tier,
            duration: latency
        )
    }

    /// Splits source text into sentences. Crude on purpose — it is a fixture, not a
    /// text-processing algorithm, and a simpler rule is easier to reason about.
    private static func sentences(from text: String) -> [String] {
        text
            .split(whereSeparator: { $0 == "." || $0 == "\n" })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 20 }
    }
}
