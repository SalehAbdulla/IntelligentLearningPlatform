import Foundation

@MainActor
@Observable
final class StudentCourseViewModel {

    private(set) var course: Course
    private(set) var enrollment: Enrollment
    private(set) var announcements: [Announcement] = []
    private(set) var approvedItems: [ReviewItem] = []
    private(set) var messages: [TutorEncouragement] = []
    private(set) var addedDeckItemIds: Set<String> = []
    private(set) var quizzesByItem: [String: Quiz] = [:]
    private(set) var busyItemId: String? = nil
    private(set) var hasLoaded = false
    private(set) var error: AppError? = nil
    private(set) var notice: String? = nil

    private let store: any CourseStore
    private let materials: any MaterialStore
    private let decks: any DeckStore
    private let quizzes: any QuizStore
    private let log: any TutorEncouragementLog
    private let clock: () -> Date

    init(
        joined: JoinedCourse,
        store: any CourseStore,
        materials: any MaterialStore,
        decks: any DeckStore,
        quizzes: any QuizStore,
        log: any TutorEncouragementLog = InMemoryTutorEncouragementLog(),
        clock: @escaping () -> Date = { .now }
    ) {
        self.course = joined.course
        self.enrollment = joined.enrollment
        self.store = store
        self.materials = materials
        self.decks = decks
        self.quizzes = quizzes
        self.log = log
        self.clock = clock
    }

    var isPending: Bool { enrollment.status == .pending }

    var liveMaterials: [PublishedMaterial] {
        let now = clock()
        return course.publishedMaterials.filter { $0.isLive(at: now) }.sorted { $0.publishedAt > $1.publishedAt }
    }

    var upcomingCount: Int {
        let now = clock()
        return course.publishedMaterials.filter { $0.isScheduled(at: now) }.count
    }

    var summaries: [ReviewItem] { approvedItems.filter { $0.kind == .summary } }
    var cardSets: [ReviewItem] { approvedItems.filter { $0.kind == .flashcards } }
    var quizItems: [ReviewItem] { approvedItems.filter { $0.kind == .quiz } }

    var hasContent: Bool {
        !liveMaterials.isEmpty || !announcements.isEmpty || !approvedItems.isEmpty || !messages.isEmpty
    }

    func load() async {
        do {
            if let fresh = try await store.course(id: course.id) {
                course = fresh
            }
            if let fresh = try await store.enrollments(courseId: course.id).first(where: { $0.uid == enrollment.uid }) {
                enrollment = fresh
            }
            let now = clock()
            announcements = try await store.announcements(courseId: course.id)
                .filter { $0.reachesStudents && ($0.isSent || ($0.scheduledFor.map { $0 <= now } ?? false)) }
                .sorted { ($0.sentAt ?? $0.scheduledFor ?? $0.createdAt) > ($1.sentAt ?? $1.scheduledFor ?? $1.createdAt) }
            approvedItems = try await store.reviewItems(courseId: course.id)
                .filter { $0.publishedText != nil }
                .sorted { ($0.decidedAt ?? $0.createdAt) > ($1.decidedAt ?? $1.createdAt) }
            messages = try await log.entries(courseId: course.id, studentUid: enrollment.uid)
            error = nil
        } catch {
            self.error = AppError.from(error)
        }
        hasLoaded = true
    }

    func text(for item: ReviewItem) -> String {
        item.publishedText ?? item.draft
    }

    func material(for published: PublishedMaterial) async -> Material? {
        try? await materials.material(id: published.materialId)
    }

    func cardCount(for item: ReviewItem) -> Int {
        TutorContentParser.cards(from: text(for: item)).count
    }

    func questionCount(for item: ReviewItem) -> Int {
        TutorContentParser.questions(from: text(for: item)).count
    }

    func addToDecks(_ item: ReviewItem) async {
        guard item.kind == .flashcards, !addedDeckItemIds.contains(item.id), busyItemId == nil else { return }
        let parsed = TutorContentParser.cards(from: text(for: item))
        guard !parsed.isEmpty else {
            notice = TutorStudioCopy.nothingToAdd
            return
        }
        busyItemId = item.id
        defer { busyItemId = nil }

        let provenance = AIProvenance(materialId: item.materialId, pageNumbers: [], confidence: .high)
        let tag = course.code.isEmpty ? course.name : course.code
        let deck = Deck(
            title: TutorStudioCopy.courseDeckTitle(item.materialTitle),
            materialId: item.materialId,
            cards: parsed.map {
                Flashcard(front: $0.front, back: $0.back, tags: [tag.lowercased()], provenance: provenance, aiDrafted: false)
            },
            createdAt: clock(),
            updatedAt: clock()
        )
        do {
            try await decks.add(deck)
            addedDeckItemIds.insert(item.id)
            notice = TutorStudioCopy.addedToDecks(parsed.count)
        } catch {
            self.error = AppError.from(error)
        }
    }

    func quiz(for item: ReviewItem) async -> Quiz? {
        guard item.kind == .quiz else { return nil }
        if let existing = quizzesByItem[item.id] { return existing }
        let parsed = TutorContentParser.questions(from: text(for: item))
        guard !parsed.isEmpty else {
            notice = TutorStudioCopy.nothingToAdd
            return nil
        }
        busyItemId = item.id
        defer { busyItemId = nil }

        let provenance = AIProvenance(materialId: item.materialId, pageNumbers: [], confidence: .high)
        let topic = course.code.isEmpty ? course.name : course.code
        let quiz = Quiz(
            title: TutorStudioCopy.courseQuizTitle(item.materialTitle),
            materialId: item.materialId,
            questionType: .shortAnswer,
            questions: parsed.map {
                QuizQuestion(stem: $0.stem, options: [$0.answer], correctOptionIndex: 0, explanation: "", topic: topic, provenance: provenance)
            },
            createdAt: clock()
        )
        do {
            try await quizzes.add(quiz)
            quizzesByItem[item.id] = quiz
            return quiz
        } catch {
            self.error = AppError.from(error)
            return nil
        }
    }

    func clearNotice() {
        notice = nil
    }
}
