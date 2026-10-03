//
//  OnboardingStore.swift
//  StudyForge
//
//  Remembers whether the user has finished the onboarding pager (A02–A04).
//
//  WHY THIS IS A PROTOCOL AND NOT AN `@AppStorage` IN THE VIEW
//  ----------------------------------------------------------
//  `@AppStorage("hasSeenOnboarding")` inside the view would be shorter, and would make the
//  pager's behaviour untestable: a unit test cannot put the app's real UserDefaults into a
//  known state, and "does the pager skip itself on the second launch?" is exactly the
//  behaviour worth asserting. Injecting the store lets a test answer that in microseconds,
//  and keeps `UserDefaults.standard` out of the view layer (docs/04 §8: everything through
//  `AppContainer`, no ambient globals).
//

import Foundation

/// Persists the one flag the onboarding flow cares about.
protocol OnboardingStore: Sendable {

    /// True once the user has reached the end (or explicitly skipped) onboarding.
    ///
    /// Read once, when the app decides whether to show the pager. It is NOT a
    /// "don't show again this launch" flag — that would be a different, weaker idea.
    var hasCompletedOnboarding: Bool { get }

    /// Records completion. Idempotent.
    func markCompleted()

    /// Clears the flag. For tests and the "replay onboarding" developer affordance.
    func reset()
}

/// Production store, backed by `UserDefaults`.
///
/// `@unchecked Sendable` because `UserDefaults` is documented as thread-safe but is not
/// annotated `Sendable`, so the compiler cannot verify what the documentation guarantees.
/// This is the narrow, honest form of the assertion: the type is safe to share, and the
/// only reason to say so manually is a gap in Apple's annotation. The alternative —
/// resolving `UserDefaults` on every access instead of storing it — would trade a
/// documented guarantee for a compiler appeasement.
struct UserDefaultsOnboardingStore: OnboardingStore, @unchecked Sendable {

    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "studyforge.onboarding.completed") {
        self.defaults = defaults
        self.key = key
    }

    var hasCompletedOnboarding: Bool {
        defaults.bool(forKey: key)
    }

    func markCompleted() {
        defaults.set(true, forKey: key)
    }

    func reset() {
        defaults.removeObject(forKey: key)
    }
}

/// In-memory store for tests and previews.
///
/// A class with a lock rather than a struct, because a test needs to observe the write and
/// `Sendable` requires the mutation to be safe.
final class InMemoryOnboardingStore: OnboardingStore, @unchecked Sendable {

    private let lock = NSLock()
    private var completed: Bool

    init(hasCompletedOnboarding: Bool = false) {
        self.completed = hasCompletedOnboarding
    }

    var hasCompletedOnboarding: Bool {
        lock.withLock { completed }
    }

    func markCompleted() {
        lock.withLock { completed = true }
    }

    func reset() {
        lock.withLock { completed = false }
    }
}
