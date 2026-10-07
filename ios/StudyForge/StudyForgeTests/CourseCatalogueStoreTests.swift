//
//  CourseCatalogueStoreTests.swift
//  StudyForgeTests
//
//  Tests for the seam that supplies the academic step's quick-picks.
//
//  What is load-bearing here, and why it is tested rather than assumed:
//   · a store that FAILS must leave the step answerable. The year control takes its options from
//     the catalogue and cannot be typed around, so an empty year range is a dead end rather than a
//     degraded screen. This is the assertion that stops F02's real source from locking a student
//     out of the wizard.
//   · a course id the catalogue does not carry is still shown, as itself. That is the ENROLLED
//     path: the only courses a student can truly name are the ones they type.
//   · `AppContainer` is the single place the source is chosen, so that is where it is checked.
//

import Foundation
import Testing
@testable import StudyForge

/// A store that always fails, so the fallback is exercised rather than only described.
private struct FailingCourseCatalogueStore: CourseCatalogueStore {
    func catalogue() async throws -> AcademicCatalogue {
        throw CatalogueUnavailable()
    }
}

private struct CatalogueUnavailable: Error {}

@Suite("Course catalogue store")
@MainActor
struct CourseCatalogueStoreTests {

    @Test("The seeded store serves the starter set the wizard ships with")
    func seededStoreServesStarter() async throws {
        let catalogue = try await SeededCourseCatalogueStore().catalogue()

        #expect(catalogue == SeededCourseCatalogueStore.starter)
        #expect(catalogue.universities.contains("Bahrain Polytechnic"))
        #expect(catalogue.courses.contains(CourseOption(id: "IT8108", name: "IT8108")))
        #expect(catalogue.years == [1, 2, 3, 4])
    }

    @Test("The empty catalogue keeps the year control answerable")
    func emptyKeepsTheYearRange() {
        // The one field a student cannot type around, which is why `years` survives when the
        // other two lists are deliberately dropped.
        #expect(AcademicCatalogue.empty.years == [1, 2, 3, 4])
        #expect(AcademicCatalogue.empty.universities.isEmpty)
        #expect(AcademicCatalogue.empty.courses.isEmpty)
    }

    @Test("A known course id resolves to its name, and an unknown one to itself")
    func courseNamesResolveElseFallBackToTheId() {
        let catalogue = SeededCourseCatalogueStore.starter

        // `MATH101` is the enrolled path: a real course the catalogue cannot know, typed by the
        // student. Showing the id is honest, and inventing a name for it would not be.
        #expect(catalogue.courseNames(for: ["c_104", "MATH101"]) == "Data Structures, MATH101")
    }

    @Test("The container takes its catalogue from the injected store")
    func containerUsesTheInjectedStore() async {
        let container = container(courseCatalogue: SeededCourseCatalogueStore())

        await container.loadCatalogue()

        #expect(container.catalogue == SeededCourseCatalogueStore.starter)
    }

    @Test("A failed store leaves the catalogue answerable rather than empty")
    func failureFallBackIsAnswerable() async {
        let container = container(courseCatalogue: FailingCourseCatalogueStore())

        await container.loadCatalogue()

        #expect(container.catalogue == .empty)
        #expect(
            !container.catalogue.years.isEmpty,
            "a failed load must not strand the year control, which has no free-text escape"
        )
    }

    /// Built the way `ProfileGateTests` does: a real container with mocks, so the wiring under
    /// test is the app's rather than a stand-in for it.
    private func container(courseCatalogue: any CourseCatalogueStore) -> AppContainer {
        AppContainer(
            environment: .dev,
            firebaseSource: .localEmulator,
            auth: MockAuthService(initialState: .signedOut, latency: .zero),
            profile: MockProfileService(latency: .zero),
            courseCatalogue: courseCatalogue,
            onboarding: InMemoryOnboardingStore()
        )
    }
}
