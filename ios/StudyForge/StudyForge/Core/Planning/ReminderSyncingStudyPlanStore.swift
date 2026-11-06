//
//  ReminderSyncingStudyPlanStore.swift
//  StudyForge
//
//  F06 — a StudyPlanStore decorator that keeps dated session reminders in step
//  with the plan that was JUST PERSISTED (docs/03 §G, G04; docs/02 F14 failure
//  cases: duplicate notifications, permission denied, quiet hours).
//
//  WHY A DECORATOR OVER THE STORE
//  ------------------------------
//  Every F06 mutation funnels through `StudyPlanStore.add`/`delete` — the wizard's
//  `generate()`, and StudyPlanViewModel's mark-done / skip / start / reschedule /
//  re-plan / persist paths. One decorator therefore covers the whole session
//  lifecycle without editing a view model, which matters because those view
//  models belong to open PRs #151/#152/#153 and must not be disturbed.
//
//  ORDER OF OPERATIONS — THE SAFETY CONTRACT
//  -----------------------------------------
//  1. Writes go to the wrapped store FIRST. A failed write rethrows and NO
//     reminder work happens: a plan the student cannot see must not produce
//     banners (a failed persistence schedules nothing).
//  2. Only after a successful write — and on `all()` reads, for reconciliation —
//     is the desired set recomputed and diffed against the scheduler's pending
//     identifiers. Reconciliations are SERIALISED (chained): overlapping reads
//     and writes converge instead of a stale desired set cancelling a newer one.
//  3. Notification problems are swallowed. Scheduling can never corrupt or
//     discard a saved plan, and this type never writes to a plan at all:
//     history (completed / skipped / in-progress sessions) and everything F07
//     derives from it stay byte-for-byte untouched.
//
//  APPROVED PRODUCT DECISIONS ENCODED HERE
//  ---------------------------------------
//  • Fire exactly 30 minutes before `scheduledAt` (`reminderLead`).
//  • Permission is READ via F14's authorizer, never requested here — the M02
//    primer and the B09 flow own prompting. Not granted ⇒ the desired set is
//    empty, so anything already pending is cancelled (denied ⇒ nothing shows).
//  • Quiet hours SUPPRESS (never delay): the FIRE time's local hour is tested
//    against `NotificationPreferences.isQuiet(hour:)`.
//  • Started sessions (`startedAt != nil`) never carry a pending reminder.
//  • Eligible = pending + not started + fire strictly in the future + study
//    reminders enabled + fire outside quiet hours + within the per-plan cap of
//    upcoming reminders (10, mirroring `NotificationReminderPlanner.limit`).
//  • Cancellation is scoped to the `reminder-` identifier prefix, so an
//    unrelated F14 notification is never cancelled by F06.
//
//  WHY NOT NotificationReminderPlanner (M1, UNTOUCHED)
//  ---------------------------------------------------
//  The planner is reused for CONVENTION — its stable `reminder-<session.id>`
//  identifier scheme, subject-as-title copy, and 10-cap ordering are matched
//  exactly so F06 banners and F14 inbox rows stay two views of one session. Its
//  FILTERS are not reused because they answer different questions than the
//  approved rules: it tests quiet hours against SESSION START (not fire time),
//  includes started sessions, and treats "start in the future" as the horizon
//  (not "fire in the future"). Its `createdAt` is session start for inbox
//  day-grouping and is deliberately NOT used as a fire time anywhere here.
//

import Foundation

/// `@unchecked Sendable` + lock: the reconciliation chain below is mutable state.
/// The lock is only ever held to build or swap a task reference — never across an
/// `await` — the same discipline `InMemoryStudyReminderScheduler` uses.
final class ReminderSyncingStudyPlanStore: StudyPlanStore, @unchecked Sendable {

    /// Lead time before the session. Approved: exactly 30 minutes.
    static let reminderLead: TimeInterval = 30 * 60

    /// Identifier prefix shared with `NotificationReminderPlanner`'s inbox rows.
    /// Cancellation matches ONLY this prefix: F06 cancels only what F06 schedules.
    static let idPrefix = "reminder-"

    /// Per-plan cap on upcoming reminders, mirroring `NotificationReminderPlanner.limit`
    /// so the banner queue and the inbox queue agree on which sessions are "the next ten".
    static let limit = 10

    private let inner: any StudyPlanStore
    private let notifications: any NotificationStore
    private let authorizer: any NotificationAuthorizer
    private let reminderScheduler: any StudyReminderScheduler
    private let now: @Sendable () -> Date

    /// Serialises reconciliations. Overlapping reads/writes must not interleave:
    /// a reconcile computing its desired set from stale plans could cancel a
    /// newer plan's reminders. Each entry chains onto the previous task, so runs
    /// execute strictly in enqueue order, and every run re-reads the plans afresh.
    /// RETAIN CHECK: each task captures `self` strongly, but the apparent cycle
    /// self → chain → task → self breaks the moment the task completes — the
    /// runtime releases the closure context, captures included — and the single
    /// chain slot is overwritten on every enqueue, so at most one completed task
    /// handle is ever retained. Nothing accumulates across generations, and an
    /// awaiting caller keeps `self` alive for the duration anyway.
    private let chainLock = NSLock()
    private var reconcileChain: Task<Void, Never>?

    init(
        inner: any StudyPlanStore,
        notifications: any NotificationStore,
        authorizer: any NotificationAuthorizer,
        reminderScheduler: any StudyReminderScheduler,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.inner = inner
        self.notifications = notifications
        self.authorizer = authorizer
        self.reminderScheduler = reminderScheduler
        self.now = now
    }

    // MARK: StudyPlanStore

    func all() async throws -> [StudyPlan] {
        let plans = try await inner.all()
        await enqueueReconcile()          // relaunch / screen-load reconciliation
        return plans
    }

    /// Pure read-through. Every state CHANGE flows through `add`/`delete`, and the
    /// whole-plan reconciliation on `all()` already covers screen loads.
    func plan(id: String) async throws -> StudyPlan? {
        try await inner.plan(id: id)
    }

    func add(_ plan: StudyPlan) async throws {
        try await inner.add(plan)         // persist FIRST; a failure rethrows and schedules nothing
        await enqueueReconcile()          // only after the write succeeded
    }

    func delete(id: String) async throws {
        try await inner.delete(id: id)
        await enqueueReconcile()          // the deleted plan's reminders become obsolete
    }

    // MARK: Reconciliation

    /// Recomputes the desired reminder set from every stored plan and brings the
    /// scheduler's pending set in line with it. Safe to call at any time; never
    /// throws; never writes to a plan. This is the lifecycle hook: the first
    /// `all()` after an app relaunch, a permission change, or a preferences
    /// change converges the pending set to the approved rules.
    func reconcileReminders() async {
        await enqueueReconcile()
    }

    /// Runs one reconciliation after every previously enqueued one, reading the
    /// plans afresh at its own start — so the LAST run always reflects the LAST
    /// persisted state, no matter how reads and writes overlapped.
    private func enqueueReconcile() async {
        let task = chainLock.withLock { () -> Task<Void, Never> in
            let previous = reconcileChain
            let next = Task { [self] in
                await previous?.value
                await performReconcile()
            }
            reconcileChain = next
            return next
        }
        await task.value
    }

    private func performReconcile() async {
        // Fresh read INSIDE the serialised section: a plans array captured before a
        // concurrent write could otherwise cancel that write's reminders.
        guard let plans = try? await inner.all() else { return }   // read failure: leave reminders as they are
        do {
            // Preferences first: if they cannot be read, abort WITHOUT cancelling —
            // failing toward "leave the student's pending reminders alone".
            let preferences = try await notifications.preferences()

            // READ only — requesting permission here would violate the approved
            // "F14 owns the permission flow" decision (tests assert zero prompts).
            let granted = await authorizer.currentStatus().allowsDelivery

            var desired: [StudyReminderRequest] = []
            if granted {
                for plan in plans {
                    desired.append(contentsOf: Self.desiredRequests(
                        for: plan,
                        preferences: preferences,
                        now: now()
                    ))
                }
            }

            let desiredIDs = Set(desired.map(\.id))
            let pending = try await reminderScheduler.pendingIdentifiers()
            let managed = pending.filter { $0.hasPrefix(Self.idPrefix) }   // scope: F06 reminders only
            let obsolete = managed.filter { !desiredIDs.contains($0) }
            if !obsolete.isEmpty {
                try await reminderScheduler.cancelPending(ids: obsolete)
            }
            for request in desired {
                try await reminderScheduler.schedule(request)   // same id replaces: idempotent
            }
        } catch {
            // A notification failure must never surface into the store: the plan is
            // already persisted at this point, and the next reconciliation retries.
        }
    }

    // MARK: Desired-set computation (pure)

    /// The reminders one plan implies under the approved rules. Pure: the only
    /// time it sees is the `now` passed in, so tests can stand at a fixed moment.
    static func desiredRequests(
        for plan: StudyPlan,
        preferences: NotificationPreferences,
        now: Date
    ) -> [StudyReminderRequest] {
        guard preferences.studyReminders else { return [] }
        let calendar = Calendar.current
        return plan.sessions
            .filter { $0.status == .pending && $0.startedAt == nil }        // pending AND not started
            .compactMap { session -> StudyReminderRequest? in
                let fireAt = session.scheduledAt.addingTimeInterval(-reminderLead)
                guard fireAt > now else { return nil }                      // never in the past
                let fireHour = calendar.component(.hour, from: fireAt)
                guard !preferences.isQuiet(hour: fireHour) else { return nil }   // suppress, never delay
                return StudyReminderRequest(
                    id: idPrefix + session.id,
                    title: session.subject,
                    body: L10n.notificationReminderBody.string(
                        session.scheduledAt.formatted(date: .omitted, time: .shortened),
                        session.estimatedMinutes
                    ),
                    fireAt: fireAt
                )
            }
            .sorted { $0.fireAt < $1.fireAt }
            .prefix(limit)
            .map { $0 }
    }
}
