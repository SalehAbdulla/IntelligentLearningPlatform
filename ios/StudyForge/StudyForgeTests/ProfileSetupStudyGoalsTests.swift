//
//  ProfileSetupStudyGoalsTests.swift
//  StudyForgeTests
//
//  Tests for B03, the wizard's last step.
//
//  Two of these are about decisions rather than mechanics. `hoursStartAtTheDocumentedValue`
//  pins the slider's starting position to the number docs/05 documents, and
//  `gradeScaleIsThePlaceholderOne` pins the grade scale so that answering docs/09 Q12 has to
//  be a deliberate edit rather than something nobody notices.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Profile setup — study goals (B03)")
@MainActor
struct ProfileSetupStudyGoalsTests {

    private func model(
        profile: MockProfileService = MockProfileService(latency: .zero),
        onSaved: @escaping (StudyGoals) -> Void = { _ in }
    ) -> ProfileSetupStudyGoalsViewModel {
        ProfileSetupStudyGoalsViewModel(profile: profile, onSaved: onSaved)
    }

    @Test("The step reports 3 of 3, with the documented hours and no grade yet")
    func initialState() {
        let viewModel = model()

        #expect(viewModel.stepLabel == L10n.profileStep.string(3, 3))
        #expect(viewModel.hours == ProfileSetupStudyGoalsViewModel.defaultHours)
        #expect(viewModel.hoursReadout == WeekHoursReadout.string(for: 12))
        // A grade is a choice, not a position, so it has no honest default — unlike the
        // slider, which cannot be empty and therefore shows a visible starting value.
        #expect(viewModel.grade == nil)
        #expect(viewModel.error == nil)
        #expect(viewModel.gradeError == nil)
        #expect(viewModel.isSubmitEnabled)
    }

    @Test("The starting hours are the number the schema documents, and inside the range")
    func hoursStartAtTheDocumentedValue() {
        // 12 is what docs/05 §3 uses for `weeklyStudyGoalHours`. Taking it from the
        // repository is the same discipline as the course catalogue: an invented default is
        // a number nobody chose, shown to every student.
        #expect(ProfileSetupStudyGoalsViewModel.defaultHours == 12)
        #expect(ProfileSetupStudyGoalsViewModel.hoursRange.contains(
            ProfileSetupStudyGoalsViewModel.defaultHours
        ), "the default is outside the slider, so the student cannot return to it")
    }

    @Test("Moving the slider moves the readout")
    func readoutFollowsTheSlider() {
        let viewModel = model()

        viewModel.hours = 1
        #expect(viewModel.hoursReadout == WeekHoursReadout.string(for: 1))

        viewModel.hours = 2
        #expect(viewModel.hoursReadout == WeekHoursReadout.string(for: 2))

        // The three low categories produce three different readouts, which is the whole
        // point of the plural helper reaching this screen.
        let readouts = [1, 2, 3].map { hours -> String in
            viewModel.hours = hours
            return viewModel.hoursReadout
        }
        #expect(Set(readouts).count == 3)
    }

    @Test("The grade options are the whole scale, highest first")
    func gradeOptionsCoverTheScale() {
        let viewModel = model()

        #expect(viewModel.gradeOptions == TargetGrade.allCases)
        #expect(viewModel.gradeOptions.first == .a)
        #expect(viewModel.title(for: .b) == "B")
    }

    @Test("Finish without a grade says what is missing, and writes nothing")
    func missingGradeIsReported() async {
        let profile = MockProfileService(latency: .zero)
        let viewModel = model(profile: profile)

        await viewModel.submit()

        #expect(viewModel.gradeError == L10n.profileStudyGoalsGradeError.string)
        #expect(profile.goalsSavedCount == 0)
    }

    @Test("Choosing a grade clears the missing-grade message")
    func choosingClearsTheError() async {
        let viewModel = model()

        await viewModel.submit()
        #expect(viewModel.gradeError != nil)

        viewModel.select(.b)

        #expect(viewModel.gradeError == nil)
        #expect(viewModel.isSelected(.b))
    }

    // MARK: The write

    @Test("The grade scale is the marked placeholder, not something that drifted in")
    func gradeScaleIsThePlaceholderOne() {
        // docs/09 Q12 asks the institution for its real bands. Until it answers, this asserts
        // what is stored, so that swapping the scale is a deliberate edit with a failing test
        // to guide it rather than a silent change to a wire format.
        #expect(TargetGrade.allCases.map(\.storageValue) == ["A", "B", "C", "D"])
        // Stored as the letter a transcript shows, not as the Swift case name.
        #expect(TargetGrade.a.rawValue != TargetGrade.a.storageValue)
    }

    @Test("Ambition is an ordering, independent of the labels")
    func ambitionIsOrderedAndDistinct() {
        // F06's planner will compare these rather than the letters, so that a change of
        // scale (Q12) cannot change how hard the app pushes a student.
        #expect(TargetGrade.a.ambition > TargetGrade.b.ambition)
        #expect(TargetGrade.b.ambition > TargetGrade.c.ambition)
        #expect(TargetGrade.c.ambition > TargetGrade.d.ambition)
        #expect(Set(TargetGrade.allCases.map(\.ambition)).count == TargetGrade.allCases.count)
    }

    @Test("Finish writes both goals in one update, and nothing else")
    func writesBothGoalsInOneUpdate() async {
        let profile = MockProfileService(latency: .zero)
        let viewModel = model(profile: profile)
        viewModel.hours = 8
        viewModel.select(.a)

        await viewModel.submit()

        #expect(profile.lastSavedGoals == StudyGoals(weeklyStudyGoalHours: 8, targetGrade: .a))
        #expect(profile.goalsSavedCount == 1)
        #expect(viewModel.error == nil)
        // The three steps each answer their own question. Later steps must not re-send
        // earlier answers, and the rules would accept them if they did — all of these fields
        // are allowlisted — so only assertions like these would notice.
        #expect(profile.lastSavedProfile == nil)
        #expect(profile.lastSavedStyle == nil)
    }

    @Test("Finish hands the saved goals to the caller, which owns what happens next")
    func onSavedReceivesTheGoals() async {
        var received: [StudyGoals] = []
        let viewModel = model(onSaved: { received.append($0) })
        viewModel.hours = 1
        viewModel.select(.d)

        await viewModel.submit()

        #expect(received == [StudyGoals(weeklyStudyGoalHours: 1, targetGrade: .d)])
    }

    @Test("Both ends of the slider are writable")
    func extremesAreCarried() async {
        let profile = MockProfileService(latency: .zero)
        let viewModel = model(profile: profile)
        viewModel.select(.c)

        viewModel.hours = ProfileSetupStudyGoalsViewModel.hoursRange.lowerBound
        await viewModel.submit()
        #expect(profile.lastSavedGoals?.weeklyStudyGoalHours == 1)

        viewModel.hours = ProfileSetupStudyGoalsViewModel.hoursRange.upperBound
        await viewModel.submit()
        #expect(profile.lastSavedGoals?.weeklyStudyGoalHours == 40)
        #expect(profile.goalsSavedCount == 2)
    }

    // MARK: Failure

    @Test("A rejected write is reported, and keeps both answers")
    func rejectedWriteKeepsBothAnswers() async {
        let profile = MockProfileService(latency: .zero)
        profile.forceFailure(.writeRejected(reference: "profile-write-denied"))
        let viewModel = model(profile: profile)
        viewModel.hours = 6
        viewModel.select(.b)

        await viewModel.submit()

        #expect(viewModel.error == AppError.server(reference: "profile-write-denied"))
        #expect(viewModel.hours == 6, "the hours must not reset to the default")
        #expect(viewModel.grade == .b, "nor the grade be cleared")
    }

    @Test("A failed write does not finish the wizard")
    func failedWriteDoesNotFinish() async {
        let profile = MockProfileService(latency: .zero)
        profile.forceFailure(.offline)
        var finished = false
        let viewModel = model(profile: profile, onSaved: { _ in finished = true })
        viewModel.select(.a)

        await viewModel.submit()

        #expect(finished == false)
    }

    @Test("Two taps in flight produce one write")
    func submitIsNotReentrant() async {
        let profile = MockProfileService(latency: .milliseconds(50))
        let viewModel = model(profile: profile)
        viewModel.select(.a)

        async let first: Void = viewModel.submit()
        async let second: Void = viewModel.submit()
        _ = await (first, second)

        #expect(profile.goalsSavedCount == 1)
    }
}
