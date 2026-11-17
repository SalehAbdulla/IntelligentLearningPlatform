import Foundation

@MainActor
@Observable
final class TutorCourseHubViewModel {

    static let nameMaxCharacters = 60
    static let numberMaxCharacters = 20

    let courseId: String
    private(set) var course: Course? = nil
    private(set) var enrollments: [Enrollment] = []
    private(set) var pendingReviewCount = 0
    private(set) var hasLoaded = false
    private(set) var error: AppError? = nil
    private(set) var inviteMessage: String? = nil
    private(set) var isInviting = false

    var query = ""
    var filter: TutorRosterFilter = .all
    var sort: TutorRosterSort = .name
    var inviteName = ""
    var inviteNumber = ""

    private let uid: String
    private let store: any CourseStore
    private let clock: () -> Date

    init(uid: String, courseId: String, store: any CourseStore, clock: @escaping () -> Date = { .now }) {
        self.uid = uid
        self.courseId = courseId
        self.store = store
        self.clock = clock
    }

    var roster: [Enrollment] {
        TutorStudentInsights.roster(enrollments, query: query, filter: filter, sort: sort, now: clock())
    }

    var cohort: CohortSnapshot { CohortSnapshot.from(enrollments, now: clock()) }

    var hasStudents: Bool { enrollments.contains { $0.status != .removed } }

    var searchFoundNothing: Bool { hasStudents && roster.isEmpty }

    var canInvite: Bool {
        !isInviting
            && !inviteName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !inviteNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func count(_ filter: TutorRosterFilter) -> Int {
        let now = clock()
        return enrollments.filter { filter.includes($0, now: now) }.count
    }

    func lastActiveText(_ enrollment: Enrollment) -> String {
        TutorStudentInsights.lastActiveText(enrollment, now: clock())
    }

    func isAtRisk(_ enrollment: Enrollment) -> Bool {
        TutorStudentInsights.isAtRisk(enrollment, now: clock())
    }

    func load() async {
        do {
            course = try await store.course(id: courseId)
            enrollments = try await store.enrollments(courseId: courseId)
            pendingReviewCount = try await store.reviewItems(courseId: courseId).filter { $0.status.isPending }.count
            error = nil
        } catch {
            self.error = AppError.from(error)
        }
        hasLoaded = true
    }

    func limitInviteFields() {
        if inviteName.count > Self.nameMaxCharacters { inviteName = String(inviteName.prefix(Self.nameMaxCharacters)) }
        if inviteNumber.count > Self.numberMaxCharacters { inviteNumber = String(inviteNumber.prefix(Self.numberMaxCharacters)) }
    }

    func invite() async -> Bool {
        guard canInvite, var course else { return false }
        let name = inviteName.trimmingCharacters(in: .whitespacesAndNewlines)
        let number = inviteNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        if enrollments.contains(where: { $0.studentNumber.caseInsensitiveCompare(number) == .orderedSame && $0.status != .removed }) {
            inviteMessage = TutorStudioCopy.inviteDuplicate(number)
            return false
        }
        isInviting = true
        defer { isInviting = false }

        let studentUid = "invite-\(number.lowercased())"
        let enrollment = Enrollment(
            courseId: courseId,
            uid: studentUid,
            studentName: name,
            studentNumber: number,
            status: course.enrolmentMode == .approval ? .pending : .active
        )
        course.enrol(uid: studentUid, at: clock())
        do {
            try await store.upsert(enrollment)
            try await store.upsert(course)
            inviteName = ""
            inviteNumber = ""
            inviteMessage = nil
            await load()
            return true
        } catch {
            self.error = AppError.from(error)
            return false
        }
    }

    func approve(_ enrollment: Enrollment) async {
        await update(enrollment) { $0.status = .active }
    }

    func remove(_ enrollment: Enrollment) async {
        await update(enrollment) { $0.status = .removed }
        guard var course else { return }
        course.enrolledUids.removeAll { $0 == enrollment.uid }
        course.updatedAt = clock()
        do {
            try await store.upsert(course)
            self.course = course
        } catch {
            self.error = AppError.from(error)
        }
    }

    private func update(_ enrollment: Enrollment, _ change: (inout Enrollment) -> Void) async {
        var updated = enrollment
        change(&updated)
        do {
            try await store.upsert(updated)
            if let index = enrollments.firstIndex(where: { $0.id == updated.id }) {
                enrollments[index] = updated
            }
        } catch {
            self.error = AppError.from(error)
        }
    }
}
