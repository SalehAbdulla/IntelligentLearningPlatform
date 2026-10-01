//
//  ProfileEditTests.swift
//  StudyForgeTests
//
//  Tests for B07, the profile editor.
//
//  The load-bearing ones are about what is WRITTEN and what is KEPT.
//  `savingOnlyTheNameDoesNotRewriteTheDocument` pins the "only what changed" rule — the failure
//  it prevents is a rename silently re-sending the academic fields, which the rules would
//  happily accept. `aStoredCourseTheCatalogueDoesNotKnowSurvives` pins the opposite: an edit
//  must not destroy a value the placeholder catalogue cannot see.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Profile edit (B07)")
@MainActor
struct ProfileEditTests {

    private let academic = AcademicProfile(
        university: "Bahrain Polytechnic",
        major: "Programming",
        year: 2,
        courseIds: ["IT8108", "c_104"]
    )

    private func signedInAuth(name: String = "Sara Ali") -> MockAuthService {
        MockAuthService(
            initialState: .signedIn(UserSession(
                id: "uid_test",
                displayName: name,
                role: .student,
                plan: .free,
                groupIds: [],
                email: "sara@studyforge.test",
                isEmailVerified: true
            )),
            latency: .zero
        )
    }

    private func model(
        name: String = "Sara Ali",
        academic: AcademicProfile?,
        auth: any AuthService = MockAuthService(latency: .zero),
        profile: any ProfileService = MockProfileService(latency: .zero)
    ) -> ProfileEditViewModel {
        ProfileEditViewModel(
            initialName: name,
            initialAcademic: academic,
            auth: auth,
            profile: profile
        )
    }

    // MARK: Opening

    @Test("The form opens on what is stored, with nothing to save")
    func opensOnTheStoredValues() {
        let viewModel = model(academic: academic)

        #expect(viewModel.name == "Sara Ali")
        #expect(viewModel.university == "Bahrain Polytechnic")
        #expect(viewModel.major == "Programming")
        #expect(viewModel.year == 2)
        #expect(viewModel.selectedCourseIds == ["IT8108", "c_104"])
        // A form that arrives pre-filled must NOT arrive dirty, or the discard warning fires
        // before the student has touched anything.
        #expect(viewModel.hasUnsavedChanges == false)
        #expect(viewModel.isSaveEnabled == false)
    }

    @Test("The monogram is the name's initials, and a placeholder when there is none")
    func initialsComeFromTheName() {
        #expect(model(name: "Sara Ali", academic: academic).initials == "SA")
        // One word gives one letter — the monogram is "up to two initials", not "always two".
        #expect(model(name: "Madonna", academic: academic).initials == "M")
        #expect(model(name: "sara ali", academic: academic).initials == "SA")
        #expect(model(name: "   ", academic: academic).initials == "?")
    }

    @Test("Editing anything marks the form changed and offers Save")
    func editingMarksTheFormChanged() {
        let viewModel = model(academic: academic)

        viewModel.name = "Sara A. Ali"

        #expect(viewModel.hasUnsavedChanges)
        #expect(viewModel.isSaveEnabled)
    }

    @Test("A change of whitespace alone is not a change")
    func whitespaceOnlyChangesAreNotChanges() {
        let viewModel = model(academic: academic)

        viewModel.name = "  Sara Ali  "
        viewModel.major = "  Programming  "

        #expect(viewModel.hasUnsavedChanges == false)
    }

    // MARK: Saving

    @Test("Saving only the name does not rewrite the academic document")
    func savingOnlyTheNameDoesNotRewriteTheDocument() async {
        let auth = signedInAuth()
        let profile = MockProfileService(latency: .zero)
        let viewModel = model(academic: academic, auth: auth, profile: profile)

        viewModel.name = "Sara A. Ali"
        await viewModel.save()

        #expect(auth.currentSession()?.displayName == "Sara A. Ali")
        #expect(viewModel.didSave)
        // The academic half did not change, so no write was issued for it. The failure this
        // prevents is a rename re-sending fields the rules would happily accept.
        #expect(profile.savedCount == 0)
    }

    @Test("Saving only the academic fields leaves the name alone")
    func savingOnlyTheAcademicFieldsLeavesTheNameAlone() async {
        let auth = signedInAuth()
        let profile = MockProfileService(latency: .zero)
        let viewModel = model(academic: academic, auth: auth, profile: profile)

        viewModel.major = "Cybersecurity"
        await viewModel.save()

        #expect(profile.lastSavedProfile?.major == "Cybersecurity")
        #expect(profile.savedCount == 1)
        #expect(auth.currentSession()?.displayName == "Sara Ali")
    }

    @Test("A stored course the catalogue does not know is offered, and survives the save")
    func aStoredCourseTheCatalogueDoesNotKnowSurvives() async {
        let profile = MockProfileService(latency: .zero)
        let viewModel = model(
            academic: AcademicProfile(
                university: "Bahrain Polytechnic",
                major: "Programming",
                year: 2,
                courseIds: ["IT8108", "c_999"]
            ),
            profile: profile
        )

        // Offered as a chip, by its id — a student cannot remove what they cannot see.
        #expect(viewModel.courseOptions.contains { $0.id == "c_999" })

        viewModel.year = 3
        await viewModel.save()

        #expect(profile.lastSavedProfile?.courseIds == ["IT8108", "c_999"])
        #expect(profile.lastSavedProfile?.year == 3)
    }

    @Test("A stored university the catalogue does not know is still offered")
    func aStoredUniversityTheCatalogueDoesNotKnowIsOffered() {
        let viewModel = model(
            academic: AcademicProfile(
                university: "Arabian Gulf University",
                major: "Medicine",
                year: 1,
                courseIds: ["IT8108"]
            )
        )

        // First, because it is what is currently set — a menu that omitted it would silently
        // replace it with whatever the student picked next.
        #expect(viewModel.universityOptions.first == "Arabian Gulf University")
    }

    // MARK: Refusals

    @Test("A blank name is reported, and nothing is written")
    func aBlankNameIsReportedAndNothingIsWritten() async {
        let profile = MockProfileService(latency: .zero)
        let viewModel = model(academic: academic, profile: profile)

        viewModel.name = "   "
        await viewModel.save()

        #expect(viewModel.nameError == L10n.profileEditNameError.string)
        #expect(profile.savedCount == 0)
        #expect(viewModel.didSave == false)
    }

    @Test("A rejected write is reported, and the edits are kept")
    func aRejectedWriteKeepsTheEdits() async {
        let profile = MockProfileService(latency: .zero)
        profile.forceFailure(.writeRejected(reference: "profile-write-denied"))
        let viewModel = model(academic: academic, profile: profile)

        viewModel.major = "Cybersecurity"
        await viewModel.save()

        #expect(viewModel.error == AppError.server(reference: "profile-write-denied"))
        #expect(viewModel.major == "Cybersecurity")
        #expect(viewModel.didSave == false)
    }

    @Test("Two taps in flight produce one write")
    func saveIsNotReentrant() async {
        let profile = MockProfileService(latency: .milliseconds(50))
        let viewModel = model(academic: academic, profile: profile)
        viewModel.major = "Cybersecurity"

        async let first: Void = viewModel.save()
        async let second: Void = viewModel.save()
        _ = await (first, second)

        #expect(profile.savedCount == 1)
    }
}
