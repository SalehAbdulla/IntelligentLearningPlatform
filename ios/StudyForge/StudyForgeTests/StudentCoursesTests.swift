import Foundation
import Testing
@testable import StudyForge

@Suite("Student courses: joining and studying tutor content (F11)")
@MainActor
struct StudentCoursesTests {

    private let now = Date(timeIntervalSince1970: 2_000_000_000)

    private func course(_ id: String = "c1", code: String = "CS201", mode: EnrolmentMode = .code, archived: Bool = false) -> Course {
        Course(id: id, name: "Data Structures", code: code, tutorUid: "tutor", enrolmentMode: mode, isArchived: archived)
    }

    private func model(store: InMemoryCourseStore, courses: [Course]) -> StudentCoursesViewModel {
        StudentCoursesViewModel(
            uid: "student",
            studentName: "Mohammed A.",
            studentNumber: "202401702",
            store: store,
            directory: InMemoryCourseDirectory(seededWith: courses),
            clock: { now }
        )
    }

    @Test("Joining with a code enrols the student and lists the course")
    func joinWithCode() async throws {
        let store = InMemoryCourseStore(courses: [course()])
        let viewModel = model(store: store, courses: [course()])
        await viewModel.load()
        #expect(viewModel.isEmpty)

        viewModel.joinCode = "cs 201"
        #expect(await viewModel.join())

        #expect(viewModel.courses.map(\.course.id) == ["c1"])
        #expect(viewModel.joinMessage == TutorStudioCopy.joinDone("CS201"))
        let enrollment = try #require(try await store.enrollments(courseId: "c1").first)
        #expect(enrollment.status == .active)
        #expect(enrollment.studentNumber == "202401702")
        #expect(try await store.course(id: "c1")?.enrolledUids == ["student"])
    }

    @Test("Approval courses leave the student pending")
    func joinNeedsApproval() async {
        let approval = course(mode: .approval)
        let store = InMemoryCourseStore(courses: [approval])
        let viewModel = model(store: store, courses: [approval])

        viewModel.joinCode = "CS201"
        _ = await viewModel.join()

        #expect(viewModel.courses.first?.isPending == true)
        #expect(viewModel.joinMessage == TutorStudioCopy.joinPending("CS201"))
    }

    @Test("Unknown, archived and repeated codes are refused with a reason")
    func refusals() async {
        let archived = course("c2", code: "OLD1", archived: true)
        let store = InMemoryCourseStore(courses: [course(), archived])
        let viewModel = model(store: store, courses: [course(), archived])

        viewModel.joinCode = "NOPE1"
        #expect(!(await viewModel.join()))
        #expect(viewModel.joinMessage == TutorStudioCopy.joinNotFound("NOPE1"))

        viewModel.joinCode = "OLD1"
        #expect(!(await viewModel.join()))
        #expect(viewModel.joinMessage == TutorStudioCopy.joinArchived("OLD1"))

        viewModel.joinCode = "CS201"
        _ = await viewModel.join()
        viewModel.joinCode = "CS201"
        #expect(!(await viewModel.join()))
        #expect(viewModel.joinMessage == TutorStudioCopy.joinAlready("CS201"))
    }

    @Test("A removed student can join again")
    func rejoinAfterRemoval() async throws {
        let removed = Enrollment(courseId: "c1", uid: "student", studentName: "M", studentNumber: "1", status: .removed)
        let store = InMemoryCourseStore(courses: [course()], enrollments: [removed])
        let viewModel = model(store: store, courses: [course()])

        viewModel.joinCode = "CS201"
        #expect(await viewModel.join())
        #expect(try await store.enrollments(courseId: "c1").filter { $0.uid == "student" }.map(\.status) == [.active])
    }

    private func courseModel(
        store: InMemoryCourseStore,
        published: [PublishedMaterial] = [],
        status: EnrollmentStatus = .active,
        decks: InMemoryDeckStore = InMemoryDeckStore(),
        quizzes: InMemoryQuizStore = InMemoryQuizStore(),
        log: InMemoryTutorEncouragementLog = InMemoryTutorEncouragementLog(),
        materials: InMemoryMaterialStore = InMemoryMaterialStore()
    ) -> StudentCourseViewModel {
        var stored = course()
        stored.publishedMaterials = published
        let enrollment = Enrollment(courseId: "c1", uid: "student", studentName: "M", studentNumber: "1", status: status)
        return StudentCourseViewModel(
            joined: JoinedCourse(course: stored, enrollment: enrollment),
            store: store,
            materials: materials,
            decks: decks,
            quizzes: quizzes,
            log: log,
            clock: { now }
        )
    }

    private func item(_ kind: ReviewKind, draft: String, status: ReviewStatus) -> ReviewItem {
        ReviewItem(courseId: "c1", materialId: "m1", materialTitle: "Graphs", kind: kind, draft: draft, sourceSnippet: "s", confidence: 0.9, status: status)
    }

    @Test("Students only see live materials, sent course announcements and approved content")
    func visibility() async {
        var stored = course()
        stored.publishedMaterials = [
            PublishedMaterial(materialId: "m1", title: "Live", publishedAt: now.addingTimeInterval(-60)),
            PublishedMaterial(materialId: "m2", title: "Later", publishedAt: now.addingTimeInterval(3_600))
        ]
        let store = InMemoryCourseStore(
            courses: [stored],
            reviewItems: [
                item(.summary, draft: "Approved summary", status: .approved),
                item(.quiz, draft: "Pending quiz", status: .pending),
                item(.flashcards, draft: "Rejected", status: .rejected)
            ],
            announcements: [
                Announcement(courseId: "c1", authorUid: "tutor", title: "Sent", body: "b", sentAt: now.addingTimeInterval(-10)),
                Announcement(courseId: "c1", authorUid: "tutor", title: "Future", body: "b", scheduledFor: now.addingTimeInterval(600)),
                Announcement(courseId: "c1", authorUid: "tutor", audience: .individual, title: "Private", body: "b", sentAt: now)
            ]
        )
        let viewModel = courseModel(store: store)

        await viewModel.load()

        #expect(viewModel.liveMaterials.map(\.title) == ["Live"])
        #expect(viewModel.upcomingCount == 1)
        #expect(viewModel.announcements.map(\.title) == ["Sent"])
        #expect(viewModel.approvedItems.map(\.draft) == ["Approved summary"])
    }

    @Test("Encouragement from the tutor appears for that student only")
    func messages() async throws {
        let log = InMemoryTutorEncouragementLog(seededWith: [
            TutorEncouragement(courseId: "c1", studentUid: "student", announcementId: "a1", message: "Keep going"),
            TutorEncouragement(courseId: "c1", studentUid: "someone", announcementId: "a2", message: "Not yours")
        ])
        let viewModel = courseModel(store: InMemoryCourseStore(courses: [course()]), log: log)

        await viewModel.load()

        #expect(viewModel.messages.map(\.message) == ["Keep going"])
    }

    @Test("Approved cards become a deck the student can review")
    func addCards() async throws {
        let decks = InMemoryDeckStore()
        let cards = item(.flashcards, draft: "Q: What is BFS?\nA: Level by level.\n\nQ: What is DFS?\nA: Deep first.", status: .approved)
        let viewModel = courseModel(store: InMemoryCourseStore(courses: [course()], reviewItems: [cards]), decks: decks)
        await viewModel.load()

        await viewModel.addToDecks(viewModel.cardSets[0])
        await viewModel.addToDecks(viewModel.cardSets[0])

        let stored = try await decks.all()
        #expect(stored.count == 1)
        #expect(stored.first?.cards.map(\.front) == ["What is BFS?", "What is DFS?"])
        #expect(stored.first?.cards.allSatisfy { !$0.aiDrafted && $0.tags == ["cs201"] } == true)
        #expect(viewModel.notice == TutorStudioCopy.addedToDecks(2))
    }

    @Test("An approved quiz becomes a short-answer quiz the student can take once")
    func makeQuiz() async throws {
        let quizzes = InMemoryQuizStore()
        let quizItem = item(.quiz, draft: "1. Which search goes level by level?\n✓ BFS", status: .approved)
        let viewModel = courseModel(store: InMemoryCourseStore(courses: [course()], reviewItems: [quizItem]), quizzes: quizzes)
        await viewModel.load()

        let quiz = try #require(await viewModel.quiz(for: viewModel.quizItems[0]))
        let again = await viewModel.quiz(for: viewModel.quizItems[0])

        #expect(again?.id == quiz.id)
        #expect(quiz.questions.map(\.options) == [["BFS"]])
        #expect(quiz.questions.allSatisfy { QuizQuestionKind($0) == .shortAnswer })
        #expect(try await quizzes.all().count == 1)
    }

    @Test("A pending student sees no course content and the tutor's material opens when on the device")
    func pendingAndMaterial() async {
        let material = Material(id: "m1", title: "Graphs", source: .text, text: "Graph text")
        let viewModel = courseModel(
            store: InMemoryCourseStore(courses: [course()]),
            published: [PublishedMaterial(materialId: "m1", title: "Graphs", publishedAt: now.addingTimeInterval(-1))],
            status: .pending,
            materials: InMemoryMaterialStore(seededWith: [material])
        )

        #expect(viewModel.isPending)
        #expect(await viewModel.material(for: viewModel.liveMaterials[0])?.text == "Graph text")
    }
}
