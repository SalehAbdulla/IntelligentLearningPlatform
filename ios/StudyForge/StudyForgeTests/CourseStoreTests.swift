//
//  CourseStoreTests.swift
//  StudyForgeTests
//
//  F11 — the tutor store, in both its in-memory and on-device forms.
//
//  The cascade test is the one that matters: deleting a course must not leave a roster or a
//  review queue behind pointing at something that no longer exists.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Course store (F11)")
struct CourseStoreTests {

    private func course(id: String = "c1", tutor: String = "t1") -> Course {
        Course(id: id, name: "IT8108", code: "IT8108", tutorUid: tutor)
    }

    private func enrollment(courseId: String = "c1", uid: String = "s1") -> Enrollment {
        Enrollment(courseId: courseId, uid: uid, studentName: "Sara Ali", studentNumber: "202300001")
    }

    private func reviewItem(courseId: String = "c1") -> ReviewItem {
        ReviewItem(
            courseId: courseId,
            materialId: "m1",
            materialTitle: "Lecture 4",
            kind: .summary,
            draft: "Draft",
            sourceSnippet: "Source",
            confidence: 0.8
        )
    }

    @Test("Courses are scoped to their tutor — the same boundary the rules enforce")
    func coursesAreScopedToTutor() async throws {
        let store = InMemoryCourseStore(courses: [
            course(id: "a", tutor: "t1"),
            course(id: "b", tutor: "t2"),
        ])

        let mine = try await store.courses(tutorUid: "t1")

        #expect(mine.count == 1)
        #expect(mine.first?.id == "a")
    }

    @Test("An enrolment is keyed by uid + course, so the same student cannot be enrolled twice")
    func enrollmentIdIsComposite() {
        #expect(Enrollment.identifier(uid: "s1", courseId: "c1") == "s1_c1")
        #expect(enrollment().id == "s1_c1")
    }

    @Test("Deleting a course cascades to its roster, queue and announcements")
    func deleteCascades() async throws {
        let store = InMemoryCourseStore(
            courses: [course()],
            enrollments: [enrollment()],
            reviewItems: [reviewItem()],
            announcements: [Announcement(courseId: "c1", authorUid: "t1", title: "Hi", body: "Body", sentAt: .now)]
        )

        try await store.deleteCourse(id: "c1")

        #expect(try await store.course(id: "c1") == nil)
        #expect(try await store.enrollments(courseId: "c1").isEmpty)
        #expect(try await store.reviewItems(courseId: "c1").isEmpty)
        #expect(try await store.announcements(courseId: "c1").isEmpty)
    }

    @Test("A storage failure maps to an AppError carrying a reference")
    func failureMapping() async throws {
        let store = InMemoryCourseStore()
        await store.forceFailure(.storageFailed)

        do {
            _ = try await store.courses(tutorUid: "t1")
            Issue.record("expected the forced failure to throw")
        } catch {
            #expect(AppError.from(error) == .server(reference: "tutor-store-failed"))
        }
    }

    @Test("A course, its roster and its queue survive a file round-trip")
    func fileRoundTrip() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("studyforge-tutor-\(UUID().uuidString)", isDirectory: true)

        let store = FileCourseStore(directory: directory)
        try await store.upsert(course())
        try await store.upsert(enrollment())
        try await store.upsert(reviewItem())

        // A SECOND instance, to prove the data came off disk rather than a cache.
        let reopened = FileCourseStore(directory: directory)
        #expect(try await reopened.course(id: "c1")?.code == "IT8108")
        #expect(try await reopened.enrollments(courseId: "c1").count == 1)
        #expect(try await reopened.reviewItems(courseId: "c1").count == 1)

        try? FileManager.default.removeItem(at: directory)
    }
}
