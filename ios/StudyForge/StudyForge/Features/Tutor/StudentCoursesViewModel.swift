import Foundation

struct JoinedCourse: Identifiable, Equatable {
    let course: Course
    let enrollment: Enrollment

    var id: String { course.id }
    var isPending: Bool { enrollment.status == .pending }
}

@MainActor
@Observable
final class StudentCoursesViewModel {

    static let codeMaxCharacters = 20

    private(set) var courses: [JoinedCourse] = []
    private(set) var hasLoaded = false
    private(set) var isJoining = false
    private(set) var error: AppError? = nil
    private(set) var joinMessage: String? = nil
    private(set) var joinSucceeded = false
    var joinCode = ""

    let uid: String
    private let studentName: String
    private let studentNumber: String
    private let store: any CourseStore
    private let directory: any CourseDirectory
    private let clock: () -> Date

    init(
        uid: String,
        studentName: String,
        studentNumber: String,
        store: any CourseStore,
        directory: any CourseDirectory = InMemoryCourseDirectory(),
        clock: @escaping () -> Date = { .now }
    ) {
        self.uid = uid
        self.studentName = studentName
        self.studentNumber = studentNumber
        self.store = store
        self.directory = directory
        self.clock = clock
    }

    var isEmpty: Bool { hasLoaded && courses.isEmpty && error == nil }

    var canJoin: Bool {
        !isJoining && !uid.isEmpty && !CourseDirectoryEntry.normalized(joinCode).isEmpty
    }

    func limitCode() {
        if joinCode.count > Self.codeMaxCharacters {
            joinCode = String(joinCode.prefix(Self.codeMaxCharacters))
        }
    }

    func load() async {
        guard !uid.isEmpty else {
            hasLoaded = true
            return
        }
        do {
            var joined: [JoinedCourse] = []
            for entry in try await directory.entries() {
                guard let enrollment = try await store.enrollments(courseId: entry.courseId)
                    .first(where: { $0.uid == uid && $0.status != .removed }),
                    let course = try await store.course(id: entry.courseId) else { continue }
                joined.append(JoinedCourse(course: course, enrollment: enrollment))
            }
            courses = joined.sorted { $0.course.code.localizedCaseInsensitiveCompare($1.course.code) == .orderedAscending }
            error = nil
        } catch {
            self.error = AppError.from(error)
        }
        hasLoaded = true
    }

    func join() async -> Bool {
        guard canJoin else { return false }
        isJoining = true
        joinSucceeded = false
        defer { isJoining = false }

        do {
            guard let entry = try await directory.entry(code: joinCode),
                  var course = try await store.course(id: entry.courseId) else {
                joinMessage = TutorStudioCopy.joinNotFound(joinCode.trimmingCharacters(in: .whitespaces))
                return false
            }
            guard !course.isArchived else {
                joinMessage = TutorStudioCopy.joinArchived(course.code)
                return false
            }
            let existing = try await store.enrollments(courseId: course.id).first { $0.uid == uid }
            if let existing, existing.status != .removed {
                joinMessage = TutorStudioCopy.joinAlready(course.code)
                return false
            }

            let status: EnrollmentStatus = course.enrolmentMode == .approval ? .pending : .active
            var enrollment = existing ?? Enrollment(
                courseId: course.id,
                uid: uid,
                studentName: studentName,
                studentNumber: studentNumber,
                status: status
            )
            enrollment.status = status
            enrollment.lastActiveAt = clock()
            course.enrol(uid: uid, at: clock())
            try await store.upsert(enrollment)
            try await store.upsert(course)

            joinMessage = status == .pending ? TutorStudioCopy.joinPending(course.code) : TutorStudioCopy.joinDone(course.code)
            joinSucceeded = true
            joinCode = ""
            await load()
            return true
        } catch {
            self.error = AppError.from(error)
            return false
        }
    }
}
