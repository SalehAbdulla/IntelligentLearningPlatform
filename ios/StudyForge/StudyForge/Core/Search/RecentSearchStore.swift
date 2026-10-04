//
//  RecentSearchStore.swift
//  StudyForge
//
//  M05 — remembers the queries the student has run (docs/03 §M, "recent searches").
//
//  WHY THIS IS A PROTOCOL AND NOT `@AppStorage`
//  --------------------------------------------
//  The same reason `OnboardingStore` is: a unit test cannot put the app's real `UserDefaults` into a
//  known state, and "does a repeated query move to the front rather than appearing twice?" is exactly
//  the behaviour worth asserting. Injecting the store answers that in microseconds and keeps
//  `UserDefaults.standard` out of the view layer (docs/04 §8).
//
//  WHY IT IS CAPPED
//  ----------------
//  A recent-searches list is a shortcut, not a history. Past a handful of entries it stops being
//  quicker than typing, so the store keeps the newest few and drops the rest — the cap lives here
//  rather than in the view, so both implementations obey it.
//

import Foundation

/// Persists the last few search queries.
protocol RecentSearchStore: Sendable {

    /// The queries, most recent first. At most ``RecentSearchLimit/cap`` of them.
    var recent: [String] { get }

    /// Records a query. A repeat moves to the front rather than appearing twice.
    func record(_ query: String)

    /// Clears the list. M05's "Clear".
    func clear()
}

/// The one place the recent-searches cap is stated.
///
/// A plain namespace rather than a static on the protocol: a protocol's static member cannot be
/// read from the protocol metatype, and both implementations AND the tests need the same number, so
/// threading it through a conforming type would be worse than naming it once.
enum RecentSearchLimit {
    static let cap = 8
}

/// Production store, backed by `UserDefaults`.
///
/// `@unchecked Sendable` for the same documented-but-unannotated reason as
/// `UserDefaultsOnboardingStore`: `UserDefaults` is thread-safe, and the compiler cannot see it.
struct UserDefaultsRecentSearchStore: RecentSearchStore, @unchecked Sendable {

    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "studyforge.search.recent") {
        self.defaults = defaults
        self.key = key
    }

    var recent: [String] {
        defaults.stringArray(forKey: key) ?? []
    }

    func record(_ query: String) {
        insert(query, into: recent) { defaults.set($0, forKey: key) }
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}

/// In-memory store for tests and previews.
final class InMemoryRecentSearchStore: RecentSearchStore, @unchecked Sendable {

    private let lock = NSLock()
    private var stored: [String]

    init(recent: [String] = []) {
        self.stored = recent
    }

    var recent: [String] { lock.withLock { stored } }

    func record(_ query: String) {
        lock.withLock {
            insert(query, into: stored) { stored = $0 }
        }
    }

    func clear() {
        lock.withLock { stored = [] }
    }
}

/// The one insert rule, shared so the two stores cannot drift.
///
/// A blank query is ignored (there is nothing to remember about an empty field), a repeat is moved
/// to the front rather than duplicated (so the same search does not fill the list), and the list is
/// trimmed to the cap.
private func insert(_ query: String, into existing: [String], _ store: ([String]) -> Void) {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }

    var updated = existing.filter { $0.lowercased() != trimmed.lowercased() }
    updated.insert(trimmed, at: 0)
    store(Array(updated.prefix(RecentSearchLimit.cap)))
}