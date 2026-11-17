import Foundation

struct TutorDraftOutcome: Equatable {
    var items: [ReviewItem] = []
    var failures = 0
}

@MainActor
struct TutorReviewDrafter {

    nonisolated static let snippetLength = 280
    nonisolated static let cardCount = 10
    nonisolated static let questionCount = 5
    nonisolated static let droppedPenalty = 0.1
    nonisolated static let unsourcedPenalty = 0.1

    static let order: [ReviewKind] = [.summary, .flashcards, .quiz]

    let router: AIRouter
    var learningStyle: LearningStyle = .readWrite

    nonisolated static func confidence(_ level: AIConfidence) -> Double {
        switch level {
        case .high: 0.9
        case .medium: 0.75
        case .low: 0.55
        }
    }

    nonisolated static func adjusted(_ base: Double, dropped: Int, pages: [Int]) -> Double {
        var value = base
        if dropped > 0 { value -= droppedPenalty }
        if pages.isEmpty { value -= unsourcedPenalty }
        return min(max(value, 0.05), 0.99)
    }

    func drafts(
        for material: Material,
        courseId: String,
        kinds: Set<ReviewKind>,
        now: Date = .now
    ) async -> TutorDraftOutcome {
        var outcome = TutorDraftOutcome()
        let context = AIGenerationContext(
            materialId: material.id,
            text: material.text,
            language: .english,
            learningStyle: learningStyle
        )

        for kind in Self.order where kinds.contains(kind) {
            do {
                let (draft, confidence, pages) = try await generate(kind, context: context)
                guard !draft.isEmpty else {
                    outcome.failures += 1
                    continue
                }
                outcome.items.append(ReviewItem(
                    courseId: courseId,
                    materialId: material.id,
                    materialTitle: material.title,
                    kind: kind,
                    draft: draft,
                    sourceSnippet: Self.snippet(from: material.text, pages: pages),
                    confidence: confidence,
                    createdAt: now
                ))
            } catch {
                outcome.failures += 1
            }
        }
        return outcome
    }

    private func generate(_ kind: ReviewKind, context: AIGenerationContext) async throws -> (String, Double, [Int]) {
        switch kind {
        case .summary:
            let generated = try await router.summarize(SummaryRequest(context: context, length: .standard, style: .bullets))
            let pages = generated.provenance.pageNumbers
            return (
                Self.summaryText(generated.value),
                Self.adjusted(Self.confidence(generated.provenance.confidence), dropped: 0, pages: pages),
                pages
            )
        case .flashcards:
            let generated = try await router.makeFlashcards(
                FlashcardRequest(context: context, count: Self.cardCount, difficulty: .mixed)
            )
            let usable = generated.value.filter { !Self.clean($0.front).isEmpty && !Self.clean($0.back).isEmpty }
            let pages = generated.provenance.pageNumbers
            return (
                Self.flashcardText(usable),
                Self.adjusted(Self.confidence(generated.provenance.confidence), dropped: generated.value.count - usable.count, pages: pages),
                pages
            )
        case .quiz:
            let generated = try await router.makeQuiz(
                QuizRequest(context: context, questionCount: Self.questionCount, questionType: .multipleChoice)
            )
            let questions = QuizQuestionShaper.shaped(generated.value, type: .multipleChoice, provenance: generated.provenance)
            let pages = generated.provenance.pageNumbers
            return (
                Self.quizText(questions),
                Self.adjusted(Self.confidence(generated.provenance.confidence), dropped: generated.value.count - questions.count, pages: pages),
                pages
            )
        }
    }

    nonisolated static func summaryText(_ summary: AISummary) -> String {
        let points = summary.keyPoints.map(clean).filter { !$0.isEmpty }.map { "• \($0)" }
        return ([clean(summary.tldr)] + points).filter { !$0.isEmpty }.joined(separator: "\n")
    }

    nonisolated static func flashcardText(_ cards: [AIFlashcard]) -> String {
        cards.map { TutorStudioCopy.cardDraft(clean($0.front), clean($0.back)) }.joined(separator: "\n\n")
    }

    nonisolated static func quizText(_ questions: [QuizQuestion]) -> String {
        questions.enumerated().map { index, question in
            let answer = question.options.indices.contains(question.correctOptionIndex) ? question.options[question.correctOptionIndex] : ""
            return TutorStudioCopy.questionDraft(index + 1, question.stem, answer)
        }
        .joined(separator: "\n\n")
    }

    nonisolated static func snippet(from text: String, pages: [Int]) -> String {
        let sections = PageMarker.parse(text)
        let body: String
        if let first = pages.min(), let section = sections.first(where: { $0.page == first }) {
            body = section.body
        } else {
            body = sections.first?.body ?? text
        }
        let collapsed = body
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        guard collapsed.count > snippetLength else { return collapsed }
        return String(collapsed.prefix(snippetLength)) + "…"
    }

    nonisolated static func clean(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
