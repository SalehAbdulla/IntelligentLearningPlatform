//
//  ProfileSetupAcademicTests.swift
//  StudyForgeTests
//
//  Tests for B01, the profile wizard's academic step.
//
//  What is load-bearing here, and why it is tested rather than assumed:
//   · the write contains EXACTLY the four allowlisted fields — the server rejects the
//     whole update otherwise, and a silent field would break saving outright
//   · course ids are stored in catalogue order, so the same selection always produces the
//     same document and the write is idempotent
//   · a rejected write keeps what the student typed, because losing a filled-in form is
//     its own defect
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Profile setup — academic (B01)")
@MainActor
struct ProfileSetupAcademicTests {

    /// A two-course catalogue, so a test can reason about the whole list rather than a
    /// slice of the placeholder one.
    private static let catalogue = AcademicCatalogue(
        universities: ["Bahrain Polytechnic", "University of Bahrain"],
        years: [1, 2, 3, 4],
        courses: [
            CourseOption(id: "c_101", name: "Introduction to Programming"),
            CourseOption(id: "c_104", name: "Data Structures"),
        ]
    )

    private func model(
        profile: MockProfileService = MockProfileService(latency: .zero),
        catalogue: AcademicCatalogue = ProfileSetupAcademicTests.catalogue,
        onSaved: @escaping (AcademicProfile) -> Void = { _ in }
    ) -> ProfileSetupAcademicViewModel {
        ProfileSetupAcademicViewModel(
            profile: profile,
            catalogue: catalogue,
            onSaved: onSaved
        )
    }

    /// Fills every field, so a test can start from a complete form. Uses the catalogue
    /// above, so callers must not inject a different one.
    private func completed(_ viewModel: ProfileSetupAcademicViewModel) {
        viewModel.university = "Bahrain Polytechnic"
        viewModel.major = "Software Engineering"
        viewModel.year = 3
        viewModel.toggle(Self.catalogue.courses[0])
    }

    @Test("An untouched form is empty, enabled, and on step 1 of 3")
    func initialState() {
        let viewModel = model()

        #expect(viewModel.stepLabel == L10n.profileStep.string(1, 3))
        #expect(viewModel.university == nil)
        #expect(viewModel.year == nil)
        #expect(viewModel.selectedCourses.isEmpty)
        #expect(viewModel.error == nil)
        #expect(viewModel.isSubmitEnabled)
    }

    // MARK: Validation

    @Test("An empty form reports all four problems at once, and writes nothing")
    func reportsEveryProblemAtOnce() async {
        let profile = MockProfileService(latency: .zero)
        let viewModel = model(profile: profile)

        await viewModel.submit()

        // All four, not the first one found: a form that reports a single problem per tap
        // makes the student discover it by iteration.
        #expect(viewModel.universityError == L10n.profileAcademicErrorUniversity.string)
        #expect(viewModel.majorError == L10n.profileAcademicErrorMajor.string)
        #expect(viewModel.yearError == L10n.profileAcademicErrorYear.string)
        #expect(viewModel.coursesError == L10n.profileAcademicErrorCourses.string)
        #expect(profile.savedCount == 0)
    }

    @Test("A whitespace-only major is rejected, not saved as blank")
    func whitespaceMajorIsRejected() async {
        let profile = MockProfileService(latency: .zero)
        let viewModel = model(profile: profile)
        completed(viewModel)
        viewModel.major = "   "

        await viewModel.submit()

        #expect(viewModel.majorError == L10n.profileAcademicErrorMajor.string)
        #expect(profile.savedCount == 0)
    }

    // MARK: The write

    @Test("A complete form writes exactly the academic fields, with the major trimmed")
    func writesTheAcademicFields() async {
        let profile = MockProfileService(latency: .zero)
        let viewModel = model(profile: profile)
        completed(viewModel)
        viewModel.major = "  Software Engineering  "

        await viewModel.submit()

        // Compared as a whole value: `AcademicProfile` holds nothing else, which is the
        // app-side half of the allowlist guarantee. The rules tests assert the server-side
        // half (backend/rules-tests/firestore.rules.test.mjs).
        #expect(
            profile.lastSavedProfile == AcademicProfile(
                university: "Bahrain Polytechnic",
                major: "Software Engineering",
                year: 3,
                courseIds: ["c_101"]
            )
        )
        #expect(viewModel.error == nil)
    }

    @Test("Course ids are stored in catalogue order, not the order they were tapped")
    func courseIdsFollowCatalogueOrder() async {
        let profile = MockProfileService(latency: .zero)
        let viewModel = model(profile: profile)

        // Everything except the courses, so the two toggles below start from an empty
        // selection — `completed()` would already have `c_101` selected, and tapping it
        // again would REMOVE it.
        viewModel.university = "Bahrain Polytechnic"
        viewModel.major = "Software Engineering"
        viewModel.year = 3

        // Tapped newest-first: a selection-order implementation would store
        // ["c_104", "c_101"], producing a different document for the same two courses.
        viewModel.toggle(Self.catalogue.courses[1])
        viewModel.toggle(Self.catalogue.courses[0])

        await viewModel.submit()

        #expect(profile.lastSavedProfile?.courseIds == ["c_101", "c_104"])
    }

    @Test("Tapping a selected course again removes it")
    func togglingTwiceRemovesTheCourse() {
        let viewModel = model()
        let course = Self.catalogue.courses[0]

        viewModel.toggle(course)
        #expect(viewModel.isSelected(course))

        viewModel.toggle(course)
        #expect(!viewModel.isSelected(course))
        #expect(viewModel.selectedCourses.isEmpty)
    }

    @Test("Editing a field clears only that field's error")
    func editingClearsOnlyItsOwnError() async {
        let viewModel = model()

        await viewModel.submit()
        #expect(viewModel.majorError != nil)
        #expect(viewModel.yearError != nil)

        viewModel.didEdit(.major)

        #expect(viewModel.majorError == nil)
        #expect(viewModel.yearError != nil, "an unrelated field is still wrong")
    }

    // MARK: Failure and continuation

    @Test("A rejected write is reported, and keeps what the student typed")
    func rejectedWriteKeepsTheForm() async {
        let profile = MockProfileService(latency: .zero)
        profile.forceFailure(.writeRejected(reference: "profile-write-denied"))
        let viewModel = model(profile: profile)
        completed(viewModel)

        await viewModel.submit()

        // `.server`, not `.notPermitted`: a rules denial here means the app asked for a
        // field the allowlist does not name, which is our defect and not the student's.
        #expect(viewModel.error == AppError.server(reference: "profile-write-denied"))
        #expect(viewModel.major == "Software Engineering", "the form must not be cleared")
        #expect(viewModel.university == "Bahrain Polytechnic")
    }

    @Test("Continue hands the saved profile to the caller, which owns navigation")
    func onSavedReceivesTheProfile() async {
        var received: [AcademicProfile] = []
        let viewModel = model(onSaved: { received.append($0) })
        completed(viewModel)

        await viewModel.submit()

        #expect(received.count == 1)
        #expect(received.first?.courseIds == ["c_101"])
        #expect(received.first?.year == 3)
    }

    @Test("A failed write does not call the caller's continuation")
    func failedWriteDoesNotAdvance() async {
        let profile = MockProfileService(latency: .zero)
        profile.forceFailure(.offline)
        var advanced = false
        let viewModel = model(profile: profile, onSaved: { _ in advanced = true })
        completed(viewModel)

        await viewModel.submit()

        #expect(advanced == false, "a student must not be moved on from a failed save")
    }

    @Test("Two taps in flight produce one write")
    func submitIsNotReentrant() async {
        let profile = MockProfileService(latency: .milliseconds(50))
        let viewModel = model(profile: profile)
        completed(viewModel)

        async let first: Void = viewModel.submit()
        async let second: Void = viewModel.submit()
        _ = await (first, second)

        #expect(profile.savedCount == 1, "the second tap must not write twice")
    }

    // MARK: Injected catalogue

    @Test("The pickers come from the injected catalogue, not a hard-coded list")
    func usesTheInjectedCatalogue() {
        let tiny = AcademicCatalogue(
            universities: ["Only University"],
            years: [7],
            courses: [CourseOption(id: "x_1", name: "Only Course")]
        )
        let viewModel = model(catalogue: tiny)

        #expect(viewModel.catalogue.universities == ["Only University"])
        #expect(viewModel.catalogue.years == [7])
        #expect(viewModel.catalogue.courses.map(\.id) == ["x_1"])
    }
}
