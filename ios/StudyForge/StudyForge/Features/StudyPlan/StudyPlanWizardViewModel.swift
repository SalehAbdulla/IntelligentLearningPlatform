//
//  StudyPlanWizardViewModel.swift
//  StudyForge
//
//  Presentation logic for F06's wizard — subjects, availability, deadline, intensity — collecting
//  the input the scheduler turns into a week of sessions.
//
//  WHY THE INPUT IS A VALUE TYPE
//  -----------------------------
//  `StudyPlanInput` is the reusable "recipe" the re-plan re-runs. Keeping it a plain struct means a
//  re-plan is `schedule(input, now:)` again — no hidden state to reconstruct.
//

import Foundation

@MainActor
@Observable
final class StudyPlanWizardViewModel {

    enum Step: Int, CaseIterable {
        case subjects = 0
        case availability
        case deadline
        case intensity
    }

    var step: Step = .subjects

    // Step 1 — subjects
    var subjectText = ""
    var subjects: [String] = []

    // Step 2 — availability
    var weeklyHours: Int? = 8

    // Step 3 — deadline
    var hasDeadline = false
    var deadline: Date = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now

    // Step 4 — intensity
    var intensity: StudyIntensity? = .balanced

    private(set) var isSaving = false
    private(set) var error: AppError?
    private(set) var savedPlan: StudyPlan?

    private let store: any StudyPlanStore

    init(store: any StudyPlanStore) {
        self.store = store
    }

    // MARK: Copy

    var title: String { L10n.planTitle.string }
    var commonBackTitle: String { L10n.commonBack.string }
    var commonNextTitle: String { L10n.commonNext.string }
    var stepIndicator: String { L10n.planStepIndicator.string(step.rawValue + 1, Step.allCases.count) }
    var subjectsHeading: String { L10n.planSubjectsHeading.string }
    var subjectPlaceholder: String { L10n.planSubjectPlaceholder.string }
    var addSubjectTitle: String { L10n.planAddSubject.string }
    var availabilityHeading: String { L10n.planAvailabilityHeading.string }
    var deadlineHeading: String { L10n.planDeadlineHeading.string }
    var noDeadlineTitle: String { L10n.planNoDeadline.string }
    var intensityHeading: String { L10n.planIntensityHeading.string }
    var generateTitle: String { L10n.planGenerate.string }

    func intensityTitle(_ intensity: StudyIntensity) -> String {
        switch intensity {
        case .light: L10n.planIntensityLight.string
        case .balanced: L10n.planIntensityBalanced.string
        case .intensive: L10n.planIntensityIntensive.string
        }
    }

    var isLastStep: Bool { step == .intensity }

    var canContinue: Bool {
        switch step {
        case .subjects: !subjects.isEmpty
        case .availability: weeklyHours != nil
        case .deadline: true
        case .intensity: intensity != nil
        }
    }

    // MARK: Actions

    func addSubject() {
        let name = subjectText.trimmingCharacters(in: .whitespacesAndNewlines)
        // Clear the field whatever happens: a blank entry is a no-op, not a reason to leave the
        // stray spaces sitting in the field.
        subjectText = ""
        guard !name.isEmpty else { return }
        if !subjects.contains(name) { subjects.append(name) }
    }

    func removeSubject(_ subject: String) {
        subjects.removeAll { $0 == subject }
    }

    func next() {
        guard let next = Step(rawValue: step.rawValue + 1) else { return }
        step = next
    }

    func back() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        step = previous
    }

    func generate() async {
        guard !isSaving, let weeklyHours, let intensity, !subjects.isEmpty else { return }
        isSaving = true
        defer { isSaving = false }

        let input = StudyPlanInput(
            subjects: subjects,
            weeklyHours: weeklyHours,
            deadline: hasDeadline ? deadline : nil,
            intensity: intensity
        )
        let plan = StudyPlan(input: input, sessions: StudyPlanner.schedule(input, now: .now))

        do {
            try await store.add(plan)
            savedPlan = plan
        } catch {
            self.error = AppError.from(error)
        }
    }
}
