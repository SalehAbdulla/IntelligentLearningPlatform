import Foundation
import Testing
@testable import StudyForge

@Suite("Tutor home, roster and publishing (F11)")
@MainActor
struct TutorCourseScreensTests {

    private let now = Date(timeIntervalSince1970: 2_000_000_000)

    private func course(_ id: String, mode: EnrolmentMode = .code, archived: Bool = false) -> Course {
        Course(id: id, name: "Course \(id)", code: id.uppercased(), tutorUid: "tutor", enrolmentMode: mode, isArchived: archived, updatedAt: now)
    }

    private func student(_ name: String, course: String = "c1", mastery: Int = 75, daysAgo: Double? = 1, status: EnrollmentStatus = .active) -> Enrollment {
        Enrollment(
            courseId: course,
            uid: "uid-\(name)",
            studentName: name,
            studentNumber: "ID-\(name)",
            masteryPercent: mastery,
            lastActiveAt: daysAgo.map { now.addingTimeInterval(-$0 * 86_400) },
            status: status
        )
    }

    private var lecture: String {
        PageMarker.forPage(1) + String(repeating: "A graph is a set of vertices joined by edges. Breadth-first search explores level by level. ", count: 6)
    }

    private func router() -> AIRouter {
        AIRouter(
            providers: [
                .onDevice: MockProvider(tier: .onDevice, latency: .zero),
                .firebaseAI: MockProvider(tier: .firebaseAI, latency: .zero)
            ],
            governor: AICostGovernor()
        )
    }

    @Test("The home sums active courses, pending reviews and at-risk students")
    func homeTotals() async {
        let store = InMemoryCourseStore(
            courses: [course("c1"), course("c2"), course("old", archived: true)],
            enrollments: [student("A"), student("B", mastery: 40), student("C", course: "c2", daysAgo: 0.5), student("D", course: "old", mastery: 10)],
            reviewItems: [
                ReviewItem(courseId: "c1", materialId: "m", materialTitle: "M", kind: .quiz, draft: "d", sourceSnippet: "s", confidence: 0.6),
                ReviewItem(courseId: "old", materialId: "m", materialTitle: "M", kind: .quiz, draft: "d", sourceSnippet: "s", confidence: 0.6)
            ]
        )
        let viewModel = TutorStudioHomeViewModel(uid: "tutor", store: store, clock: { now })

        await viewModel.load()

        #expect(viewModel.activeCourses.count == 2)
        #expect(viewModel.cohort.students == 3)
        #expect(viewModel.atRiskCount == 1)
        #expect(viewModel.pendingReviewCount == 1)
        #expect(viewModel.studentCount(for: course("c1")) == 2)
        viewModel.showsArchived = true
        #expect(viewModel.visibleCourses.map(\.id) == ["old"])
    }

    @Test("Archiving a course moves it out of the active list")
    func archive() async {
        let store = InMemoryCourseStore(courses: [course("c1")])
        let viewModel = TutorStudioHomeViewModel(uid: "tutor", store: store, clock: { now })
        await viewModel.load()

        await viewModel.setArchived(viewModel.courses[0], archived: true)

        #expect(viewModel.activeCourses.isEmpty)
        #expect(viewModel.archivedCourses.count == 1)
    }

    @Test("Without a signed-in tutor the home is empty rather than failing")
    func noTutor() async {
        let viewModel = TutorStudioHomeViewModel(uid: "", store: InMemoryCourseStore(courses: [course("c1")]))
        await viewModel.load()
        #expect(viewModel.isEmpty)
    }

    @Test("Inviting a student enrols them and refuses a duplicate ID")
    func invite() async throws {
        let store = InMemoryCourseStore(courses: [course("c1")])
        let viewModel = TutorCourseHubViewModel(uid: "tutor", courseId: "c1", store: store, clock: { now })
        await viewModel.load()

        viewModel.inviteName = "Noor Ali"
        viewModel.inviteNumber = "202305"
        #expect(await viewModel.invite())
        #expect(viewModel.enrollments.map(\.studentName) == ["Noor Ali"])
        #expect(try await store.course(id: "c1")?.enrolledUids == ["invite-202305"])

        viewModel.inviteName = "Someone"
        viewModel.inviteNumber = "202305"
        #expect(!(await viewModel.invite()))
        #expect(viewModel.inviteMessage == TutorStudioCopy.inviteDuplicate("202305"))
    }

    @Test("Approval courses add invited students as pending until approved")
    func approvalFlow() async {
        let store = InMemoryCourseStore(courses: [course("c1", mode: .approval)])
        let viewModel = TutorCourseHubViewModel(uid: "tutor", courseId: "c1", store: store, clock: { now })
        await viewModel.load()
        viewModel.inviteName = "Noor"
        viewModel.inviteNumber = "1"
        _ = await viewModel.invite()

        #expect(viewModel.count(.pending) == 1)
        await viewModel.approve(viewModel.enrollments[0])
        #expect(viewModel.count(.pending) == 0)
        #expect(viewModel.enrollments[0].status == .active)
    }

    @Test("Removing a student hides them and takes them off the course")
    func remove() async throws {
        let store = InMemoryCourseStore(
            courses: [Course(id: "c1", name: "C", code: "C1", tutorUid: "tutor", enrolledUids: ["uid-A"])],
            enrollments: [student("A")]
        )
        let viewModel = TutorCourseHubViewModel(uid: "tutor", courseId: "c1", store: store, clock: { now })
        await viewModel.load()

        await viewModel.remove(viewModel.enrollments[0])

        #expect(viewModel.roster.isEmpty)
        #expect(!viewModel.hasStudents)
        #expect(try await store.course(id: "c1")?.enrolledUids.isEmpty == true)
    }

    @Test("Roster filters and search work together")
    func rosterFilters() async {
        let store = InMemoryCourseStore(courses: [course("c1")], enrollments: [student("Amal"), student("Badr", mastery: 30), student("Bilal", mastery: 20)])
        let viewModel = TutorCourseHubViewModel(uid: "tutor", courseId: "c1", store: store, clock: { now })
        await viewModel.load()

        viewModel.filter = .atRisk
        viewModel.query = "bil"
        #expect(viewModel.roster.map(\.studentName) == ["Bilal"])
        viewModel.query = "amal"
        #expect(viewModel.searchFoundNothing)
    }

    @Test("Publishing now shares the material, posts an announcement and drafts AI content")
    func publishNow() async throws {
        let material = Material(title: "Lecture 5 - Graphs", source: .text, text: lecture)
        let store = InMemoryCourseStore(courses: [course("c1"), course("c2")])
        let viewModel = TutorPublishViewModel(
            uid: "tutor",
            course: course("c1"),
            store: store,
            materials: InMemoryMaterialStore(seededWith: [material]),
            router: router(),
            clock: { now }
        )
        await viewModel.load()
        viewModel.selectedMaterialId = material.id
        viewModel.selectAllTargets()

        await viewModel.publish()

        let result = try #require(viewModel.result)
        #expect(result.courses == 2)
        #expect(result.drafted == 6)
        for id in ["c1", "c2"] {
            #expect(try await store.course(id: id)?.publishedMaterials.first?.materialId == material.id)
            #expect(try await store.announcements(courseId: id).first?.isSent == true)
            #expect(try await store.reviewItems(courseId: id).count == 3)
        }
    }

    @Test("Scheduling keeps the material hidden until the chosen time")
    func schedule() async throws {
        let material = Material(title: "Lecture 6", source: .text, text: lecture)
        let store = InMemoryCourseStore(courses: [course("c1")])
        let viewModel = TutorPublishViewModel(
            uid: "tutor",
            course: course("c1"),
            store: store,
            materials: InMemoryMaterialStore(seededWith: [material]),
            router: router(),
            clock: { now }
        )
        await viewModel.load()
        viewModel.selectedMaterialId = material.id
        viewModel.schedules = true
        viewModel.publishDate = now.addingTimeInterval(86_400)
        viewModel.draftsAIContent = false

        await viewModel.publish()

        let published = try #require(try await store.course(id: "c1")?.publishedMaterials.first)
        #expect(published.isScheduled(at: now))
        #expect(try await store.announcements(courseId: "c1").first?.isScheduled == true)
        #expect(try await store.reviewItems(courseId: "c1").isEmpty)
        #expect(viewModel.result?.isScheduled == true)
    }

    @Test("Publishing needs a material, a target and at least one draft kind")
    func publishGuards() async {
        let material = Material(title: "Lecture", source: .text, text: lecture)
        let viewModel = TutorPublishViewModel(
            uid: "tutor",
            course: course("c1"),
            store: InMemoryCourseStore(courses: [course("c1")]),
            materials: InMemoryMaterialStore(seededWith: [material]),
            router: router(),
            clock: { now }
        )
        await viewModel.load()
        #expect(!viewModel.canPublish)

        viewModel.selectedMaterialId = material.id
        #expect(viewModel.canPublish)

        for kind in ReviewKind.allCases { viewModel.toggleKind(kind) }
        #expect(!viewModel.canPublish)
        viewModel.draftsAIContent = false
        #expect(viewModel.canPublish)

        viewModel.toggleTarget("c1")
        #expect(!viewModel.canPublish)
    }
}
