//
//  StudyPlanViewModel.swift
//  StudyForge
//
//  Presentation logic for F06's week view — the latest plan, its sessions grouped by day, and the
//  mark-done / skip / re-plan actions.
//

import Foundation

@MainActor
@Observable
final class StudyPlanViewModel {

    private(set) var state: LoadState<StudyPlan> = .idle

    private let store: any StudyPlanStore

    /// The re-plan clock. Injected so tests can pin time instead of reading the machine clock —
    /// the house rule: never assert on `Date.now` (CONTRIBUTING §7).
    private let now: () -> Date

    init(store: any StudyPlanStore, now: @escaping () -> Date = { .now }) {
        self.store = store
        self.now = now
    }

    // MARK: Re-plan outcome (G09)

    /// What the most recent re-plan did.
    ///
    /// `insufficientCapacity` means NOTHING was saved: the plan on disk is byte-for-byte what it
    /// was, and the view shows the existing error banner (`.server(reference:
    /// "replan-insufficient-capacity")`) rather than a silently reduced schedule.
    enum ReplanOutcome: Equatable {
        case saved
        case insufficientCapacity
    }

    private(set) var lastReplanOutcome: ReplanOutcome?

    // MARK: Derived

    var plan: StudyPlan? { state.value }
    var isEmpty: Bool { if case .empty = state { return true }; return false }
    var isLoading: Bool { state.isLoading }
    var error: AppError? { if case .failed(let error) = state { return error }; return nil }

    /// Sessions grouped by day, ascending, each group ordered by start time.
    var sessionsByDay: [(day: Date, sessions: [StudySession])] {
        guard let plan else { return [] }
        let grouped = Dictionary(grouping: plan.sessions) {
            Calendar.current.startOfDay(for: $0.scheduledAt)
        }
        return grouped.keys.sorted().map { day in
            (day, (grouped[day] ?? []).sorted { $0.scheduledAt < $1.scheduledAt })
        }
    }

    // MARK: Copy

    var title: String { L10n.planTitle.string }
    var emptyTitle: String { L10n.planEmptyTitle.string }
    var emptyBody: String { L10n.planEmptyBody.string }
    var newPlanTitle: String { L10n.planNewPlan.string }
    var weekHeading: String { L10n.planWeekHeading.string }
    var noSessionsTitle: String { L10n.planNoSessions.string }
    var markDoneTitle: String { L10n.planMarkDone.string }
    var skipTitle: String { L10n.planSkip.string }
    var replanTitle: String { L10n.planReplan.string }

    // MARK: Session detail (G08)

    var sessionDetailTitle: String { L10n.planSessionDetail.string }
    var durationLabel: String { L10n.planDuration.string }
    var scheduledLabel: String { L10n.planScheduledFor.string }
    var statusLabel: String { L10n.planStatusLabel.string }
    var startedLabel: String { L10n.planStarted.string }
    var startNowTitle: String { L10n.planStartNow.string }
    var rescheduleTitle: String { L10n.planReschedule.string }
    var inProgressTitle: String { L10n.planInProgress.string }

    func statusTitle(_ status: StudySessionStatus) -> String {
        switch status {
        case .pending: L10n.planStatusPending.string
        case .completed: L10n.planStatusCompleted.string
        case .skipped: L10n.planStatusSkipped.string
        }
    }

    func durationTitle(_ minutes: Int) -> String { L10n.planMinutes.string(minutes) }

    /// One session by id, re-read from the plan so the sheet reflects live state after an action.
    func session(id: String) -> StudySession? {
        plan?.sessions.first { $0.id == id }
    }

    /// The detail sheet's summary lines, built here so the view only draws them — the same split
    /// `SFDetailRow` documents.
    func detailRows(for session: StudySession) -> [DetailRow] {
        var rows: [DetailRow] = [
            DetailRow(id: "duration", label: durationLabel, value: durationTitle(session.estimatedMinutes)),
            DetailRow(
                id: "scheduled",
                label: scheduledLabel,
                value: session.scheduledAt.formatted(date: .abbreviated, time: .shortened)
            ),
            DetailRow(id: "status", label: statusLabel, value: statusTitle(session.status)),
        ]
        if let started = session.startedAt {
            rows.append(DetailRow(
                id: "started",
                label: startedLabel,
                value: started.formatted(date: .omitted, time: .shortened)
            ))
        }
        return rows
    }

    // MARK: Actions

    /// Loads the most recently updated plan.
    func load() async {
        state = .loading
        do {
            let plans = try await store.all()
            state = plans.first.map { .loaded($0) } ?? .empty
        } catch {
            state = .failed(AppError.from(error))
        }
    }

    func markDone(_ session: StudySession) async {
        await setStatus(.completed, for: session)
    }

    func skip(_ session: StudySession) async {
        await setStatus(.skipped, for: session)
    }

    /// Marks a session as begun.
    ///
    /// A separate fact from `status`: the student has started, and has not yet said they finished.
    /// Idempotent — starting an already-started session leaves the original time alone rather than
    /// resetting the clock every time the sheet is opened.
    func start(_ session: StudySession) async {
        guard var plan, let index = plan.sessions.firstIndex(where: { $0.id == session.id }) else { return }
        guard plan.sessions[index].startedAt == nil else { return }
        plan.sessions[index].startedAt = .now
        plan.updatedAt = .now
        await persist(plan)
    }

    /// Moves a session to the same time the next day, back to pending.
    ///
    /// A deterministic one-day push rather than a re-solve: the design's Reschedule is a
    /// per-session nudge, and re-solving the week would move sessions the student did not ask to
    /// move — that is what Re-plan is for. The started marker is cleared, because a session moved
    /// to another day has not been started on the new one.
    func reschedule(_ session: StudySession) async {
        guard var plan, let index = plan.sessions.firstIndex(where: { $0.id == session.id }) else { return }
        plan.sessions[index].scheduledAt = Calendar.current
            .date(byAdding: .day, value: 1, to: session.scheduledAt) ?? session.scheduledAt
        plan.sessions[index].status = .pending
        plan.sessions[index].startedAt = nil
        plan.updatedAt = .now
        await persist(plan)
    }

    /// Re-plans the week WITHOUT erasing what the student already did (G09).
    ///
    /// HISTORY-FREE PLANS KEEP THE PRE-G09 CONTRACT (Option A): when the stored plan has nothing
    /// to protect — no completed, no skipped, no in-progress session, only never-started
    /// placeholders — the re-plan regenerates the WHOLE week from `StudyPlanner.schedule`, exactly
    /// as every re-plan did before G09. There is no history to erase, so the preservation rules
    /// below (written solely to protect history) do not apply, and a stale placeholder count is
    /// corrected back to the planner's full schedule — one placeholder in, a whole week out. Pinned
    /// by `replanRegenerates` (StudyPlanViewModelTests) and by test #13 of this change's suite.
    ///
    /// THREE GROUPS, ONE INVARIANT — plans that carry history:
    /// - `completed` and `skipped` sessions are history — ids, times and statuses stay untouched;
    /// - an in-progress session (`.pending` with `startedAt`) is the student's live state — kept too;
    /// - only pending, NEVER-started sessions are re-placed, so the total count can neither grow
    ///   nor shrink (`preserved + target == sessions.count`).
    ///
    /// WHY TWO PASSES AND AN EXACT-COUNT GUARD
    /// `StudyPlanner.schedule` returns a pool sized from weeklyHours, and preserved sessions can sit
    /// exactly where that pool wants to place new ones (two subjects share a slot; exam clamping
    /// moves sessions off the plain grid). Pass 1 fills the target from a normal pool. If too many
    /// candidates collide, ONE bounded second pass uses a pool sized `target + 2×preserved` — enough
    /// for every app-generated schedule, deliberately NOT claimed as a proof for all inputs. If even
    /// that cannot yield the exact target, nothing is saved: a reduced plan must never be written
    /// silently. The student sees the app's existing error banner and the store keeps the original
    /// plan; tapping "Try again" reloads it unchanged.
    func replan() async {
        guard var plan else { return }

        let preserved = plan.sessions.filter { $0.status != .pending || $0.startedAt != nil }

        // Option A (approved compatibility carve-out): no history anywhere → the pre-G09
        // contract. Regenerate the entire week from a fresh planner run; nothing is "erased"
        // because nothing here was ever done, and a stale placeholder count (one leftover
        // session where the planner wants a full week) is corrected rather than preserved.
        // Outcome follows the same rule as every other exit path: `.saved` is claimed only
        // after the store accepted the write.
        if preserved.isEmpty {
            let clock = now()
            plan.sessions = StudyPlanner.schedule(plan.input, now: clock)
            plan.updatedAt = clock
            lastReplanOutcome = nil
            await persist(plan)
            if case .loaded = state { lastReplanOutcome = .saved }
            return
        }

        let target = plan.sessions.count - preserved.count

        // Nothing left to re-place: the plan is all history (completed/skipped) or live
        // (in-progress). Still save, exactly as re-plan always did, so the action has an effect.
        if target == 0 {
            plan.updatedAt = now()
            // Success is only claimed once the store accepted the write: `persist` reports
            // failures through state, so a stale `.saved` must never survive a rejected save.
            lastReplanOutcome = nil
            await persist(plan)
            if case .loaded = state { lastReplanOutcome = .saved }
            return
        }

        let clock = now()
        var eligible = candidates(
            from: StudyPlanner.schedule(plan.input, now: clock),
            avoiding: preserved
        )

        if eligible.count < target {
            // The single bounded second pass: size the pool for the worst observed collision
            // pattern (each preserved session may claim up to two candidate slots).
            let minutes = plan.input.intensity.sessionMinutes
            let requiredPool = target + 2 * preserved.count
            var expanded = plan.input
            expanded.weeklyHours = (requiredPool * minutes + 59) / 60   // ceil to whole hours
            eligible = candidates(
                from: StudyPlanner.schedule(expanded, now: clock),
                avoiding: preserved
            )
        }

        guard eligible.count >= target else {
            // Exact count unachievable → fail VISIBLY and save NOTHING. The store is not
            // touched, so every original session, id, status, timestamp and `updatedAt`
            // survive exactly as they were.
            lastReplanOutcome = .insufficientCapacity
            state = .failed(.server(reference: "replan-insufficient-capacity"))
            return
        }

        plan.sessions = preserved + Array(eligible.prefix(target))
        plan.updatedAt = clock
        // Same rule as the no-op path above: `.saved` only after the store accepted the write.
        lastReplanOutcome = nil
        await persist(plan)
        if case .loaded = state { lastReplanOutcome = .saved }
    }

    /// Fresh candidates that do not collide with preserved history.
    private func candidates(from fresh: [StudySession], avoiding preserved: [StudySession]) -> [StudySession] {
        fresh.filter { candidate in
            !preserved.contains { collides($0, candidate) }
        }
    }

    /// True when two sessions' half-open [start, start + minutes) intervals intersect — a session
    /// ends exactly where the next one may begin, so adjacency is allowed.
    private func collides(_ a: StudySession, _ b: StudySession) -> Bool {
        let aEnd = a.scheduledAt.addingTimeInterval(TimeInterval(a.estimatedMinutes))
        let bEnd = b.scheduledAt.addingTimeInterval(TimeInterval(b.estimatedMinutes))
        return a.scheduledAt < bEnd && b.scheduledAt < aEnd
    }

    private func setStatus(_ status: StudySessionStatus, for session: StudySession) async {
        guard var plan else { return }
        if let index = plan.sessions.firstIndex(where: { $0.id == session.id }) {
            plan.sessions[index].status = status
        }
        plan.updatedAt = .now
        await persist(plan)
    }

    private func persist(_ plan: StudyPlan) async {
        do {
            try await store.add(plan)
            state = .loaded(plan)
        } catch {
            state = .failed(AppError.from(error))
        }
    }
}
