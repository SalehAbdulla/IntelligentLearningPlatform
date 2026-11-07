//
//  StudyPlanWizardValidationTests.swift
//  StudyForgeTests
//
//  F06 Task 01 — the wizard must reject a plan-level deadline in the past (docs/02 §6 lists
//  "deadline in the past" as an edge case the wizard has to handle; before this change the
//  deadline step's `canContinue` was unconditionally `true`).
//
//  WHY THE CLOCK IS INJECTED
//  -------------------------
//  The rule is "no earlier than the start of the current local day", so a test that read the
//  machine clock could only assert it by luck. `StudyPlanWizardViewModel` therefore takes its
//  `now`, and every date below is built from ONE pinned reference with the same `Calendar.current`
//  the view model uses — same inputs, same answers, on any machine and in any time zone.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Wizard deadline validation (F06)")
@MainActor
struct StudyPlanWizardValidationTests {

    /// A fixed instant — never `Date.now`.
    private let now = Date(timeIntervalSince1970: 1_773_000_000)

    private var calendar: Calendar { .current }

    /// The start of the pinned "today", in the local calendar: the rule's exact boundary.
    private var today: Date { calendar.startOfDay(for: now) }

    /// `offset` days from the pinned today; negative is the past.
    private func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: today) ?? today
    }

    /// A wizard pinned to the reference clock, plus its store, so persistence can be asserted.
    private func makeWizard() -> (StudyPlanWizardViewModel, InMemoryStudyPlanStore) {
        let store = InMemoryStudyPlanStore()
        let reference = now
        let viewModel = StudyPlanWizardViewModel(store: store, now: { reference })
        return (viewModel, store)
    }

    // MARK: The rule itself

    @Test("The deadline floor is the start of the pinned local day")
    func deadlineMinimumIsStartOfToday() {
        let (viewModel, _) = makeWizard()

        #expect(viewModel.deadlineMinimum == today)
    }

    @Test("A deadline from yesterday is rejected")
    func yesterdayIsRejected() {
        let (viewModel, _) = makeWizard()
        viewModel.hasDeadline = true
        viewModel.deadline = day(-1)
        viewModel.step = .deadline

        #expect(viewModel.deadlineIsValid == false)
        #expect(viewModel.canContinue == false, "Continue stays disabled until the date is legal")
    }

    @Test("A deadline of today is accepted")
    func todayIsAccepted() {
        let (viewModel, _) = makeWizard()
        viewModel.hasDeadline = true
        viewModel.deadline = today
        viewModel.step = .deadline

        #expect(viewModel.deadlineIsValid)
        #expect(viewModel.canContinue)
    }

    @Test("A future deadline is accepted")
    func futureIsAccepted() {
        let (viewModel, _) = makeWizard()
        viewModel.hasDeadline = true
        viewModel.deadline = day(7)
        viewModel.step = .deadline

        #expect(viewModel.deadlineIsValid)
        #expect(viewModel.canContinue)
    }

    @Test("With the deadline switched off, a stale date in the picker blocks nothing")
    func disabledDeadlineNeverBlocks() {
        let (viewModel, _) = makeWizard()
        viewModel.hasDeadline = false
        viewModel.deadline = day(-30)
        viewModel.step = .deadline

        #expect(viewModel.deadlineIsValid)
        #expect(viewModel.canContinue)
    }

    // MARK: The store is the backstop

    @Test("An invalid deadline cannot generate or persist a plan")
    func invalidDeadlineCannotGenerate() async throws {
        let (viewModel, store) = makeWizard()
        viewModel.subjectText = "Maths"
        viewModel.addSubject()
        viewModel.hasDeadline = true
        viewModel.deadline = day(-1)

        await viewModel.generate()

        #expect(viewModel.savedPlan == nil, "generate() must refuse a past deadline")
        let stored = try await store.all()
        #expect(stored.isEmpty, "nothing may reach the store")
    }

    @Test("A valid deadline still generates and persists the plan")
    func validDeadlineStillGenerates() async throws {
        let (viewModel, store) = makeWizard()
        viewModel.subjectText = "Maths"
        viewModel.addSubject()
        viewModel.hasDeadline = true
        viewModel.deadline = day(3)

        await viewModel.generate()

        #expect(viewModel.savedPlan != nil)
        #expect(viewModel.savedPlan?.input.deadline == day(3))
        let stored = try await store.all()
        #expect(stored.count == 1)
    }
}