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

    init(store: any StudyPlanStore) {
        self.store = store
    }

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

    func replan() async {
        guard var plan else { return }
        plan.sessions = StudyPlanner.schedule(plan.input, now: .now)
        plan.updatedAt = .now
        await persist(plan)
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
