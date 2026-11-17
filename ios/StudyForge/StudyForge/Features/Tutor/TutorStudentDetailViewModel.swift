import Foundation

@MainActor
@Observable
final class TutorStudentDetailViewModel {

    static let messageMaxCharacters = 400
    static let minimumRadarAxes = 3

    let enrollment: Enrollment
    let course: Course
    private(set) var cohort: [Enrollment] = []
    private(set) var progress: TutorStudentProgress? = nil
    private(set) var encouragements: [TutorEncouragement] = []
    private(set) var hasLoaded = false
    private(set) var isSending = false
    private(set) var didSend = false
    private(set) var error: AppError? = nil
    var message: String

    private let uid: String
    private let store: any CourseStore
    private let log: any TutorEncouragementLog
    private let progressSource: any TutorStudentProgressSource
    private let clock: () -> Date

    init(
        enrollment: Enrollment,
        course: Course,
        uid: String,
        store: any CourseStore,
        log: any TutorEncouragementLog = InMemoryTutorEncouragementLog(),
        progressSource: any TutorStudentProgressSource = NoSharedProgressSource(),
        clock: @escaping () -> Date = { .now }
    ) {
        self.enrollment = enrollment
        self.course = course
        self.uid = uid
        self.store = store
        self.log = log
        self.progressSource = progressSource
        self.clock = clock
        self.message = TutorStudioCopy.encouragementBody(TutorStudentInsights.firstName(enrollment.studentName), course.name)
    }

    var firstName: String { TutorStudentInsights.firstName(enrollment.studentName) }
    var flags: [TutorRiskFlag] { TutorStudentInsights.riskFlags(for: enrollment, now: clock()) }
    var isAtRisk: Bool { TutorStudentInsights.isAtRisk(enrollment, now: clock()) }
    var lastActiveText: String { TutorStudentInsights.lastActiveText(enrollment, now: clock()) }
    var cohortAverage: Int { TutorStudentInsights.cohortAverage(cohort) }

    var summaryLine: String {
        TutorStudioCopy.studentSummary(course.code, lastActiveText, enrollment.masteryPercent)
    }

    var topics: [TutorTopicProgress] { progress?.topics ?? [] }
    var activity: [TutorActivity] { progress?.activity ?? [] }

    var radarAxes: [SFRadarChart.Axis] {
        if topics.count >= Self.minimumRadarAxes {
            return topics.map { SFRadarChart.Axis(label: $0.topic, value: $0.fraction) }
        }
        let now = clock()
        let average = max(cohortAverage, 1)
        return [
            SFRadarChart.Axis(label: TutorStudioCopy.axisMastery, value: Double(enrollment.masteryPercent) / 100),
            SFRadarChart.Axis(label: TutorStudioCopy.axisActivity, value: TutorStudentInsights.activityScore(enrollment, now: now)),
            SFRadarChart.Axis(label: TutorStudioCopy.axisStanding, value: min(1, Double(enrollment.masteryPercent) / Double(average)))
        ]
    }

    var canSend: Bool {
        !isSending && enrollment.status == .active
            && !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func load() async {
        do {
            cohort = try await store.enrollments(courseId: course.id)
            encouragements = try await log.entries(courseId: course.id, studentUid: enrollment.uid)
            error = nil
        } catch {
            self.error = AppError.from(error)
        }
        progress = await progressSource.progress(forStudent: enrollment.uid)
        hasLoaded = true
    }

    func limitMessage() {
        if message.count > Self.messageMaxCharacters {
            message = String(message.prefix(Self.messageMaxCharacters))
        }
    }

    func sendEncouragement() async -> Bool {
        guard canSend else { return false }
        isSending = true
        defer { isSending = false }

        let now = clock()
        let body = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let announcement = Announcement(
            courseId: course.id,
            authorUid: uid,
            audience: .individual,
            title: TutorStudioCopy.encouragementTitle(firstName),
            body: body,
            sentAt: now,
            createdAt: now
        )
        let entry = TutorEncouragement(
            courseId: course.id,
            studentUid: enrollment.uid,
            announcementId: announcement.id,
            message: body,
            sentAt: now
        )
        do {
            try await store.upsert(announcement)
            try await log.record(entry)
            encouragements.insert(entry, at: 0)
            didSend = true
            return true
        } catch {
            self.error = AppError.from(error)
            return false
        }
    }
}
