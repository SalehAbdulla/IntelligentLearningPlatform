//
//  StudentHomeViewModel.swift
//  StudyForge
//
//  B05's data (F07): what the student home shows — today's plan, the streak, and how many
//  flashcards are due across every deck.
//
//  WHY IT COMPOSES THE TWO EXISTING VIEW MODELS
//  ---------------------------------------------
//  The dashboard's view model already knows how to assemble `ProgressCalculator`'s inputs, and
//  the plan's view model already knows how to read the store and order its sessions; deriving
//  either again here would be a second copy of logic that is already tested. This type adds only
//  what the home needs beyond them: today's sessions filtered out of the week, the due count, and
//  the "has anything real loaded" flags that keep the header from claiming a streak or a plan the
//  stores never produced.
//

import Foundation

@MainActor
@Observable
final class StudentHomeViewModel {

    private let planViewModel: StudyPlanViewModel
    private let progressViewModel: ProgressDashboardViewModel
    private let decks: any DeckStore

    /// Cards due now across every deck, or `nil` until the store has been read — a failed read
    /// leaves the badge hidden rather than showing a zero the store never reported.
    private(set) var dueCards: Int?

    /// True once `load()` has finished (successfully or not), so the plan card shows a spinner
    /// rather than flashing its empty state before the stores have answered.
    private(set) var hasLoaded = false

    init(
        store: any StudyPlanStore,
        materials: any MaterialStore,
        decks: any DeckStore,
        quizzes: any QuizStore,
        profile: any ProfileService
    ) {
        self.planViewModel = StudyPlanViewModel(store: store)
        self.progressViewModel = ProgressDashboardViewModel(
            materials: materials,
            decks: decks,
            quizzes: quizzes,
            studyPlans: store,
            profile: profile
        )
        self.decks = decks
    }

    // MARK: Today's plan

    var plan: StudyPlan? { planViewModel.plan }
    var planError: AppError? { planViewModel.error }
    var planHeading: String { planViewModel.title }
    var planEmptyTitle: String { planViewModel.emptyTitle }
    var planEmptyBody: String { planViewModel.emptyBody }
    var planNoSessionsTitle: String { planViewModel.noSessionsTitle }

    func planDuration(_ minutes: Int) -> String { planViewModel.durationTitle(minutes) }

    /// Today's sessions, earliest first — what the hero card lists (the view draws the next three).
    ///
    /// Calendar days, not a rolling window: "today" is the day the planner scheduled for, so a
    /// session at 00:30 belongs to the day it was placed on, not to yesterday.
    var todaySessions: [StudySession] {
        guard let plan else { return [] }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return plan.sessions
            .filter { calendar.startOfDay(for: $0.scheduledAt) == today }
            .sorted { $0.scheduledAt < $1.scheduledAt }
    }

    // MARK: Streak

    /// Consecutive active days from `ProgressCalculator`, or `nil` when the snapshot has no data —
    /// the header omits the pill instead of showing a streak the student has not earned.
    var streakDays: Int? {
        guard let snapshot = progressViewModel.snapshot, snapshot.hasData else { return nil }
        return snapshot.streakDays
    }

    var streakLabel: String { progressViewModel.streakLabel }
    func streakValue(_ days: Int) -> String { progressViewModel.streakValue(days) }

    // MARK: Load

    func load() async {
        await planViewModel.load()
        await progressViewModel.load()
        dueCards = await Self.dueCardCount(in: decks)
        hasLoaded = true
    }

    private static func dueCardCount(in decks: any DeckStore) async -> Int? {
        guard let decks = try? await decks.all() else { return nil }
        return decks.reduce(0) { $0 + $1.dueCount() }
    }
}
