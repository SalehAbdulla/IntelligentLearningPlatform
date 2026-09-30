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
    private let last = Mutex<AcademicProfile?>(nil)

    init(latency: Duration = .milliseconds(150), outcome: Outcome = .succeed) {
        self.latency = latency
        self.outcome = Mutex(outcome)
    }

    // MARK: - ProfileService

    func saveAcademicProfile(_ profile: AcademicProfile) async throws {
        // Skipped when zero, so unit tests run instantly while previews still show a
        // realistic loading state.
        if latency > .zero {
            try? await Task.sleep(for: latency)
        }

        if case .fail(let error) = outcome.withLock({ $0 }) {
            throw error
        }

        last.withLock { $0 = profile }
        saveCount.withLock { $0 += 1 }
    }

    // MARK: - Test and preview controls

    /// The most recent profile written, or `nil` if none was.
    var lastSavedProfile: AcademicProfile? { last.withLock { $0 } }

    /// How many times a write succeeded. Lets a test prove the button did not submit
    /// twice — the failure mode `SFPrimaryButton.isLoading` exists to prevent.
    var savedCount: Int { saveCount.withLock { $0 } }

    /// Forces the next calls to fail with `error`.
    func forceFailure(_ error: ProfileError?) {
        outcome.withLock { $0 = error.map(Outcome.fail) ?? .succeed }
    }
}
