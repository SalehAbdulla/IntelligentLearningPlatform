//
//  ReviewQueueViewModel.swift
//  StudyForge
//
//  F11 — presentation logic for J06 (`104_Tutor_AI_Content_ReviewQueue_{M2}`).
//
//  WHY BULK APPROVE STILL ASKS
//  ---------------------------
//  The design offers a bulk approve, and docs/02 §6 names its hazard: *"bulk approve with
//  low-confidence items (warn)"*. So the confirmation is not decorative — it says how many
//  drafts are about to be accepted, and it is shown even when every one of them is
//  high-confidence, because the tutor is asserting authorship of each. What it deliberately
//  does NOT do is approve silently in the background after a single tap and no summary.
//

import Foundation

@MainActor
@Observable
final class ReviewQueueViewModel {

    // MARK: Bound state

    /// J06's "filter by confidence".
    var lowConfidenceOnly = false

    private(set) var state: LoadState<[ReviewItem]> = .idle
    private(set) var isBulkApproving = false
    private(set) var error: AppError?

    let courseId: String
    private let store: any CourseStore

    init(courseId: String, store: any CourseStore) {
        self.courseId = courseId
        self.store = store
    }

    // MARK: Derived

    private var allItems: [ReviewItem] { state.value ?? [] }

    /// The items still awaiting a decision.
    var pendingCount: Int { allItems.filter { $0.status.isPending }.count }

    /// What the queue lists: pending items, optionally narrowed to the uncertain ones.
    var items: [ReviewItem] {
        let pending = allItems.filter { $0.status.isPending }
        return lowConfidenceOnly ? pending.filter(\.isLowConfidence) : pending
    }

    var isEmpty: Bool { items.isEmpty }
    var isLoading: Bool { state.isLoading }

    /// True when the queue is empty only BECAUSE of the filter — a different message from
    /// "nothing to review", and the difference tells the tutor whether to clear the filter.
    var filterHidEverything: Bool { items.isEmpty && pendingCount > 0 }

    var canBulkApprove: Bool { !items.isEmpty && !isBulkApproving }

    // MARK: Copy

    var title: String { L10n.tutorReviewTitle.string }
    var emptyTitle: String { L10n.tutorReviewEmptyTitle.string }
    var emptyBody: String { L10n.tutorReviewEmptyBody.string }
    var filterTitle: String { L10n.tutorFilterLowConfidence.string }
    var bulkTitle: String { L10n.tutorBulkApprove.string }
    var lowConfidenceBadge: String { L10n.tutorLowConfidenceBadge.string }

    var pendingCountLabel: String { L10n.tutorReviewPendingCount.string(pendingCount) }

    func confidenceLabel(_ item: ReviewItem) -> String {
        L10n.tutorConfidenceValue.string(item.confidencePercent)
    }

    /// The artefact kind, reusing the student-facing names so a tutor and a student call the
    /// same thing by the same name.
    func kindName(_ item: ReviewItem) -> String {
        switch item.kind {
        case .summary: L10n.summaryTitle.string
        case .flashcards: L10n.deckTitle.string
        case .quiz: L10n.quizTitle.string
        }
    }

    func bulkConfirmTitle() -> String {
        L10n.tutorBulkApproveConfirmTitle.string(items.count)
    }

    var bulkConfirmBody: String { L10n.tutorBulkApproveConfirmBody.string }

    // MARK: Actions

    func load() async {
        state = .loading
        do {
            let items = try await store.reviewItems(courseId: courseId)
            state = .from(items)
        } catch {
            state = .failed(AppError.from(error))
        }
    }

    /// Approves every draft currently SHOWN — which is what makes the confidence filter a real
    /// safety valve rather than a view tweak: filtering to the uncertain ones and approving
    /// would otherwise approve everything.
    func approveAll() async {
        guard canBulkApprove else { return }

        isBulkApproving = true
        defer { isBulkApproving = false }
        error = nil

        do {
            for var item in items {
                try item.decide(.approve)
                try await store.upsert(item)
            }
            await load()
        } catch {
            self.error = AppError.from(error)
        }
    }
}
