//
//  StudyReminderScheduler.swift
//  StudyForge
//
//  F06 — the M3-owned seam over DATED local notifications for study sessions
//  (docs/03 §G: G04's reminder promise; docs/03 §M: M03's study-reminder copy).
//
//  WHY THIS EXISTS NEXT TO F14's NotificationScheduler (OPTION B, APPROVED)
//  -----------------------------------------------------------------------
//  F14's `NotificationScheduler` in `Core/Notifications/` delivers IMMEDIATELY
//  (`trigger: nil`) and its files are M1-owned. A session reminder must fire at an
//  EXACT future instant — 30 minutes before the session — and must be cancellable
//  when the session completes, is skipped, is rescheduled, or the plan is deleted.
//  Option B puts that dated schedule/cancel/query surface in M3's lane
//  (`Core/Planning/`) without touching a single M1 file. It never requests
//  permission — F14's `NotificationAuthorizer` owns asking — and it only ever
//  touches the identifiers it is handed.
//
//  WHY THE CLOCK IS INJECTABLE
//  ---------------------------
//  House rule (CONTRIBUTING §7): never assert on `Date.now`. Tests pin time.
//

import Foundation
@preconcurrency import UserNotifications

/// One dated local-notification request, in the app's own vocabulary.
struct StudyReminderRequest: Equatable, Sendable {

    /// Stable identifier: `reminder-<studySession.id>` — the SAME id
    /// `NotificationReminderPlanner` derives for the inbox row, so banner and inbox
    /// row are two views of one session reminder, and a re-schedule replaces
    /// rather than duplicates.
    ///
    /// COLLISION AUDIT (F14 owns the `reminder-` string): the planner's rows live
    /// in `NotificationStore`, never in `UNUserNotificationCenter`, and F14's only
    /// system delivery today is B09's test reminder — an immediate request under a
    /// UUID id, which is delivered rather than pending. So no pending system
    /// request can carry this prefix from F14 today, and F06's prefix-filtered
    /// cancellation cannot touch F14. If F14 ever DATES system requests under
    /// `reminder-`, this prefix must be re-scoped first — a cross-lane decision,
    /// recorded here so the hazard is not rediscovered the hard way.
    let id: String

    let title: String
    let body: String

    /// The exact instant the banner fires: the session's `scheduledAt` MINUS the
    /// approved 30-minute lead. Never the session start itself, and never
    /// `StudyNotification.createdAt` (which the F14 planner dates to session start
    /// for inbox day-grouping — a different field with a different job).
    let fireAt: Date

    init(id: String, title: String, body: String, fireAt: Date) {
        self.id = id
        self.title = title
        self.body = body
        self.fireAt = fireAt
    }
}

/// Schedules, cancels and lists FUTURE study-session reminders.
protocol StudyReminderScheduler: Sendable {

    /// Adds one pending request, replacing any pending request with the same
    /// identifier (the system's own contract: same identifier ⇒ same slot, never
    /// two). A `fireAt` that is not strictly in the future is ignored — never
    /// scheduled, and never delivered immediately as a fallback.
    func schedule(_ request: StudyReminderRequest) async throws

    /// Removes the pending requests under exactly these identifiers. Identifiers
    /// that are not pending are ignored; identifiers not listed are never touched,
    /// so an unrelated F14 notification cannot be cancelled through this API.
    func cancelPending(ids: [String]) async throws

    /// The identifiers currently pending, so reconciliation can diff the desired
    /// set against reality instead of keeping a second copy of the truth.
    func pendingIdentifiers() async throws -> [String]
}

/// The real scheduler, over `UNUserNotificationCenter`.
///
/// A time-interval trigger derived from the exact `fireAt` — no immediate
/// delivery path exists in this type at all.
struct SystemStudyReminderScheduler: StudyReminderScheduler {

    private let now: @Sendable () -> Date

    init(now: @escaping @Sendable () -> Date = { .now }) {
        self.now = now
    }

    /// The exact seconds from `now` until `fireAt`, or `nil` when the moment is
    /// not ahead. Pure, so the sub-second decision is unit-testable without
    /// touching `UserNotifications`:
    /// • Sub-second values in (0, 1) pass through VERBATIM — rounding them up
    ///   to 1s (the previous clamp) silently delayed an already-due reminder and
    ///   broke the exact 30-minute-lead promise, so it was removed.
    /// • `0` and the past return nil. The documented hard constraint on
    ///   `UNTimeIntervalNotificationTrigger.timeInterval` is `> 0` (a zero
    ///   interval raises "time interval must be greater than 0"), and skipping
    ///   past instants is what keeps an overdue request from being handed to the
    ///   system as an immediate delivery.
    /// • `repeats: false` has no 60-second minimum — that floor belongs to
    ///   repeating triggers, and this seam never repeats.
    static func fireInterval(fireAt: Date, now: Date) -> TimeInterval? {
        let interval = fireAt.timeIntervalSince(now)
        return interval > 0 ? interval : nil
    }

    func schedule(_ request: StudyReminderRequest) async throws {
        guard let interval = Self.fireInterval(fireAt: request.fireAt, now: now()) else { return }
        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let notification = UNNotificationRequest(identifier: request.id, content: content, trigger: trigger)
        try await UNUserNotificationCenter.current().add(notification)
    }

    func cancelPending(ids: [String]) async throws {
        guard !ids.isEmpty else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    func pendingIdentifiers() async throws -> [String] {
        try await UNUserNotificationCenter.current().pendingNotificationRequests().map(\.identifier)
    }
}

/// An in-memory scheduler that models the system contract exactly, for tests:
/// replacement by identifier, scoped cancellation, pending queries, rejection of
/// past fire times, and delivery (a request whose fire time has passed drops out
/// of the pending set, the way iOS drops a fired trigger).
final class InMemoryStudyReminderScheduler: StudyReminderScheduler, @unchecked Sendable {

    private let lock = NSLock()
    private var pending: [String: StudyReminderRequest] = [:]
    private let now: @Sendable () -> Date

    init(now: @escaping @Sendable () -> Date = { .now }) {
        self.now = now
    }

    func schedule(_ request: StudyReminderRequest) async throws {
        lock.withLock {
            guard request.fireAt > now() else { return }
            pending[request.id] = request          // same identifier replaces: no duplicates
        }
    }

    func cancelPending(ids: [String]) async throws {
        lock.withLock {
            for id in ids { pending.removeValue(forKey: id) }
        }
    }

    func pendingIdentifiers() async throws -> [String] {
        lock.withLock {
            let current = now()
            pending = pending.filter { $0.value.fireAt > current }   // model iOS delivery
            return Array(pending.keys).sorted()
        }
    }

    /// The pending requests themselves, sorted for deterministic assertions.
    var pendingRequests: [StudyReminderRequest] {
        lock.withLock { Array(pending.values).sorted { $0.id < $1.id } }
    }
}
