//
//  InMemoryCourseStore.swift
//  StudyForge
//
//  A `CourseStore` that keeps everything in memory — previews and tests.
//
//  A REAL conformance rather than a stub, mirroring `InMemorySubscriptionStore`, so a screen
//  driven by it behaves exactly as it does against the file store. The forced-failure switch
//  is what lets a screen's error state be photographed without corrupting a file.
//

import Foundation

actor InMemoryCourseStore: CourseStore {

    private var courses: [String: Course]
    private var enrollments: [String: Enrollment]
    private var reviewItems: [String: ReviewItem]
    private var announcements: [String: Announcement]

    /// When set, every call fails with it until cleared.
    private var failure: TutorError?

    init(
        courses: [Course] = [],
        enrollments: [Enrollment] = [],
        reviewItems: [ReviewItem] = [],
        announcements: [Announcement] = []
    ) {
        self.courses = Dictionary(uniqueKeysWithValues: courses.map { ($0.id, $0) })
        self.enrollments = Dictionary(uniqueKeysWithValues: enrollments.map { ($0.id, $0) })
        self.reviewItems = Dictionary(uniqueKeysWithValues: reviewItems.map { ($0.id, $0) })
        self.announcements = Dictionary(uniqueKeysWithValues: announcements.map { ($0.id, $0) })
    }

    // MARK: Courses

    func courses(tutorUid: String) async throws -> [Course] {
        try failIfForced()
        return courses.values
            .filter { $0.tutorUid == tutorUid }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func course(id: String) async throws -> Course? {
        try failIfForced()
        return courses[id]
    }

    func upsert(_ course: Course) async throws {
        try failIfForced()
        courses[course.id] = course
    }

    func deleteCourse(id: String) async throws {
        try failIfForced()
        courses[id] = nil
        // Cascade, so a deleted course cannot leave a roster or a queue behind pointing at
        // something that no longer exists — the "removing content that is referenced
        // elsewhere" case docs/02 §6 lists for the admin feature, applied here.
        enrollments = enrollments.filter { $0.value.courseId != id }
        reviewItems = reviewItems.filter { $0.value.courseId != id }
        announcements = announcements.filter { $0.value.courseId != id }
    }

    // MARK: Roster

    func enrollments(courseId: String) async throws -> [Enrollment] {
        try failIfForced()
        return enrollments.values
            .filter { $0.courseId == courseId }
            .sorted { ($0.lastActiveAt ?? .distantPast) > ($1.lastActiveAt ?? .distantPast) }
    }

    func upsert(_ enrollment: Enrollment) async throws {
        try failIfForced()
        enrollments[enrollment.id] = enrollment
    }

    // MARK: Review queue

    func reviewItems(courseId: String) async throws -> [ReviewItem] {
        try failIfForced()
        return reviewItems.values
            .filter { $0.courseId == courseId }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func upsert(_ item: ReviewItem) async throws {
        try failIfForced()
        reviewItems[item.id] = item
    }

    // MARK: Announcements

    func announcements(courseId: String) async throws -> [Announcement] {
        try failIfForced()
        return announcements.values
            .filter { $0.courseId == courseId }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func upsert(_ announcement: Announcement) async throws {
        try failIfForced()
        announcements[announcement.id] = announcement
    }

    // MARK: Test and preview controls

    /// Forces every call to fail with `error`. Pass `nil` to restore success.
    func forceFailure(_ error: TutorError?) {
        failure = error
    }

    private func failIfForced() throws {
        if let failure { throw failure }
    }
}
