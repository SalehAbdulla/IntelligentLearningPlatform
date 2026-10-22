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

    /// Per-course exam dates, keyed by subject.
    ///
    /// A dictionary rather than the plan's `[CourseExam]` because this step edits one row at a
    /// time and already has the subject to hand, and the subjects step de-duplicates, so a
    /// subject is a sound key. `generate()` turns it into the array the plan stores, in subject
    /// order, so the plan is written in the order the student saw the rows.
    var examDates: [String: Date] = [:]

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
        // Take the exam date with the subject. Keeping it would leave the wizard holding a date
        // for a course the student has just removed — a stale date by exactly the argument in
        // docs/09 Q11, which is the whole reason exam dates live on the plan instead of the profile.
        examDates[subject] = nil
    }

    /// Switches one subject's exam date on or off.
    ///
    /// Enabling seeds a date rather than leaving an empty entry, because `DatePicker` always holds
    /// a value: an empty slot would render the row as switched on with nothing visible to change.
    /// A week out is the plan-level deadline's own default, so the two controls on this step do not
    /// open disagreeing with each other.
    func setExamDate(enabled: Bool, for subject: String) {
        if enabled {
            examDates[subject] = examDates[subject]
                ?? (Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now)
        } else {
            examDates[subject] = nil
        }
    }

    /// Moves one subject's exam date. Called by that row's own picker.
    func setExamDate(_ date: Date, for subject: String) {
        examDates[subject] = date
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

        // In the order the student sees the subjects, so the plan is written the way the wizard
        // listed it. A subject whose row was never switched on contributes nothing.
        let courseExams: [CourseExam] = subjects.compactMap { subject in
            examDates[subject].map { CourseExam(subject: subject, date: $0) }
        }

        let input = StudyPlanInput(
            subjects: subjects,
            weeklyHours: weeklyHours,
            deadline: hasDeadline ? deadline : nil,
            examDates: courseExams,
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
