//
//  MockProfileService.swift
//  StudyForge
//
//  A deterministic `ProfileService` for previews, unit tests and offline development —
//  the counterpart to `MockAuthService`.
//
//  It records what was written rather than discarding it, because the assertions that
//  matter for the wizard are about the CONTENT of the write: that the major is trimmed,
//  that the course ids are in catalogue order, and that nothing outside the allowlist is
//  sent. A mock that only returned success could not test any of those.
//

import Foundation
import Synchronization

final class MockProfileService: ProfileService {

    /// Whether the next call succeeds, or fails in a specific way.
    enum Outcome: Sendable {
        case succeed
        case fail(ProfileError)
    }

    // Declared uninitialised and set in `init`: `Mutex` is `~Copyable`, so a stored
    // `let` with an inline default cannot be reassigned. Same shape as `MockAuthService`.
    private let outcome: Mutex<Outcome>
    private let latency: Duration
    private let saveCount = Mutex(0)
    private let styleSaveCount = Mutex(0)
    private let goalsSaveCount = Mutex(0)
    private let last = Mutex<AcademicProfile?>(nil)
    private let lastStyle = Mutex<LearningStyle?>(nil)
    private let lastGoals = Mutex<StudyGoals?>(nil)

    init(latency: Duration = .milliseconds(150), outcome: Outcome = .succeed) {
        self.latency = latency
        self.outcome = Mutex(outcome)
    }

    // MARK: - ProfileService

    func saveAcademicProfile(_ profile: AcademicProfile) async throws {
        try await simulateWork()
        try throwIfForced()

        last.withLock { $0 = profile }
        saveCount.withLock { $0 += 1 }
    }

    func saveLearningStyle(_ style: LearningStyle) async throws {
        try await simulateWork()
        try throwIfForced()

        // Recorded separately from the academic write, because the assertions that matter
        // for B02 are that the STYLE was written and that the academic fields were NOT
        // touched again by a screen that never asked about them.
        lastStyle.withLock { $0 = style }
        styleSaveCount.withLock { $0 += 1 }
    }

    func saveStudyGoals(_ goals: StudyGoals) async throws {
        try await simulateWork()
        try throwIfForced()

        lastGoals.withLock { $0 = goals }
        goalsSaveCount.withLock { $0 += 1 }
    }

    // MARK: - Test and preview controls

    /// The most recent profile written, or `nil` if none was.
    var lastSavedProfile: AcademicProfile? { last.withLock { $0 } }

    /// The most recent learning style written, or `nil` if none was.
    var lastSavedStyle: LearningStyle? { lastStyle.withLock { $0 } }

    /// How many times an academic write succeeded. Lets a test prove the button did not
    /// submit twice — the failure mode `SFPrimaryButton.isLoading` exists to prevent.
    var savedCount: Int { saveCount.withLock { $0 } }

    /// How many times a style write succeeded.
    var styleSavedCount: Int { styleSaveCount.withLock { $0 } }

    /// The most recent study goals written, or `nil` if none were.
    var lastSavedGoals: StudyGoals? { lastGoals.withLock { $0 } }

    /// How many times a study-goals write succeeded.
    var goalsSavedCount: Int { goalsSaveCount.withLock { $0 } }

    /// Forces the next calls to fail with `error`.
    func forceFailure(_ error: ProfileError?) {
        outcome.withLock { $0 = error.map(Outcome.fail) ?? .succeed }
    }

    // MARK: - Helpers

    /// Skipped when the latency is zero, so unit tests run instantly while previews still
    /// show a realistic loading state.
    private func simulateWork() async throws {
        guard latency > .zero else { return }
        do {
            try await Task.sleep(for: latency)
        } catch {
            throw ProfileError.offline
        }
    }

    private func throwIfForced() throws {
        if case .fail(let error) = outcome.withLock({ $0 }) {
            throw error
        }
    }
}
