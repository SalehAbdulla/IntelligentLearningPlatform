import Foundation
import Testing
@testable import StudyForge

@Suite("Quiz prompt (F05)")
struct QuizPromptTests {

    private func request(
        type: QuizQuestionType = .mixed,
        difficulty: QuizDifficulty = .medium,
        focus: [String] = []
    ) -> QuizRequest {
        QuizRequest(
            context: AIGenerationContext(
                materialId: "m",
                text: String(repeating: "Trees have a root and leaves. ", count: 10),
                language: .english,
                learningStyle: .visual
            ),
            questionCount: 8,
            questionType: type,
            difficulty: difficulty,
            focusTopics: focus
        )
    }

    @Test("The prompt asks for the chosen difficulty")
    func difficultyInPrompt() {
        for level in QuizDifficulty.allCases {
            #expect(PromptTemplates.quiz(request(difficulty: level)).contains(level.promptGuidance))
        }
    }

    @Test("Focus topics are named when given and the whole material is covered otherwise")
    func focusInPrompt() {
        #expect(PromptTemplates.quiz(request(focus: ["AVL trees", "traversal"])).contains("AVL trees, traversal"))
        #expect(PromptTemplates.quiz(request()).contains("Cover the material evenly."))
    }

    @Test("Short answer quizzes ask for a brief model answer")
    func shortAnswerGuidance() {
        #expect(PromptTemplates.quiz(request(type: .shortAnswer)).contains("model answer"))
    }

    @Test("A request without the new fields keeps the old defaults")
    func defaults() {
        let plain = QuizRequest(
            context: request().context,
            questionCount: 5,
            questionType: .multipleChoice
        )

        #expect(plain.difficulty == .medium)
        #expect(plain.focusTopics.isEmpty)
    }
}
