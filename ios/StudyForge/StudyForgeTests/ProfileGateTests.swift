//
//  ProfileGateTests.swift
//  StudyForgeTests
//
//  The gate that decides whether a signed-in student sees the profile wizard or their home
//  screen. The load-bearing property is that the answer comes from the DOCUMENT — the mock is
//  read-after-write, so `theReadSeesTheWizard` proves the gate follows what the wizard saved
//  rather than a flag the app set about itself.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Profile gate")
@MainActor
struct ProfileGateTests {

    private func container(profile: MockProfileService) -> AppContainer {
        AppContainer(
            environment: .dev,
            firebaseSource: .localEmulator,
            auth: MockAuthService(initialState: .signedOut, latency: .zero),
            profile: profile,
            onboarding: InMemoryOnboardingStore()
        )
    }

    @Test("A fresh container has not asked yet — which is not the same as 'no profile'")
    func startsUnknown() {
        let container = container(profile: MockProfileService(latency: .zero))

        #expect(container.profileStatus == .unknown)
        #expect(container.profileStatus.isResolved == false)
    }

    @Test("An account with no document resolves to incomplete, so the wizard runs")
    func noDocumentIsIncomplete() async {
        let container = container(profile: MockProfileService(latency: .zero))

        await container.resolveProfile()

        #expect(container.profileStatus == .incomplete)
    }

    @Test("A complete profile resolves to complete, so the home screen runs")
    func completeProfileResolves() async {
        let profile = MockProfileService(latency: .zero)
        profile.seed(.preview)
        let container = container(profile: profile)

        await container.resolveProfile()

        #expect(container.profileStatus == .complete)
    }

    @Test("The gate follows what the wizard SAVED, not a flag the app set")
    func theReadSeesTheWizard() async {
        let profile = MockProfileService(latency: .zero)
        let container = container(profile: profile)

        await container.resolveProfile()
        #expect(container.profileStatus == .incomplete)

        // One step is not a profile.
        try? await profile.saveAcademicProfile(
            AcademicProfile(
                university: "Bahrain Polytechnic",
                major: "Programming",
                year: 2,
                courseIds: ["IT8108"]
            )
        )
        await container.resolveProfile()
        #expect(container.profileStatus == .incomplete)

        // The remaining two steps complete it.
        try? await profile.saveLearningStyle(.visual)
        try? await profile.saveStudyGoals(StudyGoals(weeklyStudyGoalHours: 12, targetGrade: .a))

        await container.resolveProfile()
        #expect(container.profileStatus == .complete)
    }

    @Test("A failed read resolves to failed, and does not strand the student")
    func failureResolvesToFailed() async {
        let profile = MockProfileService(latency: .zero)
        profile.forceFailure(.offline)
        let container = container(profile: profile)

        await container.resolveProfile()

        #expect(container.profileStatus == .failed)
        // `.failed` counts as resolved, so `RootView` shows the home screen rather than
        // waiting forever behind a read that cannot succeed.
        #expect(container.profileStatus.isResolved)
    }

    @Test("Only an answer — not 'unknown' or 'loading' — counts as resolved")
    func isResolvedCoversEveryOutcome() {
        #expect(ProfileStatus.unknown.isResolved == false)
        #expect(ProfileStatus.loading.isResolved == false)
        #expect(ProfileStatus.incomplete.isResolved)
        #expect(ProfileStatus.complete.isResolved)
        #expect(ProfileStatus.failed.isResolved)
    }

    @Test("The container keeps the document it read, so the wizard can resume")
    func keepsTheDocumentItRead() async {
        let profile = MockProfileService(latency: .zero)
        profile.seed(.preview)
        let container = container(profile: profile)

        await container.resolveProfile()

        #expect(container.storedProfile == StoredProfile.preview)
    }

    @Test("A failed read clears the kept document, so a stale one is never resumed from")
    func failureClearsTheKeptDocument() async {
        let profile = MockProfileService(latency: .zero)
        profile.seed(.preview)
        let container = container(profile: profile)

        await container.resolveProfile()
        #expect(container.storedProfile != nil)

        profile.forceFailure(.offline)
        await container.resolveProfile()

        #expect(container.storedProfile == nil)
    }
}
