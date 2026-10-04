//
//  CohortSnapshot.swift
//  StudyForge
//
//  F11 — the four numbers across the top of J01 (docs/03 §J J01): students, active this week,
//  average mastery, and how many need attention.
//
//  WHY THIS IS A PURE FUNCTION
//  ---------------------------
//  The KPIs are the first thing a marker reads on the tutor screen, so they must be right
//  rather than merely plausible. Deriving them in one pure function — the same discipline as
//  `ProgressCalculator` and `StudyPlanner` — means the arithmetic is tested without a device
//  or a store, and the view has nothing to compute.
//

import Foundation

/// The cohort-level figures J01 shows.
struct CohortSnapshot: Equatable, Sendable {

    /// Students on the roster (`.active` only — a pending request is not yet a student).
    let students: Int

    /// Students active within the last seven days.
    let activeThisWeek: Int

    /// Mean mastery across the roster, 0…100. `0` when the roster is empty.
    let averageMastery: Int

    /// Students flagged by `Enrollment.isAtRisk`.
    let atRisk: Int

    /// Whether there is a cohort at all — an empty course is a designed state (J01).
    var isEmpty: Bool { students == 0 }

    /// Active as a share of the cohort, 0…1. `nil` when the cohort is empty, so the UI can
    /// show "—" rather than a misleading 0 %.
    var activeFraction: Double? {
        guard students > 0 else { return nil }
        return Double(activeThisWeek) / Double(students)
    }

    /// Computes the snapshot from a course's roster.
    ///
    /// - Parameter now: injected so "active this week" is deterministic in tests rather than
    ///   dependent on when the suite happens to run.
    static func from(_ enrollments: [Enrollment], now: Date = .now) -> CohortSnapshot {
        let roster = enrollments.filter { $0.status == .active }
        let weekAgo = now.addingTimeInterval(-60 * 60 * 24 * 7)

        let masteryTotal = roster.reduce(0) { $0 + $1.masteryPercent }
        let average = roster.isEmpty ? 0 : Int((Double(masteryTotal) / Double(roster.count)).rounded())

        return CohortSnapshot(
            students: roster.count,
            activeThisWeek: roster.filter { $0.isActive(since: weekAgo) }.count,
            averageMastery: average,
            atRisk: roster.filter(\.isAtRisk).count
        )
    }

    /// An empty snapshot, for a course with no roster.
    static let empty = CohortSnapshot(students: 0, activeThisWeek: 0, averageMastery: 0, atRisk: 0)
}
