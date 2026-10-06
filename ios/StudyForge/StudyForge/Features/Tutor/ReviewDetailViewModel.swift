//
//  ReviewDetailViewModel.swift
//  StudyForge
//
//  F11 — presentation logic for J07 (`105_Tutor_AI_Content_EditApprove_{M2}`).
//
//  WHY THE REJECT BUTTON IS NOT DISABLED UNTIL A REASON IS TYPED
//  ------------------------------------------------------------
//  A greyed-out button teaches nothing. The tutor taps Reject, and the MODEL refuses — the
//  message on screen names the rule ("a reason is required"). That is the difference between a
//  rule the app enforces and a rule the interface merely hints at, and it mirrors
//  `firestore.rules`, where the same rejection is refused server-side.
//

import Foundation

@MainActor
@Observable
final class ReviewDetailViewModel {

    // MARK: State

    private(set) var item: ReviewItem

    /// The editable draft. Seeded from the model's output, which the tutor may change.
    var editedDraft: String

    /// J07's mandatory reason, used only on a rejection.
    var rejectReason = ""

    private(set) var isDeciding = false
    private(set) var error: AppError?

    /// A rule violation the tutor can fix (an empty reason, an empty edit). Distinct from
    /// `error`, which is a fault of ours.
    private(set) var validationMessage: String?

    private let store: any CourseStore

    init(item: ReviewItem, store: any CourseStore) {
        self.item = item
        self.editedDraft = item.draft
        self.store = store
    }

    // MARK: Derived

    var isPending: Bool { item.status.isPending }
    var draft: String { item.draft }
    var sourceSnippet: String { item.sourceSnippet }
    var materialTitle: String { item.materialTitle }
    var isLowConfidence: Bool { item.isLowConfidence }

    /// Whether the tutor has actually changed the draft, which is what "Edit & approve" means.
    var hasEdited: Bool {
        editedDraft.trimmingCharacters(in: .whitespacesAndNewlines) != draft
    }

    var publishedText: String? { item.publishedText }

    /// The outcome banner shown once a decision exists.
    var bannerText: String? {
        switch item.status {
        case .approved: L10n.tutorApprovedBanner.string
        case .edited: L10n.tutorEditedBanner.string
        case .rejected: L10n.tutorRejectedBanner.string
        case .pending: nil
        }
    }

    var canDecide: Bool { isPending && !isDeciding }

    // MARK: Copy

    var title: String { L10n.tutorReviewDetailTitle.string }
    var draftHeading: String { L10n.tutorDraftHeading.string }
    var sourceHeading: String { L10n.tutorSourceHeading.string }
    var approveTitle: String { L10n.tutorApprove.string }
    var editAndApproveTitle: String { L10n.tutorEditAndApprove.string }
    var rejectTitle: String { L10n.tutorReject.string }
    var rejectReasonLabel: String { L10n.tutorRejectReasonLabel.string }
    var rejectReasonPlaceholder: String { L10n.tutorRejectReasonPlaceholder.string }
    var publishedTextHeading: String { L10n.tutorPublishedTextHeading.string }

    func confidenceLabel() -> String {
        L10n.tutorConfidenceValue.string(item.confidencePercent)
    }

    func kindName() -> String {
        switch item.kind {
        case .summary: L10n.summaryTitle.string
        case .flashcards: L10n.deckTitle.string
        case .quiz: L10n.quizTitle.string
        }
    }

    // MARK: Actions

    func approve() async { await decide(.approve) }
    func editAndApprove() async { await decide(.editAndApprove) }
    func reject() async { await decide(.reject) }

    /// Records a decision through the model, which is where the rules live.
    private func decide(_ decision: ReviewDecision) async {
        guard isPending, !isDeciding else { return }

        isDeciding = true
        defer { isDeciding = false }
        error = nil
        validationMessage = nil

        do {
            var updated = item
            try updated.decide(decision, editedText: editedDraft, reason: rejectReason)
            try await store.upsert(updated)
            item = updated
        } catch let reviewError as ReviewError {
            validationMessage = message(for: reviewError)
        } catch {
            self.error = AppError.from(error)
        }
    }

    /// Turns a model-level rule violation into the sentence the tutor reads.
    private func message(for error: ReviewError) -> String {
        switch error {
        case .reasonRequired: L10n.tutorRejectReasonRequired.string
        case .editedTextRequired: L10n.tutorEditRequired.string
        }
    }
}
