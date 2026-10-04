//
//  StudyPlanStore.swift
//  StudyForge
//
//  Where the student's study plans are kept, and the seam that hides WHERE.
//
//  LOCAL-FIRST, FOR THE SAME REASON DECKS AND QUIZZES ARE
//  ------------------------------------------------------
//  A plan must be viewable offline, and it is derived from the student's own profile answers. So
//  the durable home is a local file, and this protocol is the only place that knows that.
//

import Foundation

/// Reads and writes the student's study plans.
protocol StudyPlanStore: Sendable {

    /// Every plan, most recently updated first.
    func all() async throws -> [StudyPlan]

    /// One plan, or `nil` when nothing is stored under that id.
    func plan(id: String) async throws -> StudyPlan?

    /// Stores a plan, replacing any existing one with the same id. Marking a session done is the
    /// same call: the plan is rewritten with the updated session status.
    func add(_ plan: StudyPlan) async throws

    /// Removes a plan. Removing one that is already gone is not an error.
    func delete(id: String) async throws
}

/// Failures from the plan layer, in the app's own vocabulary.
enum StudyPlanError: Error, Equatable {

    /// The local store could not be read or written.
    case storageFailed

    /// Maps to the app's single user-facing error type.
    var asAppError: AppError {
        switch self {
        case .storageFailed:
            .server(reference: "study-plan-store-failed")
        }
    }
}
