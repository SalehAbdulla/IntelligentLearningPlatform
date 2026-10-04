//
//  ReviewItemTests.swift
//  StudyForgeTests
//
//  F11 — the human-in-the-loop gate. These are the tests that matter most in this feature,
//  because they assert the rule `firestore.rules` states and the app must not contradict:
//  *"a rejection must carry a reason."*
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Review item (F11)")
struct ReviewItemTests {

    private func item(confidence: Double = 0.9) -> ReviewItem {
        ReviewItem(
            courseId: "c1",
            materialId: "m1",
            materialTitle: "Lecture 4 — Normalisation",
            kind: .summary,
            draft: "Draft text",
            sourceSnippet: "Source snippet",
            confidence: confidence
        )
    }

    @Test("Rejecting without a reason is refused, and the item stays pending")
    func rejectNeedsAReason() {
        var review = item()

        #expect(throws: ReviewError.reasonRequired) {
            try review.decide(.reject)
        }
        #expect(review.status == .pending)
        #expect(review.reason == nil)
    }

    @Test("A whitespace-only reason is not a reason")
    func whitespaceReasonIsRefused() {
        var review = item()

        #expect(throws: ReviewError.reasonRequired) {
            try review.decide(.reject, reason: "   \n ")
        }
    }

    @Test("Rejecting with a reason records it, trims it, and publishes nothing")
    func rejectWithReason() throws {
        var review = item()

        try review.decide(.reject, reason: "  Misstates the definition.  ")

        #expect(review.status == .rejected)
        #expect(review.reason == "Misstates the definition.")
        #expect(review.publishedText == nil, "a rejected draft must not reach students")
        #expect(review.decidedAt != nil)
    }

    @Test("Edit & approve requires the edited text")
    func editRequiresText() {
        var review = item()

        #expect(throws: ReviewError.editedTextRequired) {
            try review.decide(.editAndApprove)
        }
        #expect(throws: ReviewError.editedTextRequired) {
            try review.decide(.editAndApprove, editedText: "   ")
        }
        #expect(review.status == .pending)
    }

    @Test("The edited text is what students see, and the draft is kept verbatim")
    func editedTextWins() throws {
        var review = item()

        try review.decide(.editAndApprove, editedText: "Corrected text")

        #expect(review.status == .edited)
        #expect(review.publishedText == "Corrected text")
        #expect(review.approvedText == "Corrected text")
        #expect(review.draft == "Draft text", "the model's output is the audit record")
    }

    @Test("A plain approval publishes the draft and records no reason")
    func plainApprovalPublishesTheDraft() throws {
        var review = item()

        try review.decide(.approve)

        #expect(review.status == .approved)
        #expect(review.publishedText == "Draft text")
        #expect(review.reason == nil)
        #expect(review.approvedText == nil)
    }

    @Test("A pending item publishes nothing")
    func pendingPublishesNothing() {
        #expect(item().publishedText == nil)
        #expect(item().status.isPending)
    }

    @Test("Low confidence is a documented threshold, not a tuned number")
    func lowConfidenceThreshold() {
        #expect(item(confidence: 0.69).isLowConfidence)
        #expect(item(confidence: 0.7).isLowConfidence == false)
        #expect(item(confidence: 0.64).confidencePercent == 64)
    }
}
