//
//  ReviewWorkflowViewModelTests.swift
//  StudyForgeTests
//
//  F11 — J06's queue and J07's decision screen. The filter/bulk-approve pair is the one that
//  matters: filtering to the uncertain drafts and approving must approve ONLY those.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Review queue (F11)")
@MainActor
struct ReviewQueueViewModelTests {

    private func item(id: String, confidence: Double) -> ReviewItem {
        ReviewItem(
            id: id,
            courseId: "c1",
            materialId: "m1",
            materialTitle: "Lecture 4",
            kind: .summary,
            draft: "Draft \(id)",
            sourceSnippet: "Source",
            confidence: confidence
        )
    }

    @Test("Only pending items are listed")
    func onlyPending() async throws {
        var decided = item(id: "b", confidence: 0.9)
        try decided.decide(.approve)
        let store = InMemoryCourseStore(reviewItems: [item(id: "a", confidence: 0.9), decided])
        let viewModel = ReviewQueueViewModel(courseId: "c1", store: store)

        await viewModel.load()

        #expect(viewModel.items.map(\.id) == ["a"])
        #expect(viewModel.pendingCount == 1)
    }

    @Test("The confidence filter narrows the list without changing the queue")
    func filterNarrows() async {
        let store = InMemoryCourseStore(reviewItems: [
            item(id: "high", confidence: 0.95),
            item(id: "low", confidence: 0.5),
        ])
        let viewModel = ReviewQueueViewModel(courseId: "c1", store: store)
        await viewModel.load()

        viewModel.lowConfidenceOnly = true

        #expect(viewModel.items.map(\.id) == ["low"])
        #expect(viewModel.pendingCount == 2, "the queue itself is unchanged")
    }

    @Test("An empty list from the filter reads differently from an empty queue")
    func filterEmptyIsDistinguishable() async {
        let store = InMemoryCourseStore(reviewItems: [item(id: "high", confidence: 0.95)])
        let viewModel = ReviewQueueViewModel(courseId: "c1", store: store)
        await viewModel.load()

        viewModel.lowConfidenceOnly = true

        #expect(viewModel.isEmpty)
        #expect(viewModel.filterHidEverything, "the tutor should be told to clear the filter")
    }

    @Test("Bulk approve approves only what the filter is showing")
    func bulkApproveRespectsTheFilter() async throws {
        let store = InMemoryCourseStore(reviewItems: [
            item(id: "high", confidence: 0.95),
            item(id: "low", confidence: 0.5),
        ])
        let viewModel = ReviewQueueViewModel(courseId: "c1", store: store)
        await viewModel.load()

        viewModel.lowConfidenceOnly = true
        await viewModel.approveAll()

        let remaining = try await store.reviewItems(courseId: "c1")
        let byId = Dictionary(uniqueKeysWithValues: remaining.map { ($0.id, $0.status) })

        #expect(byId["low"] == .approved)
        #expect(byId["high"] == .pending, "the high-confidence draft was not shown, so it was not approved")
    }

    @Test("The confirmation names the count it is about to approve")
    func confirmationNamesTheCount() async {
        let store = InMemoryCourseStore(reviewItems: [
            item(id: "a", confidence: 0.9),
            item(id: "b", confidence: 0.9),
        ])
        let viewModel = ReviewQueueViewModel(courseId: "c1", store: store)
        await viewModel.load()

        #expect(viewModel.bulkConfirmTitle() == L10n.tutorBulkApproveConfirmTitle.string(2))
    }
}

@Suite("Review detail (F11)")
@MainActor
struct ReviewDetailViewModelTests {

    private func item(draft: String = "Draft text") -> ReviewItem {
        ReviewItem(
            courseId: "c1",
            materialId: "m1",
            materialTitle: "Lecture 4",
            kind: .summary,
            draft: draft,
            sourceSnippet: "Source snippet",
            confidence: 0.9
        )
    }

    private func viewModel(_ item: ReviewItem) -> ReviewDetailViewModel {
        ReviewDetailViewModel(item: item, store: InMemoryCourseStore(reviewItems: [item]))
    }

    @Test("Rejecting with no reason is refused with an on-screen message, not a crash")
    func rejectWithoutReasonMessages() async {
        let viewModel = viewModel(item())

        await viewModel.reject()

        #expect(viewModel.validationMessage == L10n.tutorRejectReasonRequired.string)
        #expect(viewModel.item.status == .pending)
        #expect(viewModel.error == nil, "a rule violation is the tutor's to fix, not our fault")
    }

    @Test("Rejecting with a reason records it")
    func rejectWithReason() async {
        let viewModel = viewModel(item())
        viewModel.rejectReason = "Misstates the definition."

        await viewModel.reject()

        #expect(viewModel.item.status == .rejected)
        #expect(viewModel.item.reason == "Misstates the definition.")
        #expect(viewModel.publishedText == nil)
    }

    @Test("Edit & approve is only meaningful once the draft has actually changed")
    func editNeedsAChange() {
        let viewModel = viewModel(item())
        #expect(viewModel.hasEdited == false)

        viewModel.editedDraft = "Corrected text"
        #expect(viewModel.hasEdited)
    }

    @Test("Approving publishes the draft")
    func approve() async {
        let viewModel = viewModel(item())

        await viewModel.approve()

        #expect(viewModel.item.status == .approved)
        #expect(viewModel.publishedText == "Draft text")
        #expect(viewModel.isPending == false)
        #expect(viewModel.bannerText == L10n.tutorApprovedBanner.string)
    }

    @Test("A decided item shows a banner and cannot be decided again")
    func decidedIsTerminal() async {
        let viewModel = viewModel(item())
        await viewModel.approve()

        #expect(viewModel.canDecide == false)
        #expect(viewModel.bannerText != nil)
    }
}
