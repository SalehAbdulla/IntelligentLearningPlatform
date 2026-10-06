//
//  TutorDashboardViewModel.swift
//  StudyForge
//
//  F11 — presentation logic for J01 (`99_Home_Dashboard_Tutor_{M2}`), the tutor's landing
//  screen, and the course list it shares with J02 (`100_Tutor_Course_List_{M2}`).
//
//  WHY IT AGGREGATES ON LOAD
//  -------------------------
//  J01's KPI row and its "pending review" badge are COHORT-wide: they must sum across every
//  course the tutor owns, not describe the one they happen to be looking at. Doing that once
//  at load — rather than recomputing as the tutor scrolls — keeps the numbers stable while
//  they read them, which matters when the figure is "how many students need attention".
//

import Foundation

@MainActor
@Observable
final class TutorDashboardViewModel {

    /// The tutor's courses. `.empty` is a designed state, not an error.
    private(set) var state: LoadState<[Course]> = .idle

    /// Pending review items across every course, for J01's badge.
    private(set) var pendingReviewCount = 0

    /// Cohort figures across every course, for J01's KPI row.
    private(set) var cohort: CohortSnapshot = .empty

    private let uid: String
    private let store: any CourseStore

    init(uid: String, store: any CourseStore) {
        self.uid = uid
        self.store = store
    }

    // MARK: Derived

    var courses: [Course] { state.value ?? [] }
    var isLoading: Bool { state.isLoading }
    var isEmpty: Bool { if case .empty = state { return true }; return false }
    var error: AppError? { state.error }

    // MARK: Copy

    var title: String { L10n.tutorDashboardTitle.string }
    var studentsLabel: String { L10n.tutorKpiStudents.string }
    var activeLabel: String { L10n.tutorKpiActive.string }
    var masteryLabel: String { L10n.tutorKpiMastery.string }
    var atRiskLabel: String { L10n.tutorKpiAtRisk.string }
    var createCourseTitle: String { L10n.tutorCreateCourse.string }
    var coursesHeading: String { L10n.tutorCoursesHeading.string }
    var noCoursesBody: String { L10n.tutorNoCourses.string }
    var reviewTitle: String { L10n.tutorReviewTitle.string }
    var enrolmentsTitle: String { L10n.tutorRosterTitle.string }
    var archiveTitle: String { L10n.tutorArchive.string }
    var unarchiveTitle: String { L10n.tutorUnarchive.string }
    var archivedBadge: String { L10n.tutorCourseArchived.string }

    /// The badge's text, or `nil` when there is nothing waiting — a badge reading
    /// "0 awaiting review" is noise, not information.
    var reviewBadge: String? {
        pendingReviewCount > 0 ? L10n.tutorReviewBadge.string(pendingReviewCount) : nil
    }

    func enrolmentLabel(_ course: Course) -> String {
        L10n.tutorCourseEnrolments.string(course.enrolmentCount)
    }

    func materialLabel(_ course: Course) -> String {
        L10n.tutorCourseMaterials.string(course.liveMaterialCount())
    }

    func termLabel(_ course: Course) -> String {
        let start = course.termStart.formatted(date: .abbreviated, time: .omitted)
        let end = course.termEnd.formatted(date: .abbreviated, time: .omitted)
        return L10n.tutorTermDates.string(start, end)
    }

    func enrolmentModeName(_ mode: EnrolmentMode) -> String {
        switch mode {
        case .open: L10n.tutorEnrolmentOpen.string
        case .code: L10n.tutorEnrolmentCode.string
        case .approval: L10n.tutorEnrolmentApproval.string
        }
    }

    // MARK: Actions

    func load() async {
        state = .loading
        do {
            let courses = try await store.courses(tutorUid: uid)

            var pending = 0
            var roster: [Enrollment] = []
            for course in courses {
                pending += try await store.reviewItems(courseId: course.id)
                    .filter { $0.status.isPending }
                    .count
                roster += try await store.enrollments(courseId: course.id)
            }

            pendingReviewCount = pending
            cohort = CohortSnapshot.from(roster)
            state = .from(courses)
        } catch {
            state = .failed(AppError.from(error))
        }
    }

    /// Archives or restores a course (J02's archive swipe action).
    ///
    /// Writing the flag and reloading — rather than mutating the row in place — keeps the list,
    /// the badge count and the cohort KPIs derived from ONE read, so an archived course cannot
    /// leave a stale "awaiting review" figure behind.
    func setArchived(_ course: Course, archived: Bool) async {
        var updated = course
        updated.isArchived = archived
        updated.updatedAt = .now

        do {
            try await store.upsert(updated)
            await load()
        } catch {
            state = .failed(AppError.from(error))
        }
    }

    /// J02's swipe label: what the action will DO, so a swipe on an archived course offers
    /// "Unarchive" rather than the same word twice.
    func archiveActionTitle(_ course: Course) -> String {
        course.isArchived ? unarchiveTitle : archiveTitle
    }
}
