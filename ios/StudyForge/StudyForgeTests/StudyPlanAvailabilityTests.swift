//
//  StudyPlanAvailabilityTests.swift
//  StudyForgeTests
//
//  F06 Task 02 (G02, part one) — blocked study days: the wizard collects the weekdays a
//  student cannot study and the deterministic planner never schedules onto them.
//
//  PINNED CLOCK, CALENDAR-CORRECT DATES
//  Weekday numbers come from `Calendar.current`, so every date below is built from ONE fixed
//  instant and read back through the same calendar the planner uses — the same inputs, the
//  same answers, on any machine, in any time zone, at any hour.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Blocked study days (F06)")
@MainActor
struct StudyPlanAvailabilityTests {

    /// A fixed instant — never `Date.now`.
    private let now = Date(timeIntervalSince1970: 1_773_000_000)

    private var calendar: Calendar { .current }
    private var baseDay: Date { calendar.startOfDay(for: now) }

    private func weekday(of date: Date) -> Int {
        calendar.component(.weekday, from: date)
    }

    /// `offset` calendar days from the pinned today.
    private func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: baseDay) ?? baseDay
    }

    /// A two-subject plan: 8 h of 30-minute sessions = 16, so `occurrence` runs 0...7 —
    /// the sizes the planner's round-robin is exercised at everywhere else too.
    private func input(
        blockedDays: [Int] = [],
        examDates: [CourseExam] = [],
        weeklyHours: Int = 8
    ) -> StudyPlanInput {
        StudyPlanInput(
            subjects: ["Maths", "Physics"],
            weeklyHours: weeklyHours,
            examDates: examDates,
            intensity: .light,
            blockedDays: blockedDays
        )
    }

    private func makeWizard() -> (StudyPlanWizardViewModel, InMemoryStudyPlanStore) {
        let store = InMemoryStudyPlanStore()
        return (StudyPlanWizardViewModel(store: store), store)
    }

    // MARK: The model survives its own absence

    @Test("A plan written before blocked days existed still decodes")
    func legacyPlanWithoutBlockedDaysStillDecodes() throws {
        // Exactly the shape this app wrote before G02: no `blockedDays` key anywhere.
        let legacy = """
        {
          "id" : "p1",
          "input" : {
            "subjects" : ["Maths"],
            "weeklyHours" : 8,
            "deadline" : 4000000000,
            "intensity" : "balanced"
          },
          "sessions" : [],
          "createdAt" : 1000000,
          "updatedAt" : 1000000
        }
        """

        let decoded = try JSONDecoder().decode(StudyPlan.self, from: Data(legacy.utf8))

        #expect(decoded.input.blockedDays.isEmpty, "a missing key means 'no days blocked'")
    }

    // MARK: The untouched path stays untouched

    @Test("With no blocked days the schedule is exactly the round-robin it always was")
    func noBlockedDaysKeepsLegacySchedule() {
        // The planner derives its own span from the same raw 7·86400 window; mirroring that
        // arithmetic here keeps the expectation calendar-correct even across a DST change.
        let span = max(
            1,
            calendar.dateComponents([.day], from: now, to: now.addingTimeInterval(7 * 86_400)).day ?? 7
        )
        let sessions = StudyPlanner.schedule(input(), now: now)

        #expect(sessions.count == 16, "8 h ÷ 30 min, both subjects, nothing skipped")
        for (index, session) in sessions.enumerated() {
            let occurrence = index / 2                       // two subjects, cycled
            let expectedDay = day(occurrence % span)         // round-robin over the horizon
            let expected = calendar.date(
                bySettingHour: 17,
                minute: (occurrence / span) * 30,            // 17:00, second lap at 17:30
                second: 0,
                of: expectedDay
            )
            #expect(session.scheduledAt == expected, "session \(index) must match the old maths")
        }
    }

    // MARK: The restriction itself

    @Test("No session ever lands on a blocked weekday")
    func blockedWeekdayReceivesNoSessions() {
        let blocked = weekday(of: day(0)) // block "today"
        let sessions = StudyPlanner.schedule(input(blockedDays: [blocked]), now: now)

        #expect(sessions.count == 16, "the same work redistributes onto the days that remain")
        for session in sessions {
            #expect(weekday(of: session.scheduledAt) != blocked)
        }
    }

    @Test("An exam horizon and a blocked day combine without either being bypassed")
    func blockedDaysRespectExamHorizons() {
        let exam = day(2)                 // Maths sits its exam two days out
        let blocked = weekday(of: day(1)) // and the middle day is off-limits
        let sessions = StudyPlanner.schedule(
            input(
                blockedDays: [blocked],
                examDates: [CourseExam(subject: "Maths", date: exam)]
            ),
            now: now
        )

        #expect(sessions.count == 4, "2 h ÷ 30 min, two subjects — nothing skipped")

        let maths = sessions.filter { $0.subject == "Maths" }
        #expect(!maths.isEmpty)
        for session in maths {
            #expect(weekday(of: session.scheduledAt) != blocked, "never on the blocked day")
            #expect(
                calendar.startOfDay(for: session.scheduledAt) < calendar.startOfDay(for: exam),
                "never on or after the exam day"
            )
        }
        for session in sessions where session.subject == "Physics" {
            #expect(weekday(of: session.scheduledAt) != blocked)
        }
    }

    @Test("All seven weekdays blocked produces no sessions at all")
    func allDaysBlockedProducesEmptySchedule() {
        let sessions = StudyPlanner.schedule(input(blockedDays: Array(1...7)), now: now)
        #expect(sessions.isEmpty)
    }

    @Test("Sessions stack onto the single free day instead of spilling past midnight")
    func scarceDaysStackInsteadOfSpilling() {
        // Six of seven days blocked: 16 sessions must share the one day left. Deep slot
        // stacking would run 17:00 past midnight onto the NEXT day — which is blocked here —
        // so every session has to stay on the single legal day.
        let blocked = [2, 3, 4, 5, 6, 7]
        let free = (1...7).first { !blocked.contains($0) } ?? 1
        let sessions = StudyPlanner.schedule(input(blockedDays: blocked), now: now)

        #expect(sessions.count == 16, "the same work still fits, on one day")
        for session in sessions {
            #expect(weekday(of: session.scheduledAt) == free, "never past midnight, never blocked")
        }
    }

    // MARK: The wizard refuses an impossible week

    @Test("Continue is disabled once every weekday is blocked")
    func continueDisabledWhenAllDaysBlocked() {
        let (viewModel, _) = makeWizard()
        viewModel.step = .availability
        viewModel.weeklyHours = 8

        #expect(viewModel.canContinue, "nothing blocked is the default, and it is valid")

        for weekday in 1...7 { viewModel.toggleBlockedDay(weekday) }

        #expect(viewModel.availabilityIsValid == false)
        #expect(viewModel.canContinue == false, "Continue stays disabled until a day is free")
    }

    @Test("generate() cannot persist a plan when every weekday is blocked")
    func generateRefusesAllDaysBlocked() async throws {
        let (viewModel, store) = makeWizard()
        viewModel.subjectText = "Maths"
        viewModel.addSubject()
        for weekday in 1...7 { viewModel.toggleBlockedDay(weekday) }

        await viewModel.generate()

        #expect(viewModel.savedPlan == nil, "generate() must refuse an impossible week")
        let stored = try await store.all()
        #expect(stored.isEmpty, "nothing may reach the store")
    }

    // MARK: The toggle and the round trip

    @Test("Toggling blocks and unblocks a day, keeping the list sorted, unique and in range")
    func toggleBlocksAndUnblocks() {
        let (viewModel, _) = makeWizard()

        viewModel.toggleBlockedDay(6)
        viewModel.toggleBlockedDay(2)
        #expect(viewModel.blockedDays == [2, 6], "sorted regardless of tap order")

        viewModel.toggleBlockedDay(6)
        #expect(viewModel.blockedDays == [2])

        viewModel.toggleBlockedDay(2)
        #expect(viewModel.blockedDays.isEmpty)
        #expect(viewModel.availabilityIsValid, "an empty list is the valid default")

        // Out-of-range values are ignored rather than corrupting the list.
        viewModel.toggleBlockedDay(0)
        viewModel.toggleBlockedDay(8)
        #expect(viewModel.blockedDays.isEmpty)
    }

    @Test("A valid generate() persists the blocked days on the plan's input")
    func generatePersistsBlockedDays() async throws {
        let (viewModel, store) = makeWizard()
        viewModel.subjectText = "Maths"
        viewModel.addSubject()
        viewModel.toggleBlockedDay(6)
        viewModel.toggleBlockedDay(2)

        await viewModel.generate()

        #expect(viewModel.savedPlan != nil)
        #expect(viewModel.savedPlan?.input.blockedDays == [2, 6])
        let stored = try await store.all()
        #expect(stored.count == 1)
        #expect(stored.first?.input.blockedDays == [2, 6], "what the wizard shows is what disk holds")
    }
}