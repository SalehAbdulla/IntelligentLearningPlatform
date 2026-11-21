import Foundation

@MainActor
@Observable
final class TutorStudioHomeViewModel {

    private(set) var courses: [Course] = []
    private(set) var enrollments: [Enrollment] = []
    private(set) var pendingReviewCount = 0
    private(set) var hasLoaded = false
    private(set) var error: AppError? = nil
    var showsArchived = false

    let uid: String
    private let store: any CourseStore
    private let directory: any CourseDirectory
    private let clock: () -> Date

    init(
        uid: String,
        store: any CourseStore,
        directory: any CourseDirectory = InMemoryCourseDirectory(),
        clock: @escaping () -> Date = { .now }
    ) {
        self.uid = uid
        self.store = store
        self.directory = directory
        self.clock = clock
    }

    var activeCourses: [Course] { courses.filter { !$0.isArchived } }
    var archivedCourses: [Course] { courses.filter(\.isArchived) }
    var visibleCourses: [Course] { showsArchived ? archivedCourses : activeCourses }
    var isEmpty: Bool { hasLoaded && courses.isEmpty && error == nil }

    private var activeCourseIds: Set<String> { Set(activeCourses.map(\.id)) }

    private var activeEnrollments: [Enrollment] {
        let ids = activeCourseIds
        return enrollments.filter { ids.contains($0.courseId) }
    }

    var cohort: CohortSnapshot { CohortSnapshot.from(activeEnrollments, now: clock()) }

    var atRiskCount: Int {
        let now = clock()
        return activeEnrollments.filter { TutorStudentInsights.isAtRisk($0, now: now) }.count
    }

    var courseIdsForReview: [String] { activeCourses.map(\.id) }

    func studentCount(for course: Course) -> Int {
        enrollments.filter { $0.courseId == course.id && $0.status == .active }.count
    }

    func load() async {
        guard !uid.isEmpty else {
            courses = []
            hasLoaded = true
            return
        }
        do {
            let loaded = try await store.courses(tutorUid: uid)
            var roster: [Enrollment] = []
            var pending = 0
            for course in loaded {
                roster += try await store.enrollments(courseId: course.id)
                if !course.isArchived {
                    pending += try await store.reviewItems(courseId: course.id).filter { $0.status.isPending }.count
                }
            }
            courses = loaded
            enrollments = roster
            pendingReviewCount = pending
            error = nil
            try? await directory.register(loaded)
        } catch {
            self.error = AppError.from(error)
        }
        hasLoaded = true
    }

    func setArchived(_ course: Course, archived: Bool) async {
        var updated = course
        updated.isArchived = archived
        updated.updatedAt = clock()
        do {
            try await store.upsert(updated)
            await load()
        } catch {
            self.error = AppError.from(error)
        }
    }
}
