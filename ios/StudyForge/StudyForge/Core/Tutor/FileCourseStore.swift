//
//  FileCourseStore.swift
//  StudyForge
//
//  The on-device store for the tutor studio: one JSON file in Application Support.
//
//  WHY A FILE AND NOT FIRESTORE — YET
//  ----------------------------------
//  `backend/firestore.rules` already scopes all four collections to the owning tutor, which
//  is correct and stays. What it does not provide is a studio that works with no project
//  configured — the same gap the other stores close the same way. This file is the local
//  half; the rules are the server half, behind one protocol.
//

import Foundation

actor FileCourseStore: CourseStore {

    /// The persisted shape: all four collections in one file.
    ///
    /// One file rather than four because a course and its roster, queue and announcements are
    /// written and read together; four files would be four chances to disagree, and a course
    /// whose roster failed to load looks identical to a course with no students.
    private struct Database: Codable {
        var courses: [String: Course] = [:]
        var enrollments: [String: Enrollment] = [:]
        var reviewItems: [String: ReviewItem] = [:]
        var announcements: [String: Announcement] = [:]
    }

    private let fileURL: URL

    /// The database once read. `nil` until then, so the file is touched at most once per launch.
    private var cache: Database?

    /// - Parameter directory: where to keep the file. Injected so a test can point at a
    ///   temporary directory rather than the real Application Support folder.
    init(directory: URL? = nil) {
        let base = directory ?? Self.defaultDirectory
        self.fileURL = base.appendingPathComponent("tutor-studio.json")
    }

    // MARK: Courses

    func courses(tutorUid: String) async throws -> [Course] {
        try load().courses.values
            .filter { $0.tutorUid == tutorUid }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func course(id: String) async throws -> Course? {
        try load().courses[id]
    }

    func upsert(_ course: Course) async throws {
        var database = try load()
        database.courses[course.id] = course
        try persist(database)
    }

    func deleteCourse(id: String) async throws {
        var database = try load()
        database.courses[id] = nil
        // Cascade, matching the in-memory store: a deleted course must not leave a roster or
        // queue pointing at something that no longer exists.
        database.enrollments = database.enrollments.filter { $0.value.courseId != id }
        database.reviewItems = database.reviewItems.filter { $0.value.courseId != id }
        database.announcements = database.announcements.filter { $0.value.courseId != id }
        try persist(database)
    }

    // MARK: Roster

    func enrollments(courseId: String) async throws -> [Enrollment] {
        try load().enrollments.values
            .filter { $0.courseId == courseId }
            .sorted { ($0.lastActiveAt ?? .distantPast) > ($1.lastActiveAt ?? .distantPast) }
    }

    func upsert(_ enrollment: Enrollment) async throws {
        var database = try load()
        database.enrollments[enrollment.id] = enrollment
        try persist(database)
    }

    // MARK: Review queue

    func reviewItems(courseId: String) async throws -> [ReviewItem] {
        try load().reviewItems.values
            .filter { $0.courseId == courseId }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func upsert(_ item: ReviewItem) async throws {
        var database = try load()
        database.reviewItems[item.id] = item
        try persist(database)
    }

    // MARK: Announcements

    func announcements(courseId: String) async throws -> [Announcement] {
        try load().announcements.values
            .filter { $0.courseId == courseId }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func upsert(_ announcement: Announcement) async throws {
        var database = try load()
        database.announcements[announcement.id] = announcement
        try persist(database)
    }

    // MARK: Storage

    private func load() throws -> Database {
        if let cache { return cache }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            let empty = Database()
            cache = empty
            return empty
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode(Database.self, from: data)
            cache = decoded
            return decoded
        } catch {
            throw TutorError.storageFailed
        }
    }

    private func persist(_ database: Database) throws {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(database)
            try data.write(to: fileURL, options: .atomic)
            cache = database
        } catch {
            throw TutorError.storageFailed
        }
    }

    /// Application Support, with a fallback.
    private static var defaultDirectory: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first
            .map { $0.appendingPathComponent("StudyForge", isDirectory: true) }
            ?? FileManager.default.temporaryDirectory
    }
}
