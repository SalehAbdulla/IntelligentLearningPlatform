import Foundation
import Testing
@testable import StudyForge

struct FixedProgressSource: TutorStudentProgressSource {
    let progress: TutorStudentProgress?

    func progress(forStudent uid: String) async -> TutorStudentProgress? { progress }
}

@Suite("Tutor student progress and encouragement (F11)")
@MainActor
struct TutorStudentDetailTests {

    private let now = Date(timeIntervalSince1970: 2_000_000_000)

    private var course: Course { Course(id: "c1", name: "Data Structures", code: "CS201", tutorUid: "tutor") }

    private func student(_ name: String, mastery: Int, daysAgo: Double? = 1, status: EnrollmentStatus = .active) -> Enrollment {
        Enrollment(
            courseId: "c1",
            uid: "uid-\(name)",
            studentName: name,
            studentNumber: "ID",
            masteryPercent: mastery,
            lastActiveAt: daysAgo.map { now.addingTimeInterval(-$0 * 86_400) },
            status: status
        )
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    @Test("Without shared progress the radar compares the student with the cohort")
    func fallbackRadar() async {
        let target = student("Mohammed A.", mastery: 54, daysAgo: 7)
        let store = InMemoryCourseStore(courses: [course], enrollments: [target, student("Noor", mastery: 66)])
        let viewModel = TutorStudentDetailViewModel(enrollment: target, course: course, uid: "tutor", store: store, clock: { now })

        await viewModel.load()

        #expect(viewModel.cohortAverage == 60)
        #expect(viewModel.isAtRisk)
        #expect(viewModel.flags == [.lowMastery])
        let axes = viewModel.radarAxes
        #expect(axes.count == 3)
        #expect(axes[0].value == 0.54)
        #expect(axes[1].value == 0.5)
        #expect(abs(axes[2].value - 0.9) < 0.0001)
        #expect(viewModel.topics.isEmpty)
    }

    @Test("Shared topic progress drives the radar")
    func topicRadar() async {
        let progress = TutorStudentProgress(
            topics: [
                TutorTopicProgress(topic: "Balancing", fraction: 0.3),
                TutorTopicProgress(topic: "Complexity", fraction: 0.55),
                TutorTopicProgress(topic: "Traversal", fraction: 0.6)
            ],
            activity: []
        )
        let target = student("Mohammed A.", mastery: 54)
        let viewModel = TutorStudentDetailViewModel(
            enrollment: target,
            course: course,
            uid: "tutor",
            store: InMemoryCourseStore(courses: [course], enrollments: [target]),
            progressSource: FixedProgressSource(progress: progress),
            clock: { now }
        )

        await viewModel.load()

        #expect(viewModel.radarAxes.map(\.label) == ["Balancing", "Complexity", "Traversal"])
        #expect(viewModel.topics.first?.percent == 30)
    }

    @Test("Sending encouragement posts a private announcement and remembers it")
    func sendEncouragement() async throws {
        let target = student("Mohammed Almadhoon", mastery: 54)
        let store = InMemoryCourseStore(courses: [course], enrollments: [target])
        let log = InMemoryTutorEncouragementLog()
        let viewModel = TutorStudentDetailViewModel(enrollment: target, course: course, uid: "tutor", store: store, log: log, clock: { now })
        await viewModel.load()
        #expect(viewModel.message.contains("Mohammed"))

        #expect(await viewModel.sendEncouragement())

        let announcement = try #require(try await store.announcements(courseId: "c1").first)
        #expect(announcement.audience == .individual)
        #expect(!announcement.reachesStudents)
        #expect(announcement.title == TutorStudioCopy.encouragementTitle("Mohammed"))
        #expect(try await log.entries(courseId: "c1", studentUid: target.uid).first?.announcementId == announcement.id)
        #expect(viewModel.encouragements.count == 1)
        #expect(viewModel.didSend)
    }

    @Test("Pending students and empty messages cannot be sent encouragement")
    func cannotSend() async {
        let pending = student("Noor", mastery: 50, status: .pending)
        let viewModel = TutorStudentDetailViewModel(enrollment: pending, course: course, uid: "tutor", store: InMemoryCourseStore(), clock: { now })
        #expect(!viewModel.canSend)

        let active = student("Amal", mastery: 80)
        let other = TutorStudentDetailViewModel(enrollment: active, course: course, uid: "tutor", store: InMemoryCourseStore(), clock: { now })
        other.message = "   "
        #expect(!other.canSend)
        #expect(!(await other.sendEncouragement()))
    }

    @Test("The file log keeps encouragement between launches")
    func fileLog() async throws {
        let directory = temporaryDirectory()
        let entry = TutorEncouragement(courseId: "c1", studentUid: "s1", announcementId: "a1", message: "Keep going", sentAt: now)
        try await FileTutorEncouragementLog(directory: directory).record(entry)

        let reopened = FileTutorEncouragementLog(directory: directory)
        #expect(try await reopened.entries(courseId: "c1", studentUid: "s1") == [entry])
        #expect(try await reopened.entries(courseId: "c1", studentUid: "other").isEmpty)
    }

    @Test("Local progress is only shared for the signed-in student")
    func localProgressOwnerOnly() async {
        let question = QuizQuestion(
            id: "q1",
            stem: "Q",
            options: ["A", "B", "C", "D"],
            correctOptionIndex: 0,
            explanation: "",
            topic: "Traversal",
            provenance: AIProvenance(materialId: "m", pageNumbers: [1], confidence: .high)
        )
        let quiz = Quiz(
            title: "Trees quiz 1",
            questionType: .multipleChoice,
            questions: [question],
            attempts: [QuizAttempt(id: "a1", responses: [QuizResponse(questionId: "q1", selectedOptionIndex: 0, isCorrect: true)], createdAt: now)]
        )
        let review = FlashcardReviewEntry(deckId: "d", cardId: "c", rating: .hard, intervalDays: 1, tags: ["balancing"], reviewedAt: now)
        let source = LocalStudentProgressSource(
            ownerUid: "me",
            quizzes: InMemoryQuizStore(seededWith: [quiz]),
            quizLog: InMemoryQuizAttemptLog(),
            reviewLog: InMemoryFlashcardReviewLog(seededWith: [review])
        )

        #expect(await source.progress(forStudent: "someone-else") == nil)

        let progress = await source.progress(forStudent: "me")
        #expect(progress?.topics.map(\.topic) == ["balancing", "Traversal"])
        #expect(progress?.activity.map(\.kind).contains(.quiz) == true)
        #expect(progress?.activity.map(\.kind).contains(.flashcards) == true)
    }
}
