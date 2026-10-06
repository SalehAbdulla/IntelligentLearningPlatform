//
//  TutorDashboardViewModelTests.swift
//  StudyForgeTests
//
//  F11 — J01's cohort KPIs and pending badge, which are aggregated across every course.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Tutor dashboard (F11)")
@MainActor
struct TutorDashboardViewModelTests {

    private func course(id: String, tutor: String = "t1") -> Course {
        Course(id: id, name: "Course \(id)", code: id, tutorUid: tutor)
    }

    private func pendingItem(courseId: String, confidence: Double = 0.9) -> ReviewItem {
        ReviewItem(
            courseId: courseId,
            materialId: "m1",
            materialTitle: "Lecture",
            kind: .summary,
            draft: "Draft",
            sourceSnippet: "Source",
            confidence: confidence
        )
    }

    @Test("A tutor with no courses reads as the empty state, not an error")
    func emptyState() async {
        let viewModel = TutorDashboardViewModel(uid: "t1", store: InMemoryCourseStore())

        await viewModel.load()

        #expect(viewModel.isEmpty)
        #expect(viewModel.error == nil)
        #expect(viewModel.reviewBadge == nil)
    }

    @Test("The badge counts pending items across EVERY course, and is absent at zero")
    func pendingBadge() async {
        let store = InMemoryCourseStore(
            courses: [course(id: "a"), course(id: "b")],
            reviewItems: [pendingItem(courseId: "a"), pendingItem(courseId: "b"), pendingItem(courseId: "b")]
        )
        let viewModel = TutorDashboardViewModel(uid: "t1", store: store)

        await viewModel.load()

        #expect(viewModel.pendingReviewCount == 3)
        #expect(viewModel.reviewBadge == L10n.tutorReviewBadge.string(3))
    }

    @Test("A decided item is no longer pending")
    func decidedItemsDoNotCount() async throws {
        var decided = pendingItem(courseId: "a")
        try decided.decide(.approve)
        let store = InMemoryCourseStore(courses: [course(id: "a")], reviewItems: [decided])
        let viewModel = TutorDashboardViewModel(uid: "t1", store: store)

        await viewModel.load()

        #expect(viewModel.pendingReviewCount == 0)
        #expect(viewModel.reviewBadge == nil, "a badge reading 0 is noise, not information")
    }

    @Test("The KPIs aggregate the roster across every course")
    func kpisAggregate() async {
        let store = InMemoryCourseStore(
            courses: [course(id: "a"), course(id: "b")],
            enrollments: [
                Enrollment(courseId: "a", uid: "s1", studentName: "A", studentNumber: "1", masteryPercent: 80, lastActiveAt: .now),
                Enrollment(courseId: "b", uid: "s2", studentName: "B", studentNumber: "2", masteryPercent: 40, lastActiveAt: .now),
            ]
        )
        let viewModel = TutorDashboardViewModel(uid: "t1", store: store)

        await viewModel.load()

        #expect(viewModel.cohort.students == 2)
        #expect(viewModel.cohort.averageMastery == 60)
        #expect(viewModel.cohort.atRisk == 1)
    }

    @Test("Another tutor's course is never listed")
    func scopedToTutor() async {
        let store = InMemoryCourseStore(courses: [course(id: "a", tutor: "t1"), course(id: "b", tutor: "t2")])
        let viewModel = TutorDashboardViewModel(uid: "t1", store: store)

        await viewModel.load()

        #expect(viewModel.courses.map(\.id) == ["a"])
    }

    @Test("A store failure surfaces as an AppError")
    func failureMaps() async {
        let store = InMemoryCourseStore()
        await store.forceFailure(.storageFailed)
        let viewModel = TutorDashboardViewModel(uid: "t1", store: store)

        await viewModel.load()

        #expect(viewModel.error != nil)
    }

    @Test("The copy comes from the catalogue")
    func copyIsLocalised() {
        let viewModel = TutorDashboardViewModel(uid: "t1", store: InMemoryCourseStore())

        #expect(viewModel.title == L10n.tutorDashboardTitle.string)
        #expect(viewModel.studentsLabel == L10n.tutorKpiStudents.string)
        #expect(viewModel.createCourseTitle == L10n.tutorCreateCourse.string)

        let course = Course(name: "IT8108", code: "IT8108", tutorUid: "t1")
        #expect(viewModel.enrolmentLabel(course) == L10n.tutorCourseEnrolments.string(0))
        #expect(viewModel.archivedBadge == L10n.tutorCourseArchived.string)
    }

    @Test("Archiving a course writes the flag, and the row reflects it after the reload")
    func archivePersists() async throws {
        let store = InMemoryCourseStore(courses: [course(id: "a")])
        let viewModel = TutorDashboardViewModel(uid: "t1", store: store)

        await viewModel.load()
        let listed = try #require(viewModel.courses.first)
        await viewModel.setArchived(listed, archived: true)

        #expect(viewModel.courses.first?.isArchived == true)
        #expect(try await store.course(id: "a")?.isArchived == true, "the flag is written, not just shown")
    }

    @Test("The archive swipe offers the action that is not already in effect")
    func archiveActionTitleFlips() {
        let viewModel = TutorDashboardViewModel(uid: "t1", store: InMemoryCourseStore())
        var course = Course(name: "IT8108", code: "IT8108", tutorUid: "t1")

        #expect(viewModel.archiveActionTitle(course) == L10n.tutorArchive.string, "a live course offers Archive")

        course.isArchived = true
        #expect(viewModel.archiveActionTitle(course) == L10n.tutorUnarchive.string, "an archived course offers Unarchive")
    }

    @Test("A failed archive surfaces as an AppError rather than a silent no-op")
    func archiveFailureMaps() async {
        let store = InMemoryCourseStore(courses: [course(id: "a")])
        let viewModel = TutorDashboardViewModel(uid: "t1", store: store)

        await viewModel.load()
        await store.forceFailure(.storageFailed)
        await viewModel.setArchived(course(id: "a"), archived: true)

        #expect(viewModel.error != nil)
    }
}
