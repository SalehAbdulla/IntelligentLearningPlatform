import Foundation

enum TutorQueueFilter: String, CaseIterable, Identifiable, Sendable {
    case pending
    case lowConfidence
    case all

    var id: String { rawValue }
}

@MainActor
@Observable
final class TutorReviewQueueViewModel {

    let courseIds: [String]
    private(set) var items: [ReviewItem] = []
    private(set) var hasLoaded = false
    private(set) var isBulkApproving = false
    private(set) var error: AppError? = nil
    var filter: TutorQueueFilter = .pending

    private let store: any CourseStore
    private let clock: () -> Date

    init(courseIds: [String], store: any CourseStore, clock: @escaping () -> Date = { .now }) {
        self.courseIds = courseIds
        self.store = store
        self.clock = clock
    }

    var pendingItems: [ReviewItem] { items.filter { $0.status.isPending } }
    var pendingCount: Int { pendingItems.count }
    var lowConfidenceCount: Int { pendingItems.filter(\.isLowConfidence).count }

    var visibleItems: [ReviewItem] {
        switch filter {
        case .pending: pendingItems
        case .lowConfidence: pendingItems.filter(\.isLowConfidence).sorted { $0.confidence < $1.confidence }
        case .all: items
        }
    }

    var bulkCandidates: [ReviewItem] { pendingItems.filter { !$0.isLowConfidence } }
    var canBulkApprove: Bool { !bulkCandidates.isEmpty && !isBulkApproving }
    var isEmpty: Bool { hasLoaded && visibleItems.isEmpty }

    func count(_ filter: TutorQueueFilter) -> Int {
        switch filter {
        case .pending: pendingCount
        case .lowConfidence: lowConfidenceCount
        case .all: items.count
        }
    }

    func load() async {
        do {
            var loaded: [ReviewItem] = []
            for id in courseIds {
                loaded += try await store.reviewItems(courseId: id)
            }
            items = loaded.sorted { $0.createdAt > $1.createdAt }
            error = nil
        } catch {
            self.error = AppError.from(error)
        }
        hasLoaded = true
    }

    func approve(_ item: ReviewItem) async {
        await decide(item) { try $0.decide(.approve, at: $1) }
    }

    func reject(_ item: ReviewItem, reason: TutorRejectReason, note: String) async -> Bool {
        guard reason.canSubmit(note: note) else { return false }
        let text = reason.reasonText(note: note)
        return await decide(item) { try $0.decide(.reject, reason: text, at: $1) }
    }

    func approveAll() async {
        guard canBulkApprove else { return }
        isBulkApproving = true
        defer { isBulkApproving = false }
        for item in bulkCandidates {
            await decide(item) { try $0.decide(.approve, at: $1) }
        }
    }

    @discardableResult
    private func decide(_ item: ReviewItem, _ change: (inout ReviewItem, Date) throws -> Void) async -> Bool {
        var updated = item
        do {
            try change(&updated, clock())
            try await store.upsert(updated)
            if let index = items.firstIndex(where: { $0.id == updated.id }) {
                items[index] = updated
            }
            return true
        } catch let error as ReviewError {
            self.error = error.asAppError
            return false
        } catch {
            self.error = AppError.from(error)
            return false
        }
    }

    func replace(_ item: ReviewItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        }
    }
}
