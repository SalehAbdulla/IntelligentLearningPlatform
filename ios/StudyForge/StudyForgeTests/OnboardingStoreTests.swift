//
//  OnboardingStoreTests.swift
//  StudyForgeTests
//
//  Tests for the onboarding persistence seam and the pipeline step model.
//
//  The store is tested because it is the one piece of onboarding that survives a relaunch:
//  if `markCompleted` silently failed, the pager would reappear every launch and nothing
//  else in the suite would notice.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Onboarding store")
struct OnboardingStoreTests {

    @Test("An in-memory store starts in the state it was given")
    func initialState() {
        #expect(InMemoryOnboardingStore().hasCompletedOnboarding == false)
        #expect(InMemoryOnboardingStore(hasCompletedOnboarding: true).hasCompletedOnboarding)
    }

    @Test("Marking complete is idempotent, and reset clears it")
    func markingAndResetting() {
        let store = InMemoryOnboardingStore()

        store.markCompleted()
        store.markCompleted() // must not trap or toggle
        #expect(store.hasCompletedOnboarding)

        store.reset()
        #expect(store.hasCompletedOnboarding == false)
    }

    @Test("The UserDefaults store round-trips, in a suite of its own")
    func userDefaultsStoreRoundTrips() throws {
        // A dedicated suite rather than `.standard`, so this test cannot corrupt the
        // developer's real onboarding flag — or pass by reading the app's leftover state.
        let suiteName = "studyforge.tests.onboarding"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = UserDefaultsOnboardingStore(defaults: defaults, key: "flag")
        #expect(store.hasCompletedOnboarding == false)

        store.markCompleted()
        #expect(store.hasCompletedOnboarding)

        store.reset()
        #expect(store.hasCompletedOnboarding == false)
    }

    @Test("Two stores in different suites do not see each other's flag")
    func storesAreIsolated() throws {
        let suiteA = "studyforge.tests.onboarding.a"
        let suiteB = "studyforge.tests.onboarding.b"
        let defaultsA = try #require(UserDefaults(suiteName: suiteA))
        let defaultsB = try #require(UserDefaults(suiteName: suiteB))
        defer {
            defaultsA.removePersistentDomain(forName: suiteA)
            defaultsB.removePersistentDomain(forName: suiteB)
        }
        defaultsA.removePersistentDomain(forName: suiteA)
        defaultsB.removePersistentDomain(forName: suiteB)

        UserDefaultsOnboardingStore(defaults: defaultsA, key: "flag").markCompleted()

        // Writing to one suite must not leak into the other — otherwise "reset onboarding"
        // in a debug build could not be relied on.
        #expect(UserDefaultsOnboardingStore(defaults: defaultsA, key: "flag").hasCompletedOnboarding)
        #expect(UserDefaultsOnboardingStore(defaults: defaultsB, key: "flag").hasCompletedOnboarding == false)
    }
}

@Suite("Pipeline steps")
struct PipelineStepTests {

    @Test("There are four steps, numbered one to four, in pipeline order")
    func fourOrderedSteps() {
        // The ORDER is the meaning here — upload before generate before plan before
        // practise — so it is asserted rather than inferred from `allCases`.
        #expect(PipelineStep.all.count == 4)
        #expect(PipelineStep.all.map(\.number) == [1, 2, 3, 4])
        #expect(PipelineStep.all.map(\.stage) == [.upload, .generate, .plan, .practise])
    }

    @Test("Every step is fully populated")
    func everyStepIsComplete() {
        // A step with an empty body would render as a title with a blank line under it —
        // visible only if someone looked at that exact slide.
        for step in PipelineStep.all {
            #expect(!step.title.isEmpty)
            #expect(!step.body.isEmpty)
            #expect(!step.symbolName.isEmpty)
        }
    }
}
