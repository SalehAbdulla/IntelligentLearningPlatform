import Foundation
import Testing
@testable import StudyForge

@Suite("Tutor AI review drafts (F11)")
@MainActor
struct TutorReviewDrafterTests {

    private let text = PageMarker.forPage(3) + """
    A graph models pairwise relationships between objects. \
    Edges may be directed or undirected, and breadth-first search explores the graph level by level. \
    Depth-first search follows one branch as far as it can before backtracking. \
    A weighted graph stores a cost on every edge, which shortest-path algorithms such as Dijkstra use. \
    An adjacency list keeps each vertex with the vertices it connects to.
    """

    private func router() -> AIRouter {
        AIRouter(
            providers: [
                .onDevice: MockProvider(tier: .onDevice, latency: .zero),
                .firebaseAI: MockProvider(tier: .firebaseAI, latency: .zero)
            ],
            governor: AICostGovernor()
        )
    }

    @Test("Confidence follows the provenance and drops for discarded items or missing pages")
    func confidence() {
        #expect(TutorReviewDrafter.confidence(.high) == 0.9)
        #expect(TutorReviewDrafter.confidence(.low) == 0.55)
        #expect(TutorReviewDrafter.adjusted(0.9, dropped: 0, pages: [2]) == 0.9)
        #expect(abs(TutorReviewDrafter.adjusted(0.9, dropped: 2, pages: []) - 0.7) < 0.0001)
        #expect(TutorReviewDrafter.adjusted(0.1, dropped: 1, pages: []) == 0.05)
    }

    @Test("Drafts are written as readable text for the reviewer")
    func draftText() {
        let summary = AISummary(tldr: "Graphs model relationships.", keyPoints: ["BFS goes level by level.", " "], glossary: [])
        #expect(TutorReviewDrafter.summaryText(summary) == "Graphs model relationships.\n• BFS goes level by level.")

        let cards = [AIFlashcard(front: "What is BFS?", back: "Level-by-level search.", difficulty: 1)]
        #expect(TutorReviewDrafter.flashcardText(cards) == TutorStudioCopy.cardDraft("What is BFS?", "Level-by-level search."))

        let question = QuizQuestion(
            stem: "Which search goes level by level?",
            options: ["DFS", "BFS"],
            correctOptionIndex: 1,
            explanation: "",
            topic: "Graphs",
            provenance: AIProvenance(materialId: "m", pageNumbers: [3], confidence: .high)
        )
        #expect(TutorReviewDrafter.quizText([question]) == TutorStudioCopy.questionDraft(1, "Which search goes level by level?", "BFS"))
    }

    @Test("The source snippet comes from the cited page and is trimmed")
    func snippet() {
        let snippet = TutorReviewDrafter.snippet(from: text, pages: [3])
        #expect(snippet.hasPrefix("A graph models pairwise relationships"))
        #expect(snippet.count <= TutorReviewDrafter.snippetLength + 1)
        #expect(snippet.hasSuffix("…"))
        #expect(TutorReviewDrafter.snippet(from: "Short text.", pages: []) == "Short text.")
    }

    @Test("Publishing drafts a summary, cards and a quiz waiting for review")
    func draftsAllKinds() async {
        let material = Material(title: "Lecture 5 - Graphs", source: .text, text: text)
        let outcome = await TutorReviewDrafter(router: router()).drafts(
            for: material,
            courseId: "c1",
            kinds: Set(ReviewKind.allCases)
        )

        #expect(outcome.failures == 0)
        #expect(outcome.items.map(\.kind) == [.summary, .flashcards, .quiz])
        #expect(outcome.items.allSatisfy { $0.status == .pending && $0.courseId == "c1" && $0.materialId == material.id })
        #expect(outcome.items.allSatisfy { !$0.draft.isEmpty && !$0.sourceSnippet.isEmpty })
        #expect(outcome.items.allSatisfy { $0.confidence > 0 && $0.confidence < 1 })
    }

    @Test("Only the chosen kinds are drafted")
    func chosenKinds() async {
        let material = Material(title: "Graphs", source: .text, text: text)
        let outcome = await TutorReviewDrafter(router: router()).drafts(for: material, courseId: "c1", kinds: [.quiz])

        #expect(outcome.items.map(\.kind) == [.quiz])
    }

    @Test("A material the AI cannot read counts as failures, not drafts")
    func unreadable() async {
        let material = Material(title: "Empty", source: .text, text: "Too short.")
        let outcome = await TutorReviewDrafter(router: router()).drafts(for: material, courseId: "c1", kinds: Set(ReviewKind.allCases))

        #expect(outcome.items.isEmpty)
        #expect(outcome.failures == 3)
    }
}
