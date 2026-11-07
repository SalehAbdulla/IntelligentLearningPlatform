//
//  StudySessionReminderSyncTests.swift
//  StudyForgeTests
//
//  F06 session reminders — deterministic coverage for `StudyReminderScheduler`
//  and `ReminderSyncingStudyPlanStore` (the approved 25 scenarios).
//
//  House rules honoured (CONTRIBUTING §666–670): InMemory doubles only, the
//  clock is PINNED (`fixedNow`), stable identifiers everywhere, no randomness,
//  no timing-dependent assertions.
//

import Foundation
import Testing
@testable import StudyForge

struct StudySessionReminderSyncTests {

    /// The pinned clock: 2023-11-14T22:13:20Z. Every relative time in this suite
    /// derives from it, so nothing here can flake at midnight.
    private let fixedNow = Date(timeIntervalSince1970: 1_700_000_000)

    // MARK: Test doubles (test-local; production seams stay untouched)

    private final class TestClock: @unchecked Sendable {
        var now: Date
        init(_ now: Date) { self.now = now }
    }

    /// Counts prompts so "never requests permission" is an assertion, not a hope.
    private final class CountingAuthorizer: NotificationAuthorizer, @unchecked Sendable {
        private let lock = NSLock()
        private var status: NotificationAuthorization
        private var prompts = 0

        init(status: NotificationAuthorization) { self.status = status }

        var promptCount: Int { lock.withLock { prompts } }

        func setStatus(_ status: NotificationAuthorization) {
            lock.withLock { self.status = status }
        }

        func currentStatus() async -> NotificationAuthorization {
            lock.withLock { status }
        }

        func requestAuthorization() async -> NotificationAuthorization {
            lock.withLock { prompts += 1; return status }
        }
    }

    private enum TestError: Error { case boom }

    /// Scheduling always fails — proves a notification failure cannot reach the plan.
    private struct ThrowingScheduler: StudyReminderScheduler {
        func schedule(_ request: StudyReminderRequest) async throws { throw TestError.boom }
        func cancelPending(ids: [String]) async throws { throw TestError.boom }
        func pendingIdentifiers() async throws -> [String] { throw TestError.boom }
    }

    /// Persistence always fails — proves a failed write schedules nothing.
    private struct FailingPlanStore: StudyPlanStore {
        func all() async throws -> [StudyPlan] { [] }
        func plan(id: String) async throws -> StudyPlan? { nil }
        func add(_ plan: StudyPlan) async throws { throw StudyPlanError.storageFailed }
        func delete(id: String) async throws { throw StudyPlanError.storageFailed }
    }

    /// Wraps the plan store and FREEZES its first `all()` snapshot at a gate, so a
    /// test can interleave a newer write while an older reconcile provably holds
    /// stale plans — the exact precondition of the stale-reconcile race.
    private final class GatedStudyPlanStore: StudyPlanStore, @unchecked Sendable {
        private let inner: InMemoryStudyPlanStore
        private let lock = NSLock()
        private var shouldFreezeNextRead = true
        private var freezeHeld = false
        private var frozenSnapshot: [StudyPlan]?
        private var arrivalWaiter: CheckedContinuation<Void, Never>?
        private var releaseGiven = false
        private var releaseWaiter: CheckedContinuation<Void, Never>?

        init(inner: InMemoryStudyPlanStore) { self.inner = inner }

        /// The snapshot the gate froze — the stale data a buggy reconcile would act on.
        var capturedFirstSnapshot: [StudyPlan]? { lock.withLock { frozenSnapshot } }

        /// Test side: suspends until the first `all()` has frozen its snapshot.
        func waitUntilFrozen() async {
            if lock.withLock({ freezeHeld }) { return }
            await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
                let resumeNow = lock.withLock { () -> Bool in
                    if freezeHeld { return true }
                    arrivalWaiter = c
                    return false
                }
                if resumeNow { c.resume() }
            }
        }

        /// Test side: lets the frozen reconcile continue.
        func release() {
            let waiter = lock.withLock { () -> CheckedContinuation<Void, Never>? in
                releaseGiven = true
                let w = releaseWaiter
                releaseWaiter = nil
                return w
            }
            waiter?.resume()
        }

        func all() async throws -> [StudyPlan] {
            let plans = try await inner.all()
            let shouldFreeze = lock.withLock { () -> Bool in
                guard shouldFreezeNextRead else { return false }
                shouldFreezeNextRead = false
                freezeHeld = true
                frozenSnapshot = plans
                return true
            }
            guard shouldFreeze else { return plans }

            let arrival = lock.withLock { () -> CheckedContinuation<Void, Never>? in
                let w = arrivalWaiter
                arrivalWaiter = nil
                return w
            }
            arrival?.resume()

            await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
                let resumeNow = lock.withLock { () -> Bool in
                    if releaseGiven { return true }
                    releaseWaiter = c
                    return false
                }
                if resumeNow { c.resume() }
            }
            return plans
        }

        func plan(id: String) async throws -> StudyPlan? { try await inner.plan(id: id) }
        func add(_ plan: StudyPlan) async throws { try await inner.add(plan) }
        func delete(id: String) async throws { try await inner.delete(id: id) }
    }

    // MARK: Fixture + helpers

    private struct Fixture {
        let clock: TestClock
        let inner: InMemoryStudyPlanStore
        let notifications: InMemoryNotificationStore
        let authorizer: CountingAuthorizer
        let scheduler: InMemoryStudyReminderScheduler
        let store: ReminderSyncingStudyPlanStore
    }

    private func makeFixture(
        status: NotificationAuthorization = .granted,
        seeded: [StudyPlan] = []
    ) -> Fixture {
        let clock = TestClock(fixedNow)
        let inner = InMemoryStudyPlanStore(seededWith: seeded)
        let notifications = InMemoryNotificationStore()
        let authorizer = CountingAuthorizer(status: status)
        let scheduler = InMemoryStudyReminderScheduler(now: { clock.now })
        let store = ReminderSyncingStudyPlanStore(
            inner: inner,
            notifications: notifications,
            authorizer: authorizer,
            reminderScheduler: scheduler,
            now: { clock.now }
        )
        return Fixture(
            clock: clock, inner: inner, notifications: notifications,
            authorizer: authorizer, scheduler: scheduler, store: store
        )
    }

    private func session(
        id: String,
        minutesFromNow: Double,
        status: StudySessionStatus = .pending,
        started: Bool = false
    ) -> StudySession {
        StudySession(
            id: id,
            subject: "Databases",
            estimatedMinutes: 45,
            scheduledAt: fixedNow.addingTimeInterval(minutesFromNow * 60),
            status: status,
            startedAt: started ? fixedNow.addingTimeInterval(-60) : nil
        )
    }

    private func plan(_ sessions: [StudySession], id: String = "plan-1") -> StudyPlan {
        StudyPlan(
            id: id,
            input: StudyPlanInput(subjects: ["Databases"], weeklyHours: 8, intensity: .balanced),
            sessions: sessions,
            createdAt: fixedNow,
            updatedAt: fixedNow
        )
    }

    /// The approved fire time: exactly 30 minutes before the session starts.
    private func fire(_ session: StudySession) -> Date {
        session.scheduledAt.addingTimeInterval(-ReminderSyncingStudyPlanStore.reminderLead)
    }

    private func pendingIDs(_ fixture: Fixture) async -> [String] {
        await fixture.scheduler.pendingIdentifiers()
    }

    // MARK: 1–3 — scheduling basics

    @Test("1. A future pending session schedules exactly once, under the stable reminder id")
    func futurePendingSessionSchedulesOnce() async throws {
        let f = makeFixture()
        try await f.store.add(plan([session(id: "s1", minutesFromNow: 120)]))
        let ids = try await pendingIDs(f)
        #expect(ids == ["reminder-s1"])
        #expect(f.scheduler.pendingRequests.first?.title == "Databases")
    }

    @Test("2. The reminder fires exactly 30 minutes before the session starts")
    func firesExactlyThirtyMinutesBeforeStart() async throws {
        let f = makeFixture()
        let s = session(id: "s1", minutesFromNow: 120)
        try await f.store.add(plan([s]))
        #expect(f.scheduler.pendingRequests.first?.fireAt == s.scheduledAt.addingTimeInterval(-30 * 60))
        #expect(f.scheduler.pendingRequests.first?.fireAt == fire(s))
    }

    @Test("3. A fire time in the past is rejected (the session itself may still be ahead)")
    func pastFireTimeRejected() async throws {
        let f = makeFixture()
        // Starts in 10 minutes ⇒ the fire moment was 20 minutes ago: never scheduled.
        try await f.store.add(plan([session(id: "s1", minutesFromNow: 10)]))
        let ids = try await pendingIDs(f)
        #expect(ids.isEmpty)
    }

    // MARK: 4–8 — session lifecycle

    @Test("4. Completing a session cancels its reminder")
    func completedSessionCancelsReminder() async throws {
        let f = makeFixture()
        try await f.store.add(plan([session(id: "s1", minutesFromNow: 120)]))
        let before = try await pendingIDs(f)
        #expect(before == ["reminder-s1"])
        try await f.store.add(plan([session(id: "s1", minutesFromNow: 120, status: .completed)]))
        let after = try await pendingIDs(f)
        #expect(after.isEmpty)
    }

    @Test("5. Skipping a session cancels its reminder")
    func skippedSessionCancelsReminder() async throws {
        let f = makeFixture()
        try await f.store.add(plan([session(id: "s1", minutesFromNow: 120)]))
        try await f.store.add(plan([session(id: "s1", minutesFromNow: 120, status: .skipped)]))
        let ids = try await pendingIDs(f)
        #expect(ids.isEmpty)
    }

    @Test("6. A started session never carries a pending reminder")
    func startedSessionCancelsReminder() async throws {
        let f = makeFixture()
        try await f.store.add(plan([session(id: "s1", minutesFromNow: 120)]))
        let before = try await pendingIDs(f)
        #expect(before == ["reminder-s1"])
        try await f.store.add(plan([session(id: "s1", minutesFromNow: 120, started: true)]))
        let after = try await pendingIDs(f)
        #expect(after.isEmpty)
    }

    @Test("7. Rescheduling a session updates the fire time (same id, no duplicate)")
    func rescheduledSessionUpdatesReminderTime() async throws {
        let f = makeFixture()
        try await f.store.add(plan([session(id: "s1", minutesFromNow: 120)]))
        let moved = session(id: "s1", minutesFromNow: 120 + 24 * 60)   // the +1-day nudge
        try await f.store.add(plan([moved]))
        let ids = try await pendingIDs(f)
        #expect(ids == ["reminder-s1"])
        #expect(f.scheduler.pendingRequests.count == 1)
        #expect(f.scheduler.pendingRequests.first?.fireAt == fire(moved))
    }

    @Test("8. Re-planning cancels replaced sessions' reminders and schedules the new ones")
    func replanCancelsReplacedReminders() async throws {
        let f = makeFixture()
        try await f.store.add(plan([
            session(id: "old1", minutesFromNow: 120),
            session(id: "old2", minutesFromNow: 180),
        ]))
        // The base develop re-plan regenerates the week with fresh session ids.
        try await f.store.add(plan([
            session(id: "new1", minutesFromNow: 120),
            session(id: "new2", minutesFromNow: 180),
        ]))
        let ids = try await pendingIDs(f)
        #expect(ids == ["reminder-new1", "reminder-new2"])
    }

    @Test("9. Re-plan with preservation keeps history byte-for-byte; only pendings re-sync")
    func replanPreservesHistoryAndProgressData() async throws {
        let f = makeFixture()
        let history = session(id: "hist1", minutesFromNow: -600, status: .completed)
        let oldPending = session(id: "old1", minutesFromNow: 120)
        try await f.store.add(plan([history, oldPending]))

        // Simulated history-preserving re-plan outcome: the completed session is
        // untouched, the never-started pending is re-placed with a fresh id.
        let historyAgain = session(id: "hist1", minutesFromNow: -600, status: .completed)
        let newPending = session(id: "new1", minutesFromNow: 180)
        let rewritten = plan([historyAgain, newPending])
        try await f.store.add(rewritten)

        let stored = try await f.inner.plan(id: "plan-1")
        #expect(stored == rewritten)                    // the decorator never mutates a plan
        #expect(stored?.sessions.first(where: { $0.id == "hist1" })?.status == .completed)
        let ids = try await pendingIDs(f)
        #expect(ids == ["reminder-new1"])               // history is not pending ⇒ never scheduled

        // ACTUAL F07 metrics, not just plan equality: the dashboard's numbers are a
        // pure function of the stored plan (ProgressCalculator), so identical
        // snapshots before and after the sync prove the decorator cannot move F07.
        let before = ProgressCalculator.snapshot(ProgressInput(plan: rewritten, now: fixedNow))
        let after = ProgressCalculator.snapshot(ProgressInput(plan: stored, now: fixedNow))
        #expect(after == before)                        // every metric: streak, minutes, subjects…
        #expect(after.subjects.first?.completedSessions == 1)   // non-vacuous: history still counted
    }

    @Test("10. Repeated identical synchronisation creates no duplicates")
    func repeatedSyncCreatesNoDuplicates() async throws {
        let f = makeFixture()
        let p = plan([
            session(id: "s1", minutesFromNow: 120),
            session(id: "s2", minutesFromNow: 180),
            session(id: "s3", minutesFromNow: 240),
        ])
        try await f.store.add(p)
        try await f.store.add(p)
        try await f.store.add(p)
        let ids = try await pendingIDs(f)
        #expect(ids == ["reminder-s1", "reminder-s2", "reminder-s3"])
        #expect(f.scheduler.pendingRequests.count == 3)
    }

    // MARK: 11–12 — preferences

    @Test("11. Study reminders disabled ⇒ no system requests")
    func remindersDisabledResultsInNoRequests() async throws {
        let f = makeFixture()
        var prefs = NotificationPreferences.default
        prefs.studyReminders = false
        try await f.notifications.savePreferences(prefs)
        try await f.store.add(plan([session(id: "s1", minutesFromNow: 120)]))
        let ids = try await pendingIDs(f)
        #expect(ids.isEmpty)
    }

    @Test("12. A fire time inside quiet hours is suppressed (not delayed)")
    func quietHoursFireTimeSuppressed() async throws {
        let f = makeFixture()
        let s = session(id: "s1", minutesFromNow: 120)
        // A quiet window containing the FIRE hour, stated in local hours — the
        // timezone-proof pattern NotificationStoreTests already uses.
        let fireHour = Calendar.current.component(.hour, from: fire(s))
        var prefs = NotificationPreferences.default
        prefs.quietHoursEnabled = true
        prefs.quietStartHour = fireHour
        prefs.quietEndHour = (fireHour + 11) % 24
        try await f.notifications.savePreferences(prefs)
        try await f.store.add(plan([s]))
        let ids = try await pendingIDs(f)
        #expect(ids.isEmpty)
    }

    // MARK: 13–15 — permission (read-only; F14 owns prompting)

    @Test("13. Denied permission creates no system requests and never prompts")
    func deniedPermissionCreatesNoRequests() async throws {
        let f = makeFixture(status: .denied)
        try await f.store.add(plan([session(id: "s1", minutesFromNow: 120)]))
        let ids = try await pendingIDs(f)
        #expect(ids.isEmpty)
        #expect(f.authorizer.promptCount == 0)
    }

    @Test("14. Not-determined permission does not prompt from F06")
    func notDeterminedPermissionDoesNotPrompt() async throws {
        let f = makeFixture(status: .notDetermined)
        try await f.store.add(plan([session(id: "s1", minutesFromNow: 120)]))
        let ids = try await pendingIDs(f)
        #expect(ids.isEmpty)
        #expect(f.authorizer.promptCount == 0)
    }

    @Test("15. Granted permission schedules correctly, still without prompting")
    func grantedPermissionSchedules() async throws {
        let f = makeFixture(status: .granted)
        try await f.store.add(plan([session(id: "s1", minutesFromNow: 120)]))
        let ids = try await pendingIDs(f)
        #expect(ids == ["reminder-s1"])
        #expect(f.authorizer.promptCount == 0)
    }

    // MARK: 16–18 — cancellation scope

    @Test("16. Deleting the plan cancels its reminders")
    func planDeletionCancelsReminders() async throws {
        let f = makeFixture()
        try await f.store.add(plan([session(id: "s1", minutesFromNow: 120)]))
        try await f.store.delete(id: "plan-1")
        let ids = try await pendingIDs(f)
        #expect(ids.isEmpty)
    }

    @Test("17. Unrelated notification identifiers are never cancelled")
    func otherNotificationTypesNeverCancelled() async throws {
        let f = makeFixture()
        let fireAt = fixedNow.addingTimeInterval(600)
        try await f.scheduler.schedule(StudyReminderRequest(
            id: "reminder-stale", title: "t", body: "b", fireAt: fireAt
        ))
        try await f.scheduler.schedule(StudyReminderRequest(
            id: "quizDue-weekly", title: "t", body: "b", fireAt: fireAt
        ))
        try await f.scheduler.schedule(StudyReminderRequest(
            id: "groupActivity-team", title: "t", body: "b", fireAt: fireAt
        ))
        try await f.store.add(plan([session(id: "s1", minutesFromNow: 120)]))
        let ids = try await pendingIDs(f)
        #expect(!ids.contains("reminder-stale"))        // obsolete F06 reminder: cancelled
        #expect(ids.contains("quizDue-weekly"))         // other types: untouched
        #expect(ids.contains("groupActivity-team"))
        #expect(ids.contains("reminder-s1"))
    }

    @Test("18. Multiple plans schedule independently and never cancel each other")
    func multiplePlansDoNotCancelEachOther() async throws {
        let f = makeFixture()
        try await f.store.add(plan([
            session(id: "a1", minutesFromNow: 120),
            session(id: "a2", minutesFromNow: 180),
        ], id: "plan-a"))
        try await f.store.add(plan([
            session(id: "b1", minutesFromNow: 240),
            session(id: "b2", minutesFromNow: 300),
        ], id: "plan-b"))
        let ids = try await pendingIDs(f)
        #expect(ids == ["reminder-a1", "reminder-a2", "reminder-b1", "reminder-b2"])
    }

    // MARK: 19–20 — failure isolation

    @Test("19. A scheduling failure never corrupts or discards the saved plan")
    func schedulingFailureDoesNotCorruptPlan() async throws {
        let clock = TestClock(fixedNow)
        let inner = InMemoryStudyPlanStore()
        let store = ReminderSyncingStudyPlanStore(
            inner: inner,
            notifications: InMemoryNotificationStore(),
            authorizer: CountingAuthorizer(status: .granted),
            reminderScheduler: ThrowingScheduler(),
            now: { clock.now }
        )
        let p = plan([session(id: "s1", minutesFromNow: 120)])
        try await store.add(p)                        // must not throw
        let stored = try await inner.plan(id: "plan-1")
        #expect(stored == p)                          // byte-for-byte intact
    }

    @Test("20. A failed plan persistence schedules nothing")
    func failedPersistenceSchedulesNothing() async throws {
        let clock = TestClock(fixedNow)
        let scheduler = InMemoryStudyReminderScheduler(now: { clock.now })
        let store = ReminderSyncingStudyPlanStore(
            inner: FailingPlanStore(),
            notifications: InMemoryNotificationStore(),
            authorizer: CountingAuthorizer(status: .granted),
            reminderScheduler: scheduler,
            now: { clock.now }
        )
        var didThrow = false
        do { try await store.add(plan([session(id: "s1", minutesFromNow: 120)])) }
        catch { didThrow = true }
        #expect(didThrow)
        let ids = try await scheduler.pendingIdentifiers()
        #expect(ids.isEmpty)
    }

    // MARK: 21–23 — lifecycle reconciliation

    @Test("21. App relaunch reconciliation: ghosts cancelled, dropped requests restored")
    func relaunchReconciliation() async throws {
        let f = makeFixture()
        try await f.store.add(plan([session(id: "s1", minutesFromNow: 120)]))
        // Between launches: iOS dropped our request, and a stale one from a
        // previous plan life is still pending.
        try await f.scheduler.cancelPending(ids: ["reminder-s1"])
        try await f.scheduler.schedule(StudyReminderRequest(
            id: "reminder-ghost", title: "t", body: "b", fireAt: fixedNow.addingTimeInterval(300)
        ))
        // Relaunch: a fresh decorator over the same persisted stores, reconciled
        // by the app's first plan read (`all()`).
        let relaunched = ReminderSyncingStudyPlanStore(
            inner: f.inner,
            notifications: f.notifications,
            authorizer: f.authorizer,
            reminderScheduler: f.scheduler,
            now: { f.clock.now }
        )
        let plans = try await relaunched.all()
        #expect(plans.count == 1)
        let ids = try await pendingIDs(f)
        #expect(ids == ["reminder-s1"])   // ghost cancelled; the dropped request restored
    }

    @Test("22. Preference changes reconcile existing reminders on the next plan read")
    func preferenceChangeReconciles() async throws {
        let f = makeFixture()
        try await f.store.add(plan([session(id: "s1", minutesFromNow: 120)]))
        let initial = try await pendingIDs(f)
        #expect(initial == ["reminder-s1"])

        var prefs = NotificationPreferences.default
        prefs.studyReminders = false
        try await f.notifications.savePreferences(prefs)
        _ = try await f.store.all()               // next read reconciles
        let off = try await pendingIDs(f)
        #expect(off.isEmpty)

        prefs.studyReminders = true
        try await f.notifications.savePreferences(prefs)
        _ = try await f.store.all()
        let on = try await pendingIDs(f)
        #expect(on == ["reminder-s1"])
        // Quiet-hours edits ride the same preferences path (test 12 covers the
        // suppression rule itself).
    }

    @Test("23. Permission changes reconcile existing reminders on the next plan read")
    func permissionChangeReconciles() async throws {
        let f = makeFixture(status: .granted)
        try await f.store.add(plan([session(id: "s1", minutesFromNow: 120)]))
        let before = await pendingIDs(f)
        #expect(before == ["reminder-s1"])

        f.authorizer.setStatus(.denied)
        _ = try await f.store.all()
        let denied = await pendingIDs(f)
        #expect(denied.isEmpty)

        f.authorizer.setStatus(.granted)
        _ = try await f.store.all()
        let restored = await pendingIDs(f)
        #expect(restored == ["reminder-s1"])
    }

    // MARK: 24–25 — queue depth and the InMemory contract

    @Test("24. More than ten sessions: cap holds, the queue replenishes as time passes")
    func moreThanTenSessionsReplenishes() async throws {
        let f = makeFixture()
        let sessions = (1...12).map { session(id: "s\($0)", minutesFromNow: Double($0) * 60) }
        try await f.store.add(plan(sessions))
        let initial = await pendingIDs(f)
        #expect(initial.count == ReminderSyncingStudyPlanStore.limit)   // 10, not 12
        #expect(!initial.contains("reminder-s11"))

        // Time passes the first three fire times; the next read reconciles and
        // the queue replenishes without duplicating anything.
        f.clock.now = fixedNow.addingTimeInterval(150 * 60)
        _ = try await f.store.all()
        let later = await pendingIDs(f)
        #expect(later.contains("reminder-s11"))
        #expect(later.contains("reminder-s12"))
        #expect(!later.contains("reminder-s1"))
        #expect(later.count <= ReminderSyncingStudyPlanStore.limit)
    }

    @Test("25. The InMemory scheduler models the system contract exactly")
    func inMemorySchedulerModelsSystemContract() async throws {
        let clock = TestClock(fixedNow)
        let scheduler = InMemoryStudyReminderScheduler(now: { clock.now })
        let a = StudyReminderRequest(
            id: "reminder-a", title: "t", body: "b", fireAt: fixedNow.addingTimeInterval(600)
        )

        try await scheduler.schedule(a)
        try await scheduler.schedule(a)                        // replacement, not duplication
        var ids = try await scheduler.pendingIdentifiers()
        #expect(ids == ["reminder-a"])

        let past = StudyReminderRequest(
            id: "reminder-past", title: "t", body: "b", fireAt: fixedNow.addingTimeInterval(-1)
        )
        try await scheduler.schedule(past)                     // rejected: never in the past
        ids = try await scheduler.pendingIdentifiers()
        #expect(!ids.contains("reminder-past"))

        try await scheduler.cancelPending(ids: ["reminder-missing"])   // unknown id: no-op
        ids = try await scheduler.pendingIdentifiers()
        #expect(ids == ["reminder-a"])

        try await scheduler.cancelPending(ids: ["reminder-a"])
        ids = try await scheduler.pendingIdentifiers()
        #expect(ids.isEmpty)

        // Delivery: once the fire time passes, the request leaves the pending set.
        let later = StudyReminderRequest(
            id: "reminder-later", title: "t", body: "b", fireAt: fixedNow.addingTimeInterval(60)
        )
        try await scheduler.schedule(later)
        clock.now = fixedNow.addingTimeInterval(120)
        ids = try await scheduler.pendingIdentifiers()
        #expect(ids.isEmpty)
    }

    // MARK: 26–28 — concurrency, clock changes and exact fire intervals

    @Test("26. A frozen stale reconcile is deterministically superseded by the newer write")
    func staleReconcileIsSuperseded() async throws {
        let clock = TestClock(fixedNow)
        let inner = InMemoryStudyPlanStore()
        let gate = GatedStudyPlanStore(inner: inner)
        let scheduler = InMemoryStudyReminderScheduler(now: { clock.now })
        let store = ReminderSyncingStudyPlanStore(
            inner: gate,
            notifications: InMemoryNotificationStore(),
            authorizer: CountingAuthorizer(status: .granted),
            reminderScheduler: scheduler,
            now: { clock.now }
        )

        // R1 (plan-a's reconcile) freezes its snapshot at the gate — the exact
        // mid-flight point where a stale desired set could cancel newer work.
        let firstWrite = Task { try await store.add(plan([session(id: "a1", minutesFromNow: 120)], id: "plan-a")) }
        await gate.waitUntilFrozen()

        // Staleness is PROVEN, not assumed: R1 holds only plan-a, and plan-b does
        // not exist yet at the freeze point.
        #expect(gate.capturedFirstSnapshot?.map(\.id) == ["plan-a"])
        let planBAtFreeze = try await inner.plan(id: "plan-b")
        #expect(planBAtFreeze == nil)

        // The newer write lands while R1 is frozen; its reconcile chains BEHIND R1.
        let secondWrite = Task { try await store.add(plan([session(id: "b1", minutesFromNow: 180)], id: "plan-b")) }
        gate.release()
        try await firstWrite.value
        try await secondWrite.value

        // Serialised + fresh-reading: the stale run goes first, the fresh run last,
        // so the stale desired set can never cancel plan-b's reminder.
        let ids = try await scheduler.pendingIdentifiers()
        #expect(ids == ["reminder-a1", "reminder-b1"])
        #expect(gate.capturedFirstSnapshot?.count == 1)   // the stale read really happened
    }

    @Test("27. A clock rewind neither duplicates nor drops a pending reminder")
    func clockRewindKeepsSinglePending() async throws {
        let f = makeFixture()
        try await f.store.add(plan([session(id: "s1", minutesFromNow: 120)]))
        let before = await pendingIDs(f)
        #expect(before == ["reminder-s1"])

        // The clock moves backwards (manual change / NTP step): the reminder is
        // still future, still desired, and a re-sync replaces it 1:1.
        f.clock.now = fixedNow.addingTimeInterval(-300)
        _ = try await f.store.all()
        let after = await pendingIDs(f)
        #expect(after == ["reminder-s1"])
        #expect(f.scheduler.pendingRequests.count == 1)
    }

    @Test("28. Fire intervals are exact: sub-second passes through, overdue is never scheduled")
    func fireIntervalIsExact() {
        // The full lead distance — no rounding, no clamp.
        #expect(SystemStudyReminderScheduler.fireInterval(fireAt: fixedNow + 1800, now: fixedNow) == 1800)
        // Sub-second instants pass through VERBATIM (0.5 and 0.25 are exact in
        // binary floating point, so equality is stable).
        #expect(SystemStudyReminderScheduler.fireInterval(fireAt: fixedNow + 0.5, now: fixedNow) == 0.5)
        #expect(SystemStudyReminderScheduler.fireInterval(fireAt: fixedNow + 0.25, now: fixedNow) == 0.25)
        // The instant itself and the past are never scheduled: `nil` means the
        // system is never handed an overdue request to deliver immediately.
        #expect(SystemStudyReminderScheduler.fireInterval(fireAt: fixedNow, now: fixedNow) == nil)
        #expect(SystemStudyReminderScheduler.fireInterval(fireAt: fixedNow - 30, now: fixedNow) == nil)
    }
}
