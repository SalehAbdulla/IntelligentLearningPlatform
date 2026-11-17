import Foundation

enum TutorStudioCopy {

    static func text(_ key: String) -> String {
        Bundle.main.localizedString(forKey: key, value: nil, table: "TutorStudio")
    }

    static func format(_ key: String, _ arguments: any CVarArg...) -> String {
        String(format: text(key), locale: .current, arguments: arguments)
    }

    static var homeTitle: String { text("studio.home.title") }
    static var createCourse: String { text("studio.home.create") }
    static var kpiStudents: String { text("studio.kpi.students") }
    static var kpiActive: String { text("studio.kpi.active") }
    static var kpiMastery: String { text("studio.kpi.mastery") }
    static var kpiAtRisk: String { text("studio.kpi.atRisk") }
    static var yourCourses: String { text("studio.home.courses") }
    static var coursesFooter: String { text("studio.home.coursesFooter") }
    static var showLabel: String { text("studio.home.show") }
    static var activeTab: String { text("studio.home.activeTab") }
    static var archivedTab: String { text("studio.home.archivedTab") }
    static var archived: String { text("studio.home.archived") }
    static var archive: String { text("studio.home.archive") }
    static var unarchive: String { text("studio.home.unarchive") }
    static var archiveTitle: String { text("studio.home.archiveTitle") }
    static var emptyTitle: String { text("studio.home.emptyTitle") }
    static var emptyBody: String { text("studio.home.emptyBody") }
    static var editCourse: String { text("studio.hub.edit") }
    static var courseActions: String { text("studio.hub.actions") }
    static var inviteStudents: String { text("studio.hub.invite") }
    static var invite: String { text("studio.hub.inviteButton") }
    static var inviteNamePlaceholder: String { text("studio.hub.inviteName") }
    static var inviteNumberPlaceholder: String { text("studio.hub.inviteNumber") }
    static var inviteApprovalFooter: String { text("studio.hub.inviteApproval") }
    static var exportGradebook: String { text("studio.hub.export") }
    static var reviewQueueTitle: String { text("studio.queue.title") }
    static var searchPlaceholder: String { text("studio.hub.search") }
    static var sortLabel: String { text("studio.hub.sort") }
    static var rosterEmptyTitle: String { text("studio.hub.emptyTitle") }
    static var noMatch: String { text("studio.hub.noMatch") }
    static var columnStudent: String { text("studio.column.student") }
    static var columnStudentNumber: String { text("studio.column.studentNumber") }
    static var columnMastery: String { text("studio.column.mastery") }
    static var columnActive: String { text("studio.column.active") }
    static var columnLastActive: String { text("studio.column.lastActive") }
    static var columnStatus: String { text("studio.column.status") }
    static var columnRisk: String { text("studio.column.risk") }
    static var atRisk: String { text("studio.student.atRisk") }
    static var neverActive: String { text("studio.student.neverActive") }
    static var approveStudent: String { text("studio.hub.approve") }
    static var removeStudent: String { text("studio.hub.remove") }
    static var removeTitle: String { text("studio.hub.removeTitle") }
    static var publishMaterial: String { text("studio.hub.publish") }
    static var writeAnnouncement: String { text("studio.hub.announce") }
    static var publishTitle: String { text("studio.publish.title") }
    static var materialLabel: String { text("studio.publish.material") }
    static var noMaterials: String { text("studio.publish.noMaterials") }
    static var alreadyPublished: String { text("studio.publish.already") }
    static var draftNotVisible: String { text("studio.publish.draft") }
    static var publishDateLabel: String { text("studio.publish.date") }
    static var scheduleToggle: String { text("studio.publish.schedule") }
    static var targetCohort: String { text("studio.publish.cohort") }
    static var allCohorts: String { text("studio.publish.all") }
    static var notifyStudents: String { text("studio.publish.notify") }
    static var notifyFooter: String { text("studio.publish.notifyFooter") }
    static var draftAI: String { text("studio.publish.ai") }
    static var draftAIFooter: String { text("studio.publish.aiFooter") }
    static var publish: String { text("studio.publish.button") }
    static var publishing: String { text("studio.publish.publishing") }
    static var publishedTitle: String { text("studio.publish.done") }
    static var scheduledTitle: String { text("studio.publish.scheduled") }
    static var pendingLabel: String { text("studio.queue.pending") }
    static var bulkApproveMessage: String { text("studio.queue.bulkMessage") }
    static var approve: String { text("studio.queue.approve") }
    static var rejectItem: String { text("studio.queue.reject") }
    static var queueEmptyTitle: String { text("studio.queue.emptyTitle") }
    static var queueEmptyBody: String { text("studio.queue.emptyBody") }
    static var rejectIntro: String { text("studio.reject.intro") }
    static var rejectReasonLabel: String { text("studio.reject.reason") }
    static var rejectInaccurate: String { text("studio.reject.inaccurate") }
    static var rejectUnsupported: String { text("studio.reject.unsupported") }
    static var rejectOffTopic: String { text("studio.reject.offTopic") }
    static var rejectOther: String { text("studio.reject.other") }
    static var rejectNoteLabel: String { text("studio.reject.note") }
    static var rejectNotePlaceholder: String { text("studio.reject.notePlaceholder") }
    static var topicMastery: String { text("studio.student.topics") }
    static var progressProfile: String { text("studio.student.profile") }
    static var axisMastery: String { text("studio.student.axisMastery") }
    static var axisActivity: String { text("studio.student.axisActivity") }
    static var axisStanding: String { text("studio.student.axisStanding") }
    static var noSharedProgress: String { text("studio.student.noProgress") }
    static var recentActivity: String { text("studio.student.activity") }
    static var encouragementsSent: String { text("studio.student.sent") }
    static var privacyNote: String { text("studio.student.privacy") }
    static var sendEncouragement: String { text("studio.student.encourage") }
    static var encouragementSent: String { text("studio.student.encouraged") }
    static var backToRoster: String { text("studio.student.back") }
    static var messagePlaceholder: String { text("studio.student.messagePlaceholder") }
    static var send: String { text("studio.student.send") }
    static var formatLabel: String { text("studio.gradebook.format") }
    static var fileType: String { text("studio.gradebook.fileType") }
    static var includeLabel: String { text("studio.gradebook.include") }
    static var scopeLabel: String { text("studio.gradebook.scope") }
    static var courseLabel: String { text("studio.gradebook.course") }
    static var studentsLabel: String { text("studio.gradebook.students") }
    static var activeSinceToggle: String { text("studio.gradebook.since") }
    static var fromLabel: String { text("studio.gradebook.from") }
    static var includeRemoved: String { text("studio.gradebook.removed") }
    static var previewLabel: String { text("studio.gradebook.preview") }
    static var noRows: String { text("studio.gradebook.noRows") }
    static var gradebookNote: String { text("studio.gradebook.note") }

    static func archiveMessage(_ title: String) -> String { format("studio.home.archiveMessage", title) }
    static func courseTitle(_ code: String, _ name: String) -> String { format("studio.course.title", code, name) }
    static func courseDetail(_ students: Int, _ published: Int) -> String { format("studio.course.detail", students, published) }
    static func pendingReview(_ count: Int) -> String { format("studio.home.pending", count) }
    static func percent(_ value: Int) -> String { format("studio.percent", value) }
    static func rosterTitle(_ code: String) -> String { format("studio.hub.rosterTitle", code) }
    static func rosterEmptyBody(_ code: String) -> String { format("studio.hub.emptyBody", code) }
    static func inviteDuplicate(_ number: String) -> String { format("studio.hub.duplicate", number) }
    static func removeMessage(_ name: String) -> String { format("studio.hub.removeMessage", name) }
    static func visibleFrom(_ date: String) -> String { format("studio.publish.visibleFrom", date) }
    static func newMaterialTitle(_ title: String) -> String { format("studio.publish.announceTitle", title) }
    static func newMaterialBody(_ title: String, _ course: String) -> String { format("studio.publish.announceBody", title, course) }
    static func publishedBody(_ courses: Int, _ drafted: Int) -> String { format("studio.publish.doneBody", courses, drafted) }
    static func draftFailures(_ count: Int) -> String { format("studio.publish.failures", count) }
    static func cardDraft(_ front: String, _ back: String) -> String { format("studio.draft.card", front, back) }
    static func questionDraft(_ number: Int, _ stem: String, _ answer: String) -> String { format("studio.draft.question", number, stem, answer) }
    static func bulkApprove(_ count: Int) -> String { format("studio.queue.bulk", count) }
    static func lowConfidenceCount(_ count: Int) -> String { format("studio.queue.lowCount", count) }
    static func confidence(_ value: Double) -> String { format("studio.queue.confidence", value) }
    static func reviewItemTitle(_ kind: String, _ material: String) -> String { format("studio.queue.itemTitle", kind, material) }
    static func reasonWithNote(_ reason: String, _ note: String) -> String { format("studio.reject.withNote", reason, note) }
    static func studentSummary(_ code: String, _ active: String, _ mastery: Int) -> String { format("studio.student.summary", code, active, mastery) }
    static func cohortComparison(_ mastery: Int, _ average: Int) -> String { format("studio.student.cohort", mastery, average) }
    static func quizActivity(_ title: String, _ score: String) -> String { format("studio.student.quizActivity", title, score) }
    static func cardsActivity(_ count: Int) -> String { format("studio.student.cardsActivity", count) }
    static func activityDetail(_ date: String, _ duration: String) -> String { format("studio.student.activityDetail", date, duration) }
    static func encouragementTitle(_ name: String) -> String { format("studio.student.encourageTitle", name) }
    static func encouragementBody(_ name: String, _ course: String) -> String { format("studio.student.encourageBody", name, course) }
    static func encouragementFooter(_ name: String) -> String { format("studio.student.encourageFooter", name) }
    static func studentScope(_ included: Int, _ total: Int) -> String { format("studio.gradebook.scopeValue", included, total) }
    static func gradebookTitle(_ course: String) -> String { format("studio.gradebook.title", course) }
    static func exportButton(_ format: String) -> String { format("studio.gradebook.export", format) }
    static func shareFile(_ name: String) -> String { format("studio.gradebook.share", name) }

    static func filterTitle(_ filter: TutorRosterFilter, count: Int) -> String {
        let title = text("studio.filter.\(filter.rawValue)")
        return filter == .all ? title : format("studio.filter.count", title, count)
    }

    static func sortTitle(_ sort: TutorRosterSort) -> String { text("studio.sort.\(sort.rawValue)") }
    static func riskTitle(_ flag: TutorRiskFlag) -> String { text("studio.risk.\(flag.rawValue)") }
    static func statusTitle(_ status: EnrollmentStatus) -> String { text("studio.enrollment.\(status.rawValue)") }
    static func statusTitle(_ status: ReviewStatus) -> String { text("studio.review.\(status.rawValue)") }
    static func kindTitle(_ kind: ReviewKind) -> String { text("studio.kind.\(kind.rawValue)") }
    static func queueFilterTitle(_ filter: TutorQueueFilter) -> String { text("studio.queue.filter.\(filter.rawValue)") }
    static func formatTitle(_ format: TutorGradebookFormat) -> String { text("studio.format.\(format.rawValue)") }
}
