//
//  CourseDetailViewModel.swift
//  StudyForge
//
//  F11 — presentation logic for the course hub: J04's roster
//  (`102_Tutor_Course_Roster_{M2}`), J05's material publishing
//  (`103_Tutor_Material_Publish_{M2}`) and J10's gradebook export
//  (`108_Tutor_Gradebook_Export_{M2}`).
//
//  WHY THE ROSTER IS THE HUB
//  -------------------------
//  Every one of these screens is scoped to ONE course, and the course is what the tutor opened.
//  Keeping them behind a single view model means the roster, the published list and the export
//  all read the SAME loaded course rather than three independently-fetched copies that can
//  disagree about how many students are enrolled — the number the table and the export both show.
//

import Foundation

@MainActor
@Observable
final class CourseDetailViewModel {

    let courseId: String

    // MARK: Loaded state

    private(set) var state: LoadState<Course?> = .idle
    private(set) var enrollments: [Enrollment] = []

    /// The tutor's own library (F02), for J05's material picker.
    private(set) var libraryMaterials: [Material] = []

    private(set) var error: AppError?

    // MARK: Bound state

    /// J04's search field.
    var searchText = ""

    // Publish sheet (J05)
    var publishSelection: String?
    var publishDate: Date = .now
    var notifyStudents = true
    private(set) var isPublishing = false

    // Invite sheet (J04)
    var inviteName = ""
    var inviteNumber = ""
    private(set) var isInviting = false

    private let uid: String
    private let store: any CourseStore
    private let materials: any MaterialStore

    init(uid: String, courseId: String, store: any CourseStore, materials: any MaterialStore) {
        self.uid = uid
        self.courseId = courseId
        self.store = store
        self.materials = materials
    }

    // MARK: Derived

    var course: Course? { state.value ?? nil }
    var isLoading: Bool { state.isLoading }
    var isArchived: Bool { course?.isArchived ?? false }

    /// Cohort figures for this course, from the roster already loaded.
    var cohort: CohortSnapshot { CohortSnapshot.from(enrollments) }

    /// Whether the search field is narrowing the roster.
    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// The roster, filtered by the search field (J04's search + filter).
    ///
    /// Matches the name OR the student number, case-insensitively, because a tutor looking for
    /// one student may have either to hand.
    var roster: [Enrollment] {
        guard isSearching else { return enrollments }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return enrollments.filter {
            $0.studentName.lowercased().contains(query)
                || $0.studentNumber.lowercased().contains(query)
        }
    }

    var hasRoster: Bool { !enrollments.isEmpty }
    var searchFoundNothing: Bool { isSearching && roster.isEmpty && !enrollments.isEmpty }

    /// Published materials, newest first.
    var publishedMaterials: [PublishedMaterial] {
        (course?.publishedMaterials ?? []).sorted { $0.publishedAt > $1.publishedAt }
    }

    /// Materials available to publish — the tutor's library minus what is already published, so
    /// the picker cannot offer a duplicate (J05, and the "re-publishing" edge case in docs/02 §6).
    var availableMaterials: [Material] {
        let taken = Set((course?.publishedMaterials ?? []).map(\.materialId))
        return libraryMaterials.filter { !taken.contains($0.id) }
    }

    var canPublish: Bool { publishSelection != nil && !isPublishing }

    var canInvite: Bool {
        !inviteName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !inviteNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isInviting
    }

    /// Whether an export would contain anything (docs/02 §6's "export with no data" case).
    var canExport: Bool { !enrollments.isEmpty }

    // MARK: Copy

    var title: String { course?.name ?? L10n.tutorDashboardTitle.string }
    var rosterTitle: String { L10n.tutorRosterTitle.string }
    var searchPlaceholder: String { L10n.tutorRosterSearchPlaceholder.string }
    var rosterEmptyTitle: String { L10n.tutorRosterEmptyTitle.string }
    var rosterEmptyBody: String { L10n.tutorRosterEmptyBody.string }
    var rosterNoMatch: String { L10n.tutorRosterNoMatch.string }
    var inviteTitle: String { L10n.tutorInviteStudent.string }
    var inviteNameLabel: String { L10n.tutorInviteNameLabel.string }
    var inviteNamePlaceholder: String { L10n.tutorInviteNamePlaceholder.string }
    var inviteNumberLabel: String { L10n.tutorStudentIdLabel.string }
    var exportTitle: String { L10n.tutorExportCSV.string }
    var exportEmpty: String { L10n.tutorExportEmpty.string }
    var publishTitle: String { L10n.tutorPublishTitle.string }
    var publishEmpty: String { L10n.tutorPublishEmpty.string }
    var publishDateLabel: String { L10n.tutorPublishDateLabel.string }
    var notifyStudentsTitle: String { L10n.tutorNotifyStudents.string }
    var publishActionTitle: String { L10n.tutorPublish.string }
    var publishedHeading: String { L10n.tutorPublishedHeading.string }
    var publishedNone: String { L10n.tutorPublishedNone.string }
    var archiveTitle: String { L10n.tutorArchive.string }
    var reviewTitle: String { L10n.tutorReviewTitle.string }
    var announceTitle: String { L10n.tutorAnnounceTitle.string }
    var gradebookTitle: String { L10n.tutorGradebookTitle.string }
    var studentIdLabel: String { L10n.tutorStudentIdLabel.string }
    var lastActiveNeverLabel: String { L10n.tutorLastActiveNever.string }

    func masteryLabel(_ enrollment: Enrollment) -> String {
        L10n.tutorMasteryValue.string(enrollment.masteryPercent)
    }

    func lastActiveLabel(_ enrollment: Enrollment) -> String {
        guard let date = enrollment.lastActiveAt else { return lastActiveNeverLabel }
        return L10n.tutorLastActive.string(date.formatted(date: .abbreviated, time: .omitted))
    }

    func publishedStatusLabel(_ material: PublishedMaterial) -> String {
        material.isLive() ? L10n.tutorPublishedLive.string : L10n.tutorPublishedScheduled.string
    }

    // MARK: Actions

    func load() async {
        state = .loading
        do {
            let course = try await store.course(id: courseId)
            enrollments = try await store.enrollments(courseId: courseId)
            libraryMaterials = (try? await materials.all()) ?? []
            state = .loaded(course)
        } catch {
            state = .failed(AppError.from(error))
        }
    }

    /// Publishes the selected library material to the cohort (J05).
    ///
    /// - Returns: whether it succeeded, so the sheet knows whether to dismiss.
    func publish() async -> Bool {
        guard let materialId = publishSelection,
              let material = libraryMaterials.first(where: { $0.id == materialId }),
              var course,
              !isPublishing
        else { return false }

        isPublishing = true
        defer { isPublishing = false }
        error = nil

        course.publish(PublishedMaterial(
            materialId: materialId,
            title: material.title,
            publishedAt: publishDate,
            notifiesStudents: notifyStudents
        ))

        do {
            try await store.upsert(course)
            publishSelection = nil
            await load()
            return true
        } catch {
            self.error = AppError.from(error)
            return false
        }
    }

    /// Adds a student to the roster (J04).
    ///
    /// In production this sends an invitation and the enrolment document is created when the
    /// student accepts. Here it writes the roster entry directly, so the export and the cohort
    /// KPIs have real rows to work on — an honest stand-in, recorded in the file's header rather
    /// than pretending an email went out.
    func invite() async -> Bool {
        guard canInvite, var course else { return false }

        isInviting = true
        defer { isInviting = false }
        error = nil

        let trimmedName = inviteName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNumber = inviteNumber.trimmingCharacters(in: .whitespacesAndNewlines)

        // A locally-minted uid stands in for the account the invitation would create.
        let uid = "invited_\(UUID().uuidString.prefix(8))"
        let enrollment = Enrollment(
            courseId: courseId,
            uid: uid,
            studentName: trimmedName,
            studentNumber: trimmedNumber,
            status: course.enrolmentMode == .approval ? .pending : .active
        )

        course.enrol(uid: uid)

        do {
            try await store.upsert(course)
            try await store.upsert(enrollment)
            inviteName = ""
            inviteNumber = ""
            await load()
            return true
        } catch {
            self.error = AppError.from(error)
            return false
        }
    }

    /// Archives or restores the course (J02's archive swipe action).
    func setArchived(_ archived: Bool) async {
        guard var course else { return }
        course.isArchived = archived
        course.updatedAt = .now
        do {
            try await store.upsert(course)
            await load()
        } catch {
            self.error = AppError.from(error)
        }
    }

    /// The gradebook CSV for this cohort (J10). Empty when there is nothing to export.
    func gradebookCSV() -> String {
        GradebookExporter.csv(for: enrollments)
    }
}
