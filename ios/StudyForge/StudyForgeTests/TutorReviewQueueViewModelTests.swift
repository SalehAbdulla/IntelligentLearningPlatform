import Foundation
import Testing
@testable import StudyForge

@Suite("Tutor review queue and reject reasons (F11)")
@MainActor
struct TutorReviewQueueViewModelTests {

    private func item(_ id: String, course: String = "c1", confidence: Double, status: ReviewStatus = .pending, at seconds: TimeInterval = 0) -> ReviewItem {
        ReviewItem(
            id: id,
            courseId: course,
            materialId: "m",
            materialTitle: "Graphs",
            kind: .summary,
            draft: "Draft \(id)",
            sourceSnippet: "Source",
            confidence: confidence,
            status: status,
            createdAt: Date(timeIntervalSince1970: seconds)
        )
    }

    private func model(_ items: [ReviewItem], courses: [String] = ["c1", "c2"]) -> (TutorReviewQueueViewModel, InMemoryCourseStore) {
        let store = InMemoryCourseStore(reviewItems: items)
        return (TutorReviewQueueViewModel(courseIds: courses, store: store), store)
    }

    @Test("The queue gathers items from every course, newest first")
    func gathersCourses() async {
        let (viewModel, _) = model([item("a", confidence: 0.9, at: 1), item("b", course: "c2", confidence: 0.6, at: 2), item("x", course: "other", confidence: 0.9)])

        await viewModel.load()

        #expect(viewModel.items.map(\.id) == ["b", "a"])
        #expect(viewModel.pendingCount == 2)
        #expect(viewModel.lowConfidenceCount == 1)
    }

    @Test("Filters show pending, low confidence first by score, or everything")
    func filters() async {
        let (viewModel, _) = model([
            item("a", confidence: 0.9, at: 1),
            item("b", confidence: 0.64, at: 2),
            item("c", confidence: 0.58, at: 3),
            item("d", confidence: 0.9, status: .approved, at: 4)
        ])
        await viewModel.load()

        #expect(viewModel.visibleItems.map(\.id) == ["c", "b", "a"])
        viewModel.filter = .lowConfidence
        #expect(viewModel.visibleItems.map(\.id) == ["c", "b"])
        viewModel.filter = .all
        #expect(viewModel.visibleItems.count == 4)
    }

    @Test("Bulk approve only approves confident items")
    func bulkApprove() async throws {
        let (viewModel, store) = model([item("a", confidence: 0.9), item("b", confidence: 0.81), item("c", confidence: 0.5)])
        await viewModel.load()
        #expect(viewModel.bulkCandidates.map(\.id).sorted() == ["a", "b"])

        await viewModel.approveAll()

        let stored = try await store.reviewItems(courseId: "c1")
        #expect(stored.filter { $0.status == .approved }.count == 2)
        #expect(stored.first { $0.id == "c" }?.status == .pending)
        #expect(!viewModel.canBulkApprove)
    }

    @Test("Rejecting with a reason records it and takes the item out of the queue")
    func rejectWithReason() async throws {
        let (viewModel, store) = model([item("a", confidence: 0.6)])
        await viewModel.load()

        let rejected = await viewModel.reject(viewModel.items[0], reason: .unsupported, note: "Wrong page")

        #expect(rejected)
        let stored = try #require(try await store.reviewItems(courseId: "c1").first)
        #expect(stored.status == .rejected)
        #expect(stored.reason == TutorStudioCopy.reasonWithNote(TutorRejectReason.unsupported.title, "Wrong page"))
        #expect(viewModel.pendingCount == 0)
    }

    @Test("Other needs a note before it can reject")
    func otherNeedsNote() async {
        let (viewModel, _) = model([item("a", confidence: 0.6)])
        await viewModel.load()

        #expect(!(await viewModel.reject(viewModel.items[0], reason: .other, note: "  ")))
        #expect(viewModel.pendingCount == 1)
        #expect(await viewModel.reject(viewModel.items[0], reason: .other, note: "Duplicate of last week"))
    }

    @Test("Reject reasons turn into readable text")
    func reasonText() {
        #expect(TutorRejectReason.inaccurate.reasonText(note: "") == TutorRejectReason.inaccurate.title)
        #expect(TutorRejectReason.other.reasonText(note: "  Too long ") == "Too long")
        #expect(TutorRejectReason.offTopic.canSubmit(note: ""))
        #expect(!TutorRejectReason.other.canSubmit(note: ""))
        let long = String(repeating: "x", count: 500)
        #expect(TutorRejectReason.other.reasonText(note: long).count == TutorRejectReason.noteMaxCharacters)
    }

    @Test("A failed save is shown and leaves the item pending")
    func saveFailure() async {
        let (viewModel, store) = model([item("a", confidence: 0.9)])
        await viewModel.load()
        await store.forceFailure(.storageFailed)

        await viewModel.approve(viewModel.items[0])

        #expect(viewModel.error != nil)
        #expect(viewModel.pendingCount == 1)
    }
}
