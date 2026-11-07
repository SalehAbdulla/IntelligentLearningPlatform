//
//  StudyPlanReplanHistoryTests.swift
//  StudyForgeTests
//
//  F06 G09 — re-plan must not erase history.
//
//  Why this suite exists: the old `replan()` rebuilt every session from the planner, silently
//  destroying completed/skipped sessions and an in-progress (started) session. G09 requires:
//  1. history (completed/skipped) and live state (pending + startedAt) are preserved bit-for-bit;
//  2. only pending NEVER-started sessions are re-placed;
//  3. the session COUNT is invariant (no growth, no shrink) for plans that carry history;
//  4. collisions between preserved history and fresh placements are impossible;
//  5. if the exact count cannot be achieved, NOTHING is persisted and the existing error banner
//     reports the failure (`.server(reference: "replan-insufficient-capacity")`).
//
//  Option A carve-out — history-free plans: a plan with NO completed/skipped/in-progress session
//  has nothing to protect, so it keeps the pre-G09 contract: the WHOLE week is regenerated from
//  a fresh planner run, and a stale placeholder count is corrected back to the planner's full
//  schedule. Rules 1–5 above govern plans that carry history; #9 pins the history-free
//  equivalence and #13 the mismatched-count regression (including ".saved only after an
//  accepted write").
//
//  Every test is clock-pinned (CONTRIBUTING §7): t0 = pinned local noon … t1 = t0 + 1 h, the
//  instant `replan()` runs. No `Date.now`, no sleeps, no random.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Re-plan history preservation (F06 G09)")
@MainActor
struct StudyPlanReplanHistoryTests {

    /// Pinned epoch whose local wall time is noon-ish on every UTC offset in [-12, +14] — so
    /// t0 + 1 h is guaranteed the same calendar day and both schedules share one base day.
    private let t0 = Date(timeIntervalSince1970: 1_772_971_200)   // mod 86400 == 43200 (12:00 local-ish)
    private let t1 = Date(timeIntervalSince1970: 1_772_974_800)   // t0 + 3600 — the replan clock

    private func makeInput(
        weeklyHours: Int = 8,
        intensity: StudyIntensity = .light,          // 8 h × 30 min → N = 16 sessions
        examDates: [CourseExam] = []
    ) -> StudyPlanInput {
        StudyPlanInput(
            subjects: ["Maths", "Physics"],
            weeklyHours: weeklyHours,
            examDates: examDates,
            intensity: intensity
        )
    }

    /// The original week exactly as the planner built it at t0, with statuses applied by index.
    private func originalPlan(
        input: StudyPlanInput,
        completed: [Int] = [],
        skipped: [Int] = [],
        inProgress: [Int] = []
    ) -> StudyPlan {
        var sessions = StudyPlanner.schedule(input, now: t0)
        for i in completed where i < sessions.count { sessions[i].status = .completed }
        for i in skipped where i < sessions.count { sessions[i].status = .skipped }
        for i in inProgress where i < sessions.count { sessions[i].startedAt = t0 }
        return StudyPlan(
            id: "plan-1",
            input: input,
            sessions: sessions,
            createdAt: t0,
            updatedAt: t0
        )
    }

    /// In-memory store seeded with `plan`, plus a VM whose clock is pinned to t1.
    private func makeVM(_ plan: StudyPlan) -> (StudyPlanViewModel, InMemoryStudyPlanStore) {
        let store = InMemoryStudyPlanStore(seededWith: [plan])
        let clock = t1
        let vm = StudyPlanViewModel(store: store, now: { clock })
        return (vm, store)
    }

    /// Half-open [start, start + estimatedMinutes) intersection — independent copy of the
    /// production rule (minutes converted to seconds for `Date` arithmetic), so the tests verify
    /// rather than echo the implementation.
    private func collides(_ a: StudySession, _ b: StudySession) -> Bool {
        let aEnd = a.scheduledAt.addingTimeInterval(TimeInterval(a.estimatedMinutes) * 60)
        let bEnd = b.scheduledAt.addingTimeInterval(TimeInterval(b.estimatedMinutes) * 60)
        return a.scheduledAt < bEnd && b.scheduledAt < aEnd
    }
}

// MARK: - History is preserved


extension StudyPlanReplanHistoryTests {

    /// #1 Completed sessions survive a re-plan byte-for-byte: same id, same time, same status,
    /// same startedAt. The re-plan only touches the unstarted pending remainder.
    @Test("Completed sessions are preserved exactly")
    func completedSessionsArePreserved() async throws {
        let input = makeInput()
        let original = originalPlan(input: input, completed: [0, 1, 2])
        let (vm, store) = makeVM(original)
        await vm.load()

        await vm.replan()

        #expect(vm.lastReplanOutcome == .saved)
        let saved = try #require(try await store.all().first)
        #expect(saved.sessions.count == original.sessions.count, "count invariant")
        for i in 0..<3 {
            let before = original.sessions[i]
            let after = saved.sessions.first { $0.id == before.id }
            #expect(after != nil, "completed session id kept")
            #expect(after?.scheduledAt == before.scheduledAt)
            #expect(after?.estimatedMinutes == before.estimatedMinutes)
            #expect(after?.status == .completed)
            #expect(after?.startedAt == before.startedAt)
        }
    }

    /// #2 Skipped sessions are history too — they keep their ids and `.skipped` status instead of
    /// being resurrected as fresh pending work.
    @Test("Skipped sessions are preserved exactly")
    func skippedSessionsArePreserved() async throws {
        let input = makeInput()
        let original = originalPlan(input: input, skipped: [3, 4])
        let (vm, store) = makeVM(original)
        await vm.load()

        await vm.replan()

        #expect(vm.lastReplanOutcome == .saved)
        let saved = try #require(try await store.all().first)
        #expect(saved.sessions.count == original.sessions.count, "count invariant")
        for i in [3, 4] {
            let before = original.sessions[i]
            let after = saved.sessions.first { $0.id == before.id }
            #expect(after != nil, "skipped session id kept")
            #expect(after?.status == .skipped)
            #expect(after?.scheduledAt == before.scheduledAt)
        }
    }

    /// #3 An in-progress session (`.pending` + `startedAt`) keeps its id, its time AND its
    /// `startedAt` chip; only pending NEVER-started sessions get new identities.
    @Test("In-progress session survives; only unstarted pending are replaced")
    func inProgressSessionIsPreservedAndOnlyUnstartedPendingAreReplaced() async throws {
        let input = makeInput()
        let original = originalPlan(input: input, inProgress: [0])
        let (vm, store) = makeVM(original)
        await vm.load()

        await vm.replan()

        #expect(vm.lastReplanOutcome == .saved)
        let saved = try #require(try await store.all().first)
        #expect(saved.sessions.count == original.sessions.count, "count invariant")

        // The live (in-progress) session is untouched.
        let live = original.sessions[0]
        let kept = saved.sessions.first { $0.id == live.id }
        #expect(kept != nil, "in-progress id kept")
        #expect(kept?.startedAt == t0, "in-progress startedAt kept")
        #expect(kept?.status == .pending)
        #expect(kept?.scheduledAt == live.scheduledAt)

        // None of the never-started pending sessions survived — they were all re-placed.
        let replacedIds = original.sessions
            .filter { $0.status == .pending && $0.startedAt == nil }
            .map(\.id)
        let savedIds = Set(saved.sessions.map(\.id))
        #expect(replacedIds.allSatisfy { !savedIds.contains($0) }, "unstarted pending re-placed")
    }
}


extension StudyPlanReplanHistoryTests {

    /// #4 THE COUNT INVARIANT: 3 completed + 2 skipped + 1 in-progress + rest pending → after the
    /// re-plan the totals are identical; only the never-started pending set changed identity.
    @Test("Session count invariant holds for a mixed-status plan")
    func countInvariantHoldsForMixedStatusPlan() async throws {
        let input = makeInput()                       // N = 16
        let original = originalPlan(input: input, completed: [0, 1, 2], skipped: [3, 4], inProgress: [5])
        let (vm, store) = makeVM(original)
        await vm.load()

        await vm.replan()

        #expect(vm.lastReplanOutcome == .saved)
        let saved = try #require(try await store.all().first)

        #expect(saved.sessions.count == original.sessions.count)
        #expect(saved.sessions.filter { $0.status == .completed }.count == 3)
        #expect(saved.sessions.filter { $0.status == .skipped }.count == 2)
        let live = saved.sessions.filter { $0.status == .pending && $0.startedAt != nil }
        #expect(live.count == 1)
        let fresh = saved.sessions.filter { $0.status == .pending && $0.startedAt == nil }
        // Precomputed outside the macro: an arithmetic RHS inside #expect's expansion made the
        // CI type-checker time out ("unable to type-check this expression in reasonable time").
        let expectedFresh = 16 - 3 - 2 - 1
        #expect(fresh.count == expectedFresh, "target filled exactly — no lost sessions")
    }

    /// #5 COLLISION REGRESSION: sessions 0 and 1 of the original plan occupy the SAME time slot
    /// (one slot, two subjects). Preserve BOTH as history; the re-plan at the same base day must
    /// never hand that slot to a fresh session, and must still fill the exact target.
    @Test("Re-plan never double-books a preserved slot")
    func replanNeverDoubleBooksPreservedSlots() async throws {
        let input = makeInput()
        let original = originalPlan(input: input, skipped: [0, 1])
        #expect(original.sessions[0].scheduledAt == original.sessions[1].scheduledAt,
                "fixture sanity: index 0/1 share one slot")
        let (vm, store) = makeVM(original)
        await vm.load()

        await vm.replan()

        #expect(vm.lastReplanOutcome == .saved)
        let saved = try #require(try await store.all().first)
        #expect(saved.sessions.count == original.sessions.count, "count invariant")

        let preserved = Array(original.sessions.prefix(2))
        let placed = saved.sessions.filter { s in !preserved.contains { $0.id == s.id } }
        #expect(placed.count == 14, "target = 16 − 2")

        for p in preserved {
            for c in placed {
                #expect(!collides(p, c), "preserved \(p.subject) vs fresh \(c.subject)")
            }
            #expect(!placed.contains { $0.scheduledAt == p.scheduledAt },
                    "the preserved slot itself is not reused")
        }
    }

    /// #6 EXAM-CLAMP REGRESSION (reuses the F05b shape): a hard exam in 2 days + a deep pool
    /// produces sessions that the midnight clamp moved off the plain 17:00 grid (times before
    /// 17:00 on the exam day). Preserve them as history; the re-plan must neither double-book
    /// them nor change the count. Exercises the two-pass path when collisions exceed the target.
    @Test("Clamped exam-week sessions are never double-booked")
    func clampedExamWeekSessionsAreNeverDoubleBooked() async throws {
        let examDate = Calendar.current.date(byAdding: .day, value: 2, to: t0)!
        let input = makeInput(
            weeklyHours: 20,                            // 20 h × 30 min → N = 80 (deep slots)
            intensity: .light,
            examDates: [CourseExam(subject: "Maths", date: examDate)]
        )
        let original = originalPlan(input: input)

        // History = every session the midnight clamp pulled below 17:00 (must exist in this
        // fixture — otherwise this test would silently stop testing clamping).
        let clampedIndices = original.sessions.indices.filter {
            Calendar.current.component(.hour, from: original.sessions[$0].scheduledAt) < 17
        }
        #expect(!clampedIndices.isEmpty, "fixture sanity: clamped sessions exist")
        var history = original
        for i in clampedIndices { history.sessions[i].status = .skipped }
        for i in original.sessions.indices.prefix(4) { history.sessions[i].status = .completed }

        let (vm, store) = makeVM(history)
        await vm.load()
        await vm.replan()

        #expect(vm.lastReplanOutcome == .saved)
        let saved = try #require(try await store.all().first)
        #expect(saved.sessions.count == original.sessions.count, "count invariant")

        let preservedIds = Set(history.sessions.filter { $0.status != .pending }.map(\.id))
        let preserved = history.sessions.filter { preservedIds.contains($0.id) }
        let placed = saved.sessions.filter { !preservedIds.contains($0.id) }
        #expect(placed.count == original.sessions.count - preserved.count)
        for p in preserved {
            for c in placed {
                #expect(!collides(p, c), "clamped \(p.scheduledAt) vs fresh \(c.scheduledAt)")
            }
        }
    }
}


extension StudyPlanReplanHistoryTests {

    /// #7 FORCED SHORTFALL — the exact-count guard: two history sessions span the whole
    /// scheduling window (10 080 min = 7 days each), so every candidate collides — even after the
    /// single bounded second pass. The re-plan must refuse: `.server(reference:
    /// "replan-insufficient-capacity")` on the banner, `lastReplanOutcome == .insufficientCapacity`,
    /// and — asserted rigorously — the ENTIRE persisted plan (sessions, ids, statuses, startedAt,
    /// createdAt, updatedAt, input) deep-equals the snapshot taken before the failed re-plan.
    @Test("Forced shortfall fails visibly and leaves the persisted plan entirely unchanged")
    func forcedShortfallPreservesTheEntirePersistedPlan() async throws {
        let input = makeInput()                       // 8 h light → pool sized for 16
        let baseDay = Calendar.current.startOfDay(for: t0)

        // 2 giant history sessions covering every candidate + 8 replaceable pending (target = 8).
        var sessions: [StudySession] = [
            StudySession(subject: "Maths", estimatedMinutes: 10_080, scheduledAt: baseDay, status: .completed),
            StudySession(subject: "Physics", estimatedMinutes: 10_080, scheduledAt: baseDay, status: .skipped),
        ]
        let grid = StudyPlanner.schedule(input, now: t0)
        for i in 0..<8 {
            sessions.append(StudySession(
                subject: grid[i].subject,
                estimatedMinutes: input.intensity.sessionMinutes,
                scheduledAt: grid[i].scheduledAt,
                status: .pending
            ))
        }
        let plan = StudyPlan(id: "plan-fail", input: input, sessions: sessions, createdAt: t0, updatedAt: t0)

        let store = InMemoryStudyPlanStore(seededWith: [plan])
        let before = try await store.all()            // FULL deep snapshot before the failure
        #expect(before.count == 1)

        let clock = t1
        let vm = StudyPlanViewModel(store: store, now: { clock })
        await vm.load()
        await vm.replan()

        // 1. The failure is surfaced through the app's existing error mechanism.
        #expect(vm.lastReplanOutcome == .insufficientCapacity)
        #expect(vm.error == .server(reference: "replan-insufficient-capacity"),
                "SFErrorBanner shows AppError.server — generic wording accepted for M3")

        // 2. The ENTIRE persisted plan is untouched — not only the sessions array.
        let after = try await store.all()
        #expect(after == before, "whole-plan deep equality: ids, statuses, timestamps, updatedAt, input")

        // 3. Recovery: "Try again" reloads the original plan, exactly as it was.
        await vm.load()
        #expect(vm.plan == before.first)
    }

    /// #8 ALL-COMPLETED NO-OP: nothing is replaceable (target = 0) → the re-plan saves without
    /// touching a single session. The sessions array is bit-identical.
    @Test("Fully completed plan: re-plan is a no-op save that keeps every session")
    func allCompletedPlanIsANoOpSave() async throws {
        let input = makeInput()
        let original = originalPlan(input: input, completed: Array(0..<16))
        let (vm, store) = makeVM(original)
        await vm.load()

        await vm.replan()

        #expect(vm.lastReplanOutcome == .saved)
        let saved = try #require(try await store.all().first)
        #expect(saved.sessions == original.sessions, "every session bit-identical (updatedAt may bump)")
        #expect(vm.error == nil)
    }

    /// #9 ALL-PENDING LEGACY EQUIVALENCE: a plan with no history behaves exactly like the old
    /// always-rebuild re-plan — same subjects, times, minutes and statuses as a fresh
    /// `StudyPlanner.schedule(input, now: t1)` (only ids are re-rolled, as before). Option A's
    /// legacy branch runs here: the equivalence is enforced by construction, not incidental.
    @Test("History-free plan matches a fresh planner run at the replan clock")
    func historyFreePlanMatchesFreshPlannerRun() async throws {
        let input = makeInput()
        let original = originalPlan(input: input)     // all pending, none started
        let (vm, store) = makeVM(original)
        await vm.load()

        await vm.replan()

        #expect(vm.lastReplanOutcome == .saved)
        let saved = try #require(try await store.all().first)
        let fresh = StudyPlanner.schedule(input, now: t1)
        #expect(saved.sessions.count == fresh.count)
        for (after, expected) in zip(saved.sessions, fresh) {
            #expect(after.subject == expected.subject)
            #expect(after.scheduledAt == expected.scheduledAt)
            #expect(after.estimatedMinutes == expected.estimatedMinutes)
            #expect(after.status == expected.status)
        }
    }
}


extension StudyPlanReplanHistoryTests {

    /// #10 F07 REGRESSION: Home progress splits into HISTORY-derived fields (minutesThisWeek,
    /// itemsCompleted, streak, per-subject completed counts and studied minutes — computed from
    /// completed work) and one PLAN-DERIVED field: `SubjectProgress.totalSessions`, which
    /// `ProgressCalculator.subjectProgress` documents as "how many sessions the plan gave a
    /// subject". A history-preserving re-plan must leave every history-derived field identical;
    /// unstarted sessions may legitimately redistribute between subjects, but no session may be
    /// lost or created (G09's count invariant) and a subject can never show more completions
    /// than it has sessions.
    @Test("Re-plan does not change Home progress metrics")
    func replanDoesNotChangeProgressMetrics() async throws {
        let input = makeInput()
        let original = originalPlan(input: input, completed: [0, 1, 2])
        let (vm, store) = makeVM(original)
        await vm.load()

        let before = ProgressCalculator.snapshot(
            ProgressInput(materials: [], decks: [], quizzes: [], plan: original, weeklyGoalHours: nil, now: t1)
        )

        await vm.replan()

        #expect(vm.lastReplanOutcome == .saved)
        let saved = try #require(try await store.all().first)
        let after = ProgressCalculator.snapshot(
            ProgressInput(materials: [], decks: [], quizzes: [], plan: saved, weeklyGoalHours: nil, now: t1)
        )

        // History-derived fields: byte-identical before and after the re-plan.
        #expect(after.masteryPercent == before.masteryPercent, "mastery comes from cards and quizzes")
        #expect(after.streakDays == before.streakDays, "streak comes from activity history")
        #expect(after.minutesThisWeek == before.minutesThisWeek, "weekly minutes come from completed work")
        #expect(after.weeklyGoalHours == before.weeklyGoalHours, "the goal is profile data")
        #expect(after.weeklyActivity == before.weeklyActivity, "daily activity comes from completed work")
        #expect(after.topics == before.topics, "topic mastery comes from quiz history")
        #expect(after.itemsCompleted == before.itemsCompleted, "history counter")
        #expect(after.quizzesTaken == before.quizzesTaken, "history counter")
        #expect(after.averageQuizScore == before.averageQuizScore, "history statistic")
        #expect(after.cardsMastered == before.cardsMastered, "history counter")
        #expect(after.cardsTotal == before.cardsTotal, "library size, not plan placement")

        // Plan-derived shape: the same subjects with the same completed history; only the
        // distribution of NOT-yet-started sessions across subjects may change.
        #expect(after.subjects.map(\.subject) == before.subjects.map(\.subject), "same subject set")
        #expect(after.subjects.map(\.completedSessions) == before.subjects.map(\.completedSessions),
                "completed history per subject is protected")
        #expect(after.subjects.map(\.minutesStudied) == before.subjects.map(\.minutesStudied),
                "studied minutes per subject are protected")
        let afterTotal = after.subjects.map(\.totalSessions).reduce(0, +)
        let beforeTotal = before.subjects.map(\.totalSessions).reduce(0, +)
        #expect(afterTotal == beforeTotal, "no session lost or created by the re-plan")
        #expect(after.subjects.allSatisfy { $0.completedSessions <= $0.totalSessions },
                "a subject can never show more completions than it has sessions")
    }

    /// #11 THE SECOND PASS, PROVEN: preserve sessions 1 and 3 — each shares its slot with another
    /// subject (pairs 0/1 and 2/3), so pass 1 loses FOUR candidates (2 collisions per preserved
    /// session) while the target only drops by two: eligible = 16 − 4 = 12 < target = 14.
    /// Success therefore CANNOT come from pass 1 — the assertion below proves ≥ 1 placed time
    /// lies outside pass 1's pool (pass 2 adds only occ 8: one distinct shared time). Bounded:
    /// exactly two planner runs, no loops.
    @Test("Insufficient first pass triggers the single bounded second pass")
    func secondPassFillsTheGapExactlyOnce() async throws {
        let input = makeInput()
        let original = originalPlan(input: input, skipped: [1, 3])
        // Fixture sanity: preserved sessions 1 and 3 each share their slot with another subject.
        #expect(original.sessions[1].scheduledAt == original.sessions[0].scheduledAt)
        #expect(original.sessions[3].scheduledAt == original.sessions[2].scheduledAt)

        let (vm, store) = makeVM(original)
        await vm.load()
        await vm.replan()

        #expect(vm.lastReplanOutcome == .saved)
        let saved = try #require(try await store.all().first)
        #expect(saved.sessions.count == original.sessions.count, "count invariant")

        let preservedIds: Set<StudySession.ID> = [original.sessions[1].id, original.sessions[3].id]
        let placed = saved.sessions.filter { !preservedIds.contains($0.id) }
        #expect(placed.count == 14, "target = 16 − 2")

        // No collision with the two preserved history sessions.
        for p in [original.sessions[1], original.sessions[3]] {
            for c in placed { #expect(!collides(p, c)) }
        }

        // Proof the second pass ran: pass 1's pool holds occ 0…7 only, and its 12 non-colliding
        // candidates cannot fill 14 targets — a pass-1-only result draws every placed time from
        // pass 1's pool (difference 0). Pass 2's 18-slot pool adds occ 8 only: one distinct new
        // time (day1 17:30, shared by both subjects), so the difference is exactly ≥ 1 — the
        // threshold that discriminates pass 2 from pass 1.
        let pass1PoolTimes = Set(StudyPlanner.schedule(input, now: t1).map(\.scheduledAt))
        let placedTimes = Set(placed.map(\.scheduledAt))
        #expect(placedTimes.subtracting(pass1PoolTimes).count >= 1,
                "a placed time outside the first-pass pool proves pass 2 ran")
    }
}

extension StudyPlanReplanHistoryTests {

    /// #12 PERSISTENCE-FAILURE REGRESSION (Fix A): `persist` swallows store errors into state, so
    /// the outcome must never claim `.saved` for a write the store rejected. The store's own
    /// failure injection forces the rejection; the persisted plan — including `updatedAt` — stays
    /// byte-for-byte. Covers the replaceable-sessions path (target > 0) and the all-history
    /// no-op (target == 0); the third exit path — the history-free legacy regeneration — pins
    /// the same gate in #13.
    @Test("Forced store failure: outcome is nil, never .saved, and the plan is untouched")
    func forcedStoreFailureDoesNotReportSaved() async throws {
        let input = makeInput()
        let clock = t1

        // Phase 1 — normal path (target = 13: three completed sessions preserved).
        let original = originalPlan(input: input, completed: [0, 1, 2])
        let store = InMemoryStudyPlanStore(seededWith: [original])
        let before = try await store.all()            // FULL snapshot, including updatedAt
        #expect(before.count == 1)

        let vm = StudyPlanViewModel(store: store, now: { clock })
        await vm.load()                               // load BEFORE injecting the failure
        await store.forceFailure(.storageFailed)       // store.add now rejects every write
        await vm.replan()

        #expect(vm.lastReplanOutcome != .saved, "a rejected write must never report .saved")
        #expect(vm.lastReplanOutcome == nil, "nil = neither saved nor a capacity refusal")
        #expect(vm.error == .server(reference: "study-plan-store-failed"),
                "existing storage error exposed — AppError.from maps StudyPlanError.asAppError")

        await store.forceFailure(nil)                  // restore the store
        let after = try await store.all()
        #expect(after == before, "whole plan unchanged — sessions, ids, statuses, updatedAt")
        #expect(after.first?.updatedAt == before.first?.updatedAt, "updatedAt specifically untouched")

        // Phase 2 — the target == 0 no-op path follows the same rule.
        let allDone = originalPlan(input: input, completed: Array(0..<16))
        let store2 = InMemoryStudyPlanStore(seededWith: [allDone])
        let before2 = try await store2.all()
        let vm2 = StudyPlanViewModel(store: store2, now: { clock })
        await vm2.load()
        await store2.forceFailure(.storageFailed)
        await vm2.replan()

        #expect(vm2.lastReplanOutcome != .saved, "no-op path must not report .saved either")
        #expect(vm2.lastReplanOutcome == nil)
        #expect(vm2.error == .server(reference: "study-plan-store-failed"))

        await store2.forceFailure(nil)
        let after2 = try await store2.all()
        #expect(after2 == before2, "no-op path also leaves the plan untouched")
    }
}

extension StudyPlanReplanHistoryTests {

    /// #13 HISTORY-FREE MISMATCHED COUNT → FULL REGENERATION (Option A regression): the stored
    /// plan holds ONE never-started placeholder while the planner's schedule for the same input is
    /// ten sessions (8 h × balanced 45 min). The legacy branch must replace the lone placeholder
    /// with the planner's whole week — the exact opposite of the count-invariant path, which would
    /// have left the plan at one session. `StudyPlanViewModelTests.replanRegenerates` pins the
    /// resulting COUNT; this pins the rest of the contract: the placeholder id is gone, the
    /// sessions are the fresh planner run's, `updatedAt` records the re-plan — and `.saved` is
    /// claimed only after the store accepted the write, never when it rejects the write.
    @Test("History-free mismatched plan regenerates the full week; .saved only on accepted writes")
    func historyFreeMismatchedPlanRegeneratesFullWeek() async throws {
        let input = makeInput(weeklyHours: 8, intensity: .balanced)   // 8 h × 45 min → 10 sessions
        let lone = StudySession(id: "lone-placeholder", subject: "Maths",
                                estimatedMinutes: 45, scheduledAt: t0, status: .pending)
        let original = StudyPlan(id: "plan-mismatch", input: input, sessions: [lone],
                                 createdAt: t0, updatedAt: t0)
        let (vm, store) = makeVM(original)
        await vm.load()

        await vm.replan()

        // 1. The lone placeholder is replaced by the planner's full week (ten sessions).
        #expect(vm.lastReplanOutcome == .saved)
        let saved = try #require(try await store.all().first)
        let fresh = StudyPlanner.schedule(input, now: t1)
        #expect(fresh.count == 10, "fixture: the planner expects ten sessions")
        #expect(saved.sessions.count == 10, "history-free plans regenerate — the count is corrected")
        #expect(!saved.sessions.map(\.id).contains("lone-placeholder"), "the placeholder is gone")
        #expect(saved.sessions.allSatisfy { $0.status == .pending && $0.startedAt == nil })
        #expect(saved.sessions.map(\.subject) == fresh.map(\.subject), "planner subjects, in order")
        #expect(saved.sessions.map(\.scheduledAt) == fresh.map(\.scheduledAt), "planner times")
        #expect(saved.sessions.map(\.estimatedMinutes) == fresh.map(\.estimatedMinutes))
        #expect(saved.updatedAt == t1, "the re-plan is recorded on updatedAt")

        // 2. Same rule as the other two exit paths: a rejected write must never report `.saved`.
        let clock = t1
        let store2 = InMemoryStudyPlanStore(seededWith: [original])
        let before = try await store2.all()
        let vm2 = StudyPlanViewModel(store: store2, now: { clock })
        await vm2.load()
        await store2.forceFailure(.storageFailed)
        await vm2.replan()

        #expect(vm2.lastReplanOutcome == nil, "legacy path: nil on rejection, never .saved")
        #expect(vm2.error == .server(reference: "study-plan-store-failed"))

        await store2.forceFailure(nil)
        let after2 = try await store2.all()
        #expect(after2 == before, "the rejected write persisted nothing")
    }
}

