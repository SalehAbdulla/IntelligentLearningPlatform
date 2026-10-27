//
//  CourseDetailViewModelTests.swift
//  StudyForgeTests
//
//  F11 — the course hub: J04's roster search, J05's publishing and J10's export gate.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Course detail (F11)")
@MainActor
struct CourseDetailViewModelTests {

    private func course(mode: EnrolmentMode = .code, published: [PublishedMaterial] = []) -> Course {
        Course(
            id: "c1",
            name: "IT8108",
            code: "IT8108",
            tutorUid: "t1",
            enrolmentMode: mode,
            publishedMaterials: published
        )
    }

    private func roster() -> [Enrollment] {
        [
            Enrollment(courseId: "c1", uid: "s1", studentName: "Sara Ali", studentNumber: "202300001", masteryPercent: 80),
            Enrollment(courseId: "c1", uid: "s2", studentName: "Omar Noor", studentNumber: "202300002", masteryPercent: 40),
        ]
    }

    private func viewModel(
        store: InMemoryCourseStore,
        materials: InMemoryMaterialStore = InMemoryMaterialStore()
    ) -> CourseDetailViewModel {
        CourseDetailViewModel(uid: "t1", courseId: "c1", store: store, materials: materials)
    }

    @Test("The roster searches by name and by student number, case-insensitively")
    func rosterSearch() async {
        let store = InMemoryCourseStore(courses: [course()], enrollments: roster())
        let model = viewModel(store: store)
        await model.load()

        #expect(model.roster.count == 2)

        model.searchText = "sara"
        #expect(model.roster.map(\.studentName) == ["Sara Ali"])

        model.searchText = "202300002"
        #expect(model.roster.map(\.studentName) == ["Omar Noor"])

        model.searchText = "nobody"
        #expect(model.roster.isEmpty)
        #expect(model.searchFoundNothing, "a search that matches nothing is not an empty roster")
    }

    @Test("The cohort KPIs come from the loaded roster")
    func cohortFromRoster() async {
        let store = InMemoryCourseStore(courses: [course()], enrollments: roster())
        let model = viewModel(store: store)

        await model.load()

        #expect(model.cohort.students == 2)
        #expect(model.cohort.averageMastery == 60)
        #expect(model.cohort.atRisk == 1)
    }

    @Test("Publishing links a library material, and it leaves the picker")
    func publish() async {
        let materials = InMemoryMaterialStore(seededWith: [
            Material(id: "m1", title: "Lecture 4", source: .pdf, text: "text"),
            Material(id: "m2", title: "Lecture 5", source: .pdf, text: "text"),
        ])
        let store = InMemoryCourseStore(courses: [course()])
        let model = viewModel(store: store, materials: materials)
        await model.load()

        #expect(model.availableMaterials.count == 2)

        model.publishSelection = "m1"
        let published = await model.publish()

        #expect(published)
        #expect(model.publishedMaterials.count == 1)
        #expect(model.publishedMaterials.first?.title == "Lecture 4")
        #expect(model.availableMaterials.map(\.id) == ["m2"], "a published material is not offered twice")
    }

    @Test("A scheduled publication is not counted as live")
    func scheduledIsNotLive() {
        let soon = Date().addingTimeInterval(60 * 60 * 24)
        let scheduled = PublishedMaterial(materialId: "m1", title: "Lecture 4", publishedAt: soon)
        let live = PublishedMaterial(materialId: "m2", title: "Lecture 5", publishedAt: .now)

        let course = Course(
            name: "IT8108", code: "IT8108", tutorUid: "t1",
            publishedMaterials: [scheduled, live]
        )

        #expect(course.liveMaterialCount() == 1)
        #expect(scheduled.isScheduled())
        #expect(scheduled.isLive() == false)
    }

    @Test("Inviting adds a roster entry — active on a code course, pending on an approval course")
    func inviteRespectsTheMode() async {
        let store = InMemoryCourseStore(courses: [course(mode: .code)])
        let model = viewModel(store: store)
        await model.load()

        model.inviteName = "  Layla  "
        model.inviteNumber = "  202300009  "
        let invited = await model.invite()

        #expect(invited)
        #expect(model.inviteName.isEmpty, "the form is cleared")
        #expect(model.enrollments.first?.studentName == "Layla")
        #expect(model.enrollments.first?.status == .active)

        let approvalStore = InMemoryCourseStore(courses: [course(mode: .approval)])
        let approvalModel = viewModel(store: approvalStore)
        await approvalModel.load()
        approvalModel.inviteName = "Sami"
        approvalModel.inviteNumber = "202300010"
        _ = await approvalModel.invite()

        #expect(approvalModel.enrollments.first?.status == .pending)
    }

    @Test("A blank invite is refused")
    func blankInviteRefused() async {
        let store = InMemoryCourseStore(courses: [course()])
        let model = viewModel(store: store)
        await model.load()

        model.inviteName = "   "
        model.inviteNumber = "1"

        #expect(model.canInvite == false)
        let invited = await model.invite()
        #expect(invited == false)
    }

    @Test("The export gate follows the roster, and the CSV carries the rows")
    func export() async {
        let store = InMemoryCourseStore(courses: [course()], enrollments: roster())
        let model = viewModel(store: store)

        await model.load()

        #expect(model.canExport)
        let csv = model.gradebookCSV()
        #expect(csv.contains("Sara Ali"))
        #expect(csv.contains("Omar Noor"))
    }

    @Test("An empty roster writes nothing to export")
    func emptyRosterCannotExport() async {
        let store = InMemoryCourseStore(courses: [course()])
        let model = viewModel(store: store)

        await model.load()

        #expect(model.canExport == false)
    }

    // MARK: J02 — archive

    // The dashboard's course card carries J02's archive as a SWIPE, which is invisible to
    // VoiceOver. The course hub offers the same action as a named row, and that row is the only
    // caller of `setArchived` — so these three are the tests for the path a tutor actually uses.

    @Test("Archiving writes the flag, and the row flips to Unarchive")
    func archivePersistsAndFlips() async throws {
        let store = InMemoryCourseStore(courses: [course()])
        let model = viewModel(store: store)
        await model.load()

        #expect(model.isArchived == false)
        #expect(model.archiveTitle == L10n.tutorArchive.string)

        await model.setArchived(true)

        #expect(model.isArchived, "the reloaded course carries the flag")
        #expect(
            try await store.course(id: "c1")?.isArchived == true,
            "the flag is written, not just shown"
        )
        #expect(model.unarchiveTitle == L10n.tutorUnarchive.string, "the row now offers the way back")
    }

    @Test("Restoring clears the flag again, and the row flips back")
    func unarchiveClearsTheFlag() async {
        var archived = course()
        archived.isArchived = true
        let store = InMemoryCourseStore(courses: [archived])
        let model = viewModel(store: store)
        await model.load()

        #expect(model.isArchived, "an archived course is still openable — archive is not delete")

        await model.setArchived(false)

        #expect(model.isArchived == false)
    }

    @Test("A failed archive surfaces as an AppError rather than a silent no-op")
    func archiveFailureMaps() async {
        let store = InMemoryCourseStore(courses: [course()])
        let model = viewModel(store: store)
        await model.load()

        await store.forceFailure(.storageFailed)
        await model.setArchived(true)

        #expect(model.error != nil)
    }
}
