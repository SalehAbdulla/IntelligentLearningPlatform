//
//  InMemoryQuizStore.swift
//  StudyForge
//
//  A `QuizStore` that keeps everything in memory — previews and tests.
//
//  A REAL conformance rather than a stub, mirroring `InMemoryDeckStore`, so a screen driven by it
//  behaves exactly as it does against the file store.
//

import Foundation

actor InMemoryQuizStore: QuizStore {

    private var quizzes: [Quiz]

    /// When set, every call fails with it until cleared.
    private var failure: QuizError?

    init(seededWith quizzes: [Quiz] = []) {
        self.quizzes = quizzes
    }

    // MARK: QuizStore

    func all() async throws -> [Quiz] {
        try failIfForced()
        return quizzes.sorted { $0.createdAt > $1.createdAt }
    }

    func quiz(id: String) async throws -> Quiz? {
        try failIfForced()
        return quizzes.first { $0.id == id }
    }

    func add(_ quiz: Quiz) async throws {
        try failIfForced()
        if let index = quizzes.firstIndex(where: { $0.id == quiz.id }) {
            quizzes[index] = quiz
        } else {
            quizzes.append(quiz)
        }
    }

    func delete(id: String) async throws {
        try failIfForced()
        quizzes.removeAll { $0.id == id }
    }

    // MARK: Test and preview controls

    /// Forces every call to fail with `error`. Pass `nil` to restore success.
    func forceFailure(_ error: QuizError?) {
        failure = error
    }

    private func failIfForced() throws {
        if let failure { throw failure }
    }
}
