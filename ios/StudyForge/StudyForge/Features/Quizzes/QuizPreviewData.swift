import Foundation

enum QuizPreviewData {

    static let provenance = AIProvenance(materialId: "trees", pageNumbers: [12], confidence: .high)

    static var treesQuiz: Quiz {
        Quiz(
            id: "preview-trees",
            title: "Trees quiz 1",
            materialId: "trees",
            questionType: .mixed,
            questions: [
                QuizQuestion(
                    id: "q1",
                    stem: "Which traversal visits the root between its subtrees?",
                    options: ["Pre-order", "In-order", "Post-order", "Level-order"],
                    correctOptionIndex: 1,
                    explanation: "In-order traversal visits the left subtree, then the root, then the right subtree.",
                    topic: "Traversal",
                    provenance: provenance
                ),
                QuizQuestion(
                    id: "q2",
                    stem: "What is the height of a single-node tree?\nTrue or false: 1",
                    options: ["True", "False"],
                    correctOptionIndex: 1,
                    explanation: "Height is measured in edges, and a lone node has none, so its height is 0.",
                    topic: "Tree basics",
                    provenance: AIProvenance(materialId: "trees", pageNumbers: [14], confidence: .medium)
                ),
                QuizQuestion(
                    id: "q3",
                    stem: "What keeps an AVL tree balanced after an insert?",
                    options: ["Rotations"],
                    correctOptionIndex: 0,
                    explanation: "Single and double rotations restore the height difference of at most one.",
                    topic: "Balancing",
                    provenance: AIProvenance(materialId: "trees", pageNumbers: [18], confidence: .low)
                )
            ],
            timerMinutes: 15
        )
    }

    static var takenQuiz: Quiz {
        var quiz = treesQuiz
        quiz.attempts = [
            QuizAttempt(
                id: "a1",
                responses: [
                    QuizResponse(questionId: "q1", selectedOptionIndex: 1, isCorrect: true),
                    QuizResponse(questionId: "q2", selectedOptionIndex: 0, isCorrect: false),
                    QuizResponse(questionId: "q3", selectedOptionIndex: 0, isCorrect: false)
                ]
            )
        ]
        return quiz
    }

    static var takenRecord: QuizAttemptRecord {
        QuizAttemptRecord(
            id: "a1",
            quizId: "preview-trees",
            questionIds: ["q1", "q2", "q3"],
            durationSeconds: 492,
            typedAnswers: ["q3": "rotate nodes"],
            credits: ["q3": .half]
        )
    }
}
