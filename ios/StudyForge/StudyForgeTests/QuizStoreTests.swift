//
//  QuizStoreTests.swift
//  StudyForgeTests
//
//  Tests for the quiz models and their stores.
//

import Foundation
import Testing
@testable import StudyForge

// MARK: - Model

@Suite("Quiz model")
struct QuizModelTests {

    private func question(id: String = "q1") -> QuizQuestion {
        QuizQuestion(
            id: id,
            stem: "What is 3NF?",
            options: ["A", "B", "C", "D"],
            correctOptionIndex: 0,
            explanation: "3NF removes transitive dependencies.",
            topic: "normalisation",
            provenance: AIProvenance(materialId: "m1", pageNumbers: [18], confidence: .high)
        )
    }

    private func quiz() -> Quiz {
        Quiz(
            id: "z1",
            title: "Normalisation",
            materialId: "m1",
            questionType: .multipleChoice,
            questions: [question()],
            attempts: [QuizAttempt(responses: [QuizResponse(questionId: "q1", selectedOptionIndex: 0, isCorrect: true)])]
        )
    }

    @Test("A quiz round-trips through JSON without losing its questions or attempts")
    func codableRoundTrip() throws {
        let original = quiz()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Quiz.self, from: data)

        #expect(decoded == original)
        #expect(decoded.questions.first?.correctOptionIndex == 0)
        #expect(decoded.attempts.first?.correctCount == 1)
    }

    @Test("An attempt totals its score")
    func attemptScore() {
        let attempt = QuizAttempt(responses: [
            QuizResponse(questionId: "q1", selectedOptionIndex: 0, isCorrect: true),
            QuizResponse(questionId: "q2", selectedOptionIndex: 1, isCorrect: false),
        ])
        #expect(attempt.correctCount == 1)
        #expect(attempt.totalCount == 2)
        #expect(attempt.scorePercent == 50)
    }
}

// MARK: - Store

@Suite("Quiz store")
struct QuizStoreTests {

    private func quiz(id: String, createdAt: Date) -> Quiz {
        Quiz(id: id, title: "Quiz", questionType: .mixed, questions: [], createdAt: createdAt)
    }

    @Test("The in-memory store returns quizzes newest first")
    func inMemoryOrdersNewestFirst() async throws {
        let store = InMemoryQuizStore(seededWith: [
            quiz(id: "old", createdAt: .now.addingTimeInterval(-3600)),
            quiz(id: "new", createdAt: .now),
        ])
        #expect(try await store.all().map(\.id) == ["new", "old"])
    }

    @Test("The in-memory store adds, looks up and deletes")
    func inMemoryCRUD() async throws {
        let store = InMemoryQuizStore()
        let record = quiz(id: "z1", createdAt: .now)

        try await store.add(record)
        #expect(try await store.quiz(id: "z1") == record)

        try await store.delete(id: "z1")
        #expect(try await store.quiz(id: "z1") == nil)
    }

    @Test("The in-memory store surfaces a forced failure")
    func inMemoryFailureIsReported() async {
        let store = InMemoryQuizStore()
        await store.forceFailure(.storageFailed)
        await #expect(throws: QuizError.self) {
            try await store.all()
        }
    }

    @Test("The file store persists quizzes across instances")
    func fileStorePersists() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("quiz-tests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        try await FileQuizStore(directory: directory).add(quiz(id: "z1", createdAt: .now))
        #expect(try await FileQuizStore(directory: directory).quiz(id: "z1")?.id == "z1")
    }

    @Test("Quiz store failures map to the app's single user-facing error")
    func errorMapsToAppError() {
        #expect(QuizError.storageFailed.asAppError == AppError.server(reference: "quiz-store-failed"))
    }
}
