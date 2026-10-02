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
