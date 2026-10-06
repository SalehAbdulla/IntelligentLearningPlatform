//
//  ProgressDashboardViewModel.swift
//  StudyForge
//
//  Presentation logic for F07 — gathers what the student already has from every store, then hands it
//  to `ProgressCalculator` and shows the result.
//
//  WHY IT READS EVERY STORE
//  ------------------------
//  There is no aggregation job yet (see `ProgressSnapshot`), so the dashboard IS the aggregation:
//  it assembles the inputs the calculator needs. The five reads are local and small, and running
//  them together means the screen's loading state is one round trip rather than five.
//

import Foundation

@MainActor
@Observable
final class ProgressDashboardViewModel {

    private(set) var state: LoadState<ProgressSnapshot> = .idle

    private let materials: any MaterialStore
    private let decks: any DeckStore
    private let quizzes: any QuizStore
    private let studyPlans: any StudyPlanStore
    private let profile: any ProfileService

    init(
        materials: any MaterialStore,
        decks: any DeckStore,
        quizzes: any QuizStore,
        studyPlans: any StudyPlanStore,
        profile: any ProfileService
    ) {
        self.materials = materials
        self.decks = decks
        self.quizzes = quizzes
        self.studyPlans = studyPlans
        self.profile = profile
    }

    // MARK: Derived

    var snapshot: ProgressSnapshot? { state.value }
    var isLoading: Bool { state.isLoading }
    var error: AppError? { if case .failed(let error) = state { return error }; return nil }

    /// True only when the stores loaded but there is genuinely nothing to show.
    var showsEmpty: Bool { state.value?.hasData == false }

    // MARK: Copy

    var title: String { L10n.progressTitle.string }
    var emptyTitle: String { L10n.progressEmptyTitle.string }
    var emptyBody: String { L10n.progressEmptyBody.string }
    var masteryLabel: String { L10n.progressMastery.string }
    var streakLabel: String { L10n.progressStreak.string }
    var hoursLabel: String { L10n.progressHoursThisWeek.string }
    var weeklyHeading: String { L10n.progressWeeklyHeading.string }
    var goalHeading: String { L10n.progressGoalHeading.string }
    var subjectsHeading: String { L10n.progressSubjectsHeading.string }
    var noSubjectsTitle: String { L10n.progressNoSubjects.string }
    var radarTitle: String { L10n.progressRadarTitle.string }
    var radarEmptyTitle: String { L10n.progressRadarEmpty.string }
    var weakTopicsHeading: String { L10n.progressWeakTopicsHeading.string }
    var noWeakTopicsTitle: String { L10n.progressNoWeakTopics.string }
    var quizzesTakenLabel: String { L10n.progressQuizzesTaken.string }
    var cardsMasteredLabel: String { L10n.progressCardsMastered.string }

    func masteryValue(_ percent: Int) -> String { L10n.progressMasteryValue.string(percent) }
    func streakValue(_ days: Int) -> String { L10n.progressStreakValue.string(days) }
    func hoursValue(_ hours: Int) -> String { L10n.progressHoursValue.string(hours) }

    /// Whole hours, rounded — a dashboard states "5 h", not "4 h 37 m".
    func hours(fromMinutes minutes: Int) -> Int { Int((Double(minutes) / 60).rounded()) }

    func goalCaption(_ progress: ProgressSnapshot) -> String {
        guard let goal = progress.weeklyGoalHours else { return "" }
        return L10n.progressGoalCaption.string(hours(fromMinutes: progress.minutesThisWeek), goal)
    }

    func cardsValue(_ mastered: Int, _ total: Int) -> String {
        L10n.progressCardsValue.string(mastered, total)
    }

    // MARK: Actions

    func load() async {
        state = .loading
        do {
            async let materials = materials.all()
            async let decks = decks.all()
            async let quizzes = quizzes.all()
            async let plans = studyPlans.all()

            // The goal comes from the profile, which may not be readable — a dashboard should still
            // render without it, so the goal bar is simply omitted rather than the screen failing.
            let stored = try? await profile.fetchProfile()

            let snapshot = ProgressCalculator.snapshot(
                ProgressInput(
                    materials: try await materials,
                    decks: try await decks,
                    quizzes: try await quizzes,
                    plan: try await plans.first,
                    weeklyGoalHours: stored?.weeklyStudyGoalHours,
                    now: .now
                )
            )
            state = .loaded(snapshot)
        } catch {
            state = .failed(AppError.from(error))
        }
    }
}