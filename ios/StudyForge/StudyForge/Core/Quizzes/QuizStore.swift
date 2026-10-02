//
//  QuizStore.swift
//  StudyForge
//
//  Where the student's quizzes are kept, and the seam that hides WHERE.
//
//  LOCAL-FIRST, FOR THE SAME REASON DECKS ARE
//  ------------------------------------------
//  A quiz is derived from material that already lives on the device, and taking it must work in
//  aeroplane mode. So the durable home is a local file, and this protocol is the only place that
//  knows that.
//

import Foundation

/// Reads and writes the student's quizzes (questions and attempts together).
protocol QuizStore: Sendable {

    /// Every quiz, most recently created first.
    func all() async throws -> [Quiz]

    /// One quiz, or `nil` when nothing is stored under that id.
    func quiz(id: String) async throws -> Quiz?

    /// Stores a quiz, replacing any existing one with the same id. Recording an attempt is the same
    /// call: the quiz is rewritten with the new attempt appended.
    func add(_ quiz: Quiz) async throws

    /// Removes a quiz. Removing one that is already gone is not an error.
    func delete(id: String) async throws
}

/// Failures from the quiz layer, in the app's own vocabulary.
enum QuizError: Error, Equatable {

    /// The local store could not be read or written.
    case storageFailed

    /// Maps to the app's single user-facing error type.
    var asAppError: AppError {
        switch self {
        case .storageFailed:
            .server(reference: "quiz-store-failed")
        }
    }
}
