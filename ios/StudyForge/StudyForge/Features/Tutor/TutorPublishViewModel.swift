import Foundation

struct TutorPublishResult: Equatable {
    let courses: Int
    let drafted: Int
    let failures: Int
    let isScheduled: Bool
}

@MainActor
@Observable
final class TutorPublishViewModel {

    static let defaultLeadSeconds: TimeInterval = 3_600

    let course: Course
    private(set) var materials: [Material] = []
    private(set) var courses: [Course] = []
    private(set) var hasLoaded = false
    private(set) var isPublishing = false
    private(set) var error: AppError? = nil
    private(set) var result: TutorPublishResult? = nil

    var selectedMaterialId: String?
    var schedules = false
    var publishDate: Date
    var targetIds: Set<String>
    var notifies = true
    var draftsAIContent = true
    var draftKinds: Set<ReviewKind> = Set(ReviewKind.allCases)

    private let uid: String
    private let store: any CourseStore
    private let materialStore: any MaterialStore
    private let drafter: TutorReviewDrafter
    private let clock: () -> Date

    init(
        uid: String,
        course: Course,
        store: any CourseStore,
        materials: any MaterialStore,
        router: AIRouter,
        selectedMaterialId: String? = nil,
        clock: @escaping () -> Date = { .now }
    ) {
        self.uid = uid
        self.course = course
        self.store = store
        self.materialStore = materials
        self.drafter = TutorReviewDrafter(router: router)
        self.selectedMaterialId = selectedMaterialId
        self.clock = clock
        self.publishDate = clock().addingTimeInterval(Self.defaultLeadSeconds)
        self.targetIds = [course.id]
    }

    var selectedMaterial: Material? {
        materials.first { $0.id == selectedMaterialId }
    }

    var targetCourses: [Course] {
        courses.isEmpty ? [course] : courses
    }

    var allTargetsSelected: Bool {
        Set(targetCourses.map(\.id)).isSubset(of: targetIds)
    }

    var canPublish: Bool {
        selectedMaterial != nil
            && !targetIds.isEmpty
            && !isPublishing
            && (!draftsAIContent || !draftKinds.isEmpty)
    }

    var visibilityText: String {
        schedules
            ? TutorStudioCopy.visibleFrom(publishDate.formatted(date: .abbreviated, time: .shortened))
            : TutorStudioCopy.draftNotVisible
    }

    func isPublished(_ material: Material) -> Bool {
        course.publishedMaterials.contains { $0.materialId == material.id }
    }

    func load() async {
        do {
            materials = try await materialStore.all()
            courses = try await store.courses(tutorUid: uid).filter { !$0.isArchived }
            if !courses.contains(where: { $0.id == course.id }) {
                courses.insert(course, at: 0)
            }
            error = nil
        } catch {
            self.error = AppError.from(error)
        }
        hasLoaded = true
    }

    func toggleTarget(_ id: String) {
        if targetIds.contains(id) {
            targetIds.remove(id)
        } else {
            targetIds.insert(id)
        }
    }

    func selectAllTargets() {
        targetIds = allTargetsSelected ? [course.id] : Set(targetCourses.map(\.id))
    }

    func toggleKind(_ kind: ReviewKind) {
        if draftKinds.contains(kind) {
            draftKinds.remove(kind)
        } else {
            draftKinds.insert(kind)
        }
    }

    func publish() async {
        guard canPublish, let material = selectedMaterial else { return }
        isPublishing = true
        error = nil
        defer { isPublishing = false }

        let now = clock()
        let date = schedules ? max(publishDate, now) : now
        let targets = targetCourses.filter { targetIds.contains($0.id) }

        var drafted: [ReviewItem] = []
        var failures = 0
        if draftsAIContent, let first = targets.first {
            let outcome = await drafter.drafts(for: material, courseId: first.id, kinds: draftKinds, now: now)
            drafted = outcome.items
            failures = outcome.failures
        }

        var draftedCount = 0
        do {
            for target in targets {
                guard var stored = try await store.course(id: target.id) else { continue }
                stored.publish(
                    PublishedMaterial(materialId: material.id, title: material.title, publishedAt: date, notifiesStudents: notifies),
                    at: now
                )
                try await store.upsert(stored)

                if notifies {
                    try await store.upsert(Announcement(
                        courseId: stored.id,
                        authorUid: uid,
                        title: TutorStudioCopy.newMaterialTitle(material.title),
                        body: TutorStudioCopy.newMaterialBody(material.title, stored.name),
                        scheduledFor: schedules ? date : nil,
                        sentAt: schedules ? nil : now,
                        createdAt: now
                    ))
                }

                for item in drafted {
                    try await store.upsert(Self.copy(item, toCourse: stored.id))
                    draftedCount += 1
                }
            }
            result = TutorPublishResult(courses: targets.count, drafted: draftedCount, failures: failures, isScheduled: schedules)
        } catch {
            self.error = AppError.from(error)
        }
    }

    static func copy(_ item: ReviewItem, toCourse courseId: String) -> ReviewItem {
        ReviewItem(
            courseId: courseId,
            materialId: item.materialId,
            materialTitle: item.materialTitle,
            kind: item.kind,
            draft: item.draft,
            sourceSnippet: item.sourceSnippet,
            confidence: item.confidence,
            createdAt: item.createdAt
        )
    }
}
