//
//  StudyPathViewModel.swift
//  StudyForge
//
//  F15 — H05 (`77_Coach_StudyPath_Recommended_{M3}`): the adaptive path, read from F07's weakness
//  data and ordered by the deterministic planner.
//

import Foundation

@MainActor
@Observable
final class StudyPathViewModel {

    private(set) var state: LoadState<[StudyStep]> = .idle
    private(set) var addedToPlan = false

    private let uid: String
    private let planner: any CoachPlanningService
    private let progress: ProgressDashboardViewModel

    init(uid: String, planner: any CoachPlanningService, progress: ProgressDashboardViewModel) {
        self.uid = uid
        self.planner = planner
        self.progress = progress
    }

    // MARK: Derived

    var steps: [StudyStep] { state.value ?? [] }
    var isLoading: Bool { state.isLoading }
    var isEmpty: Bool { if case .empty = state { return true }; return false }
    var error: AppError? { state.error }

    var totalMinutes: Int { steps.reduce(0) { $0 + $1.minutes } }
    var totalLabel: String { L10n.coachPathTotal.string(totalMinutes) }

    // MARK: Copy

    var title: String { L10n.coachPathTitle.string }
    var subtitle: String { L10n.coachPathSubtitle.string }
    var addAllTitle: String { L10n.coachPathAddAll.string }
    var addedTitle: String { L10n.coachPathAdded.string }
    var emptyTitle: String { L10n.coachPathEmpty.string }

    func stepTitle(_ step: StudyStep) -> String {
        switch step.activity {
        case .read: L10n.coachStepRead.string(step.topic)
        case .flashcards: L10n.coachStepFlashcards.string(step.topic)
        case .quiz: L10n.coachStepQuiz.string(step.topic)
        case .review: L10n.coachStepReview.string(step.topic)
        }
    }

    func minutesLabel(_ step: StudyStep) -> String {
        L10n.coachMinutes.string(step.minutes)
    }

    // MARK: Actions

    /// Reads the weakness radar, then asks the planner to order a path over it.
    ///
    /// The mastery numbers come from F05's quiz attempts via F07's calculator — the path is
    /// derived from the student's OWN behaviour, which is what makes it adaptive rather than
    /// generic.
    func load() async {
        state = .loading
        await progress.load()

        let weakTopics = (progress.snapshot?.weakTopics ?? []).map {
            TopicScore(topic: $0.topic, mastery: $0.mastery)
        }

        do {
            state = .from(try await planner.studyPath(for: uid, weakTopics: weakTopics))
        } catch {
            state = .failed(AppError.from(error))
        }
    }

    /// Accepts the path (H05's "Add all to plan").
    ///
    /// Writing the steps into F06's `studyPlans` sessions is a follow-up: it needs `StudyPlanStore`
    /// to gain a bulk-insert that keeps the wizard's availability constraints, and inventing one
    /// here would produce a plan the planner screen then cannot reconcile. Until then this records
    /// the acceptance and says so, rather than silently doing nothing.
    func addAllToPlan() async {
        guard !steps.isEmpty else { return }
        addedToPlan = true
    }
}
