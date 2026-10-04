//
//  ProfileSetupLearningStyleTests.swift
//  StudyForgeTests
//
//  Tests for B02, the wizard's learning-style step.
//
//  The load-bearing one is `storageValuesMatchTheDocumentedVocabulary`. `LearningStyle`'s
//  Swift case is `readWrite`, docs/05 §3 documents the stored value as `readwrite`, and
//  deriving the wire format from the case name would have written the wrong one — silently,
//  because nothing type-checks the contents of a string.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Profile setup — learning style (B02)")
@MainActor
struct ProfileSetupLearningStyleTests {

    private func model(
        profile: MockProfileService = MockProfileService(latency: .zero),
        onSaved: @escaping (LearningStyle) -> Void = { _ in }
    ) -> ProfileSetupLearningStyleViewModel {
        ProfileSetupLearningStyleViewModel(profile: profile, onSaved: onSaved)
    }

    @Test("Nothing is preselected, and the step reports 2 of 3")
    func initialState() {
        let viewModel = model()

        #expect(viewModel.stepLabel == L10n.profileStep.string(2, 3))
        #expect(viewModel.selection == nil)
        #expect(viewModel.error == nil)
        #expect(viewModel.selectionError == nil)
        #expect(viewModel.isSubmitEnabled)
    }

    @Test("There is one card per style, in design order, each with a preview")
    func everyStyleHasAnExplainingCard() {
        let viewModel = model()

        #expect(viewModel.options.map(\.style) == LearningStyle.allCases)
        // docs/03 §B requires a sample output preview on each card, because a bare label
        // like "kinesthetic" does not tell a student what they are choosing between.
        for option in viewModel.options {
            #expect(!option.title.isEmpty, "\(option.style) has no title")
            #expect(!option.preview.isEmpty, "\(option.style) has no sample preview")
        }
    }

    @Test("Continue without a choice says what is missing, and writes nothing")
    func missingSelectionIsReported() async {
        let profile = MockProfileService(latency: .zero)
        let viewModel = model(profile: profile)

        await viewModel.submit()

        #expect(viewModel.selectionError == L10n.profileLearningStyleError.string)
        #expect(profile.styleSavedCount == 0)
    }

    @Test("Choosing clears the missing-selection message")
    func choosingClearsTheError() async {
        let viewModel = model()

        await viewModel.submit()
        #expect(viewModel.selectionError != nil)

        viewModel.select(.verbal)

        #expect(viewModel.selectionError == nil)
        #expect(viewModel.isSelected(.verbal))
    }

    @Test("Re-tapping the selected card keeps it selected (radio, not toggle)")
    func reselectingDoesNotClearTheChoice() {
        let viewModel = model()

        viewModel.select(.visual)
        viewModel.select(.visual)

        // A nil selection would look to the student like the app forgot their answer.
        #expect(viewModel.selection == .visual)
    }

    @Test("Choosing a different card replaces the previous choice")
    func selectionIsSingle() {
        let viewModel = model()

        viewModel.select(.visual)
        viewModel.select(.kinesthetic)

        #expect(viewModel.selection == .kinesthetic)
        #expect(!viewModel.isSelected(.visual))
    }

    // MARK: The write

    @Test("The stored value is the documented one, not the Swift case name")
    func storageValuesMatchTheDocumentedVocabulary() {
        // docs/05 §3: visual | verbal | readwrite | kinesthetic.
        #expect(LearningStyle.allCases.map(\.storageValue) == [
            "visual", "verbal", "readwrite", "kinesthetic",
        ])
        // The one that would have gone wrong: the Swift case is `readWrite`.
        #expect(LearningStyle.readWrite.rawValue != LearningStyle.readWrite.storageValue)
    }

    @Test("Continue writes the chosen style and nothing else")
    func writesOnlyTheStyle() async {
        let profile = MockProfileService(latency: .zero)
        let viewModel = model(profile: profile)
        viewModel.select(.readWrite)

        await viewModel.submit()

        #expect(profile.lastSavedStyle == .readWrite)
        #expect(profile.styleSavedCount == 1)
        // B02 asks one question. A write that also re-sent the academic fields would pass
        // every other check — the rules accept all of them, since they are allowlisted —
        // so only this assertion would notice.
        #expect(profile.lastSavedProfile == nil)
        #expect(viewModel.error == nil)
    }

    // MARK: Failure and continuation

    @Test("A rejected write is reported, and keeps the student's choice")
    func rejectedWriteKeepsTheChoice() async {
        let profile = MockProfileService(latency: .zero)
        profile.forceFailure(.writeRejected(reference: "profile-write-denied"))
        let viewModel = model(profile: profile)
        viewModel.select(.visual)

        await viewModel.submit()

        #expect(viewModel.error == AppError.server(reference: "profile-write-denied"))
        #expect(viewModel.selection == .visual, "the answer must not be cleared")
    }

    @Test("Continue hands the saved style to the caller, which owns navigation")
    func onSavedReceivesTheStyle() async {
        var received: [LearningStyle] = []
        let viewModel = model(onSaved: { received.append($0) })
        viewModel.select(.verbal)

        await viewModel.submit()

        #expect(received == [.verbal])
    }

    @Test("A failed write does not advance the wizard")
    func failedWriteDoesNotAdvance() async {
        let profile = MockProfileService(latency: .zero)
        profile.forceFailure(.offline)
        var advanced = false
        let viewModel = model(profile: profile, onSaved: { _ in advanced = true })
        viewModel.select(.verbal)

        await viewModel.submit()

        #expect(advanced == false)
    }

    @Test("Two taps in flight produce one write")
    func submitIsNotReentrant() async {
        let profile = MockProfileService(latency: .milliseconds(50))
        let viewModel = model(profile: profile)
        viewModel.select(.visual)

        async let first: Void = viewModel.submit()
        async let second: Void = viewModel.submit()
        _ = await (first, second)

        #expect(profile.styleSavedCount == 1)
    }
}
