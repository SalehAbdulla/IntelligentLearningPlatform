//
//  ReviewItem.swift
//  StudyForge
//
//  F11 — an AI-generated artefact waiting for a tutor's judgement, and the decision they make
//  (docs/03 §J J06/J07; docs/05 §2 `reviewQueue/{id}`).
//
//  THIS IS THE HUMAN-IN-THE-LOOP ETHICS CONTROL
//  --------------------------------------------
//  `backend/firestore.rules` states the contract in one line: *"only tutors decide whether
//  AI-generated content reaches students, and a rejection must carry a reason."* That is a
//  rule about PEOPLE, and a rule enforced only on the server is a rule the client can
//  accidentally contradict. So it is enforced HERE too: `decide(_:...)` refuses to reject
//  without a reason, which means the UI cannot construct the illegal state even if a future
//  screen forgets to ask for one.
//
//  WHY AN EDIT IS A DECISION AND NOT A FIELD EDIT
//  ----------------------------------------------
//  "Edit & approve" is not the same as approving then editing: the tutor is asserting that
//  the EDITED text is what should reach students. Modelling it as its own decision keeps that
//  assertion explicit, and keeps `draft` as the immutable record of what the model produced —
//  which is exactly the evidence an ethics review would want to see.
//

import Foundation

/// What kind of artefact the model produced.
enum ReviewKind: String, Sendable, Codable, CaseIterable, Identifiable {
    case summary
    case flashcards
    case quiz

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .summary: "text.alignleft"
        case .flashcards: "rectangle.stack"
        case .quiz: "checklist"
        }
    }
}

/// Where a queued item stands.
enum ReviewStatus: String, Sendable, Codable, CaseIterable {

    /// Awaiting the tutor. The only status the queue lists by default (J06).
    case pending

    /// Approved as generated.
    case approved

    /// Approved after the tutor changed the text.
    case edited

    /// Rejected, with a reason. It will not reach students.
    case rejected

    /// Whether the tutor still has to act.
    var isPending: Bool { self == .pending }
}

/// What the tutor decided (J07's three actions).
enum ReviewDecision: String, Sendable, Codable, CaseIterable, Identifiable {

    /// The draft is good as it stands.
    case approve

    /// The tutor changed the draft; the EDITED text is what reaches students.
    case editAndApprove

    /// It must not reach students, and the reason is mandatory.
    case reject

    var id: String { rawValue }

    /// The status this decision produces.
    var resultingStatus: ReviewStatus {
        switch self {
        case .approve: .approved
        case .editAndApprove: .edited
        case .reject: .rejected
        }
    }

    /// Whether a reason is required — true only for a rejection, matching the rules.
    var requiresReason: Bool { self == .reject }

    /// Whether the tutor must supply replacement text.
    var requiresEditedText: Bool { self == .editAndApprove }

    var symbolName: String {
        switch self {
        case .approve: "checkmark.circle"
        case .editAndApprove: "pencil.and.outline"
        case .reject: "xmark.octagon"
        }
    }
}

/// One AI-drafted artefact awaiting review (docs/05 §2 `reviewQueue/{id}`).
struct ReviewItem: Identifiable, Equatable, Sendable, Codable {

    let id: String

    var courseId: String

    /// The source material the draft was generated from — J06's "material" column.
    var materialId: String
    var materialTitle: String

    var kind: ReviewKind

    /// The model's draft, kept verbatim after a decision, so the audit trail shows what was
    /// proposed as well as what was accepted.
    var draft: String

    /// The passage the draft was grounded in, shown beside it in J07 so the tutor can CHECK
    /// the claim rather than merely read it. The same provenance idea as F03's citation chips,
    /// applied to a person instead of a screen.
    var sourceSnippet: String

    /// The router's confidence, 0…1. See `isLowConfidence`.
    var confidence: Double

    var status: ReviewStatus

    /// What the tutor wrote when rejecting. `nil` unless `status == .rejected`.
    var reason: String?

    /// The text the tutor approved, when they edited. `nil` for a plain approval.
    var approvedText: String?

    var decidedAt: Date?
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        courseId: String,
        materialId: String,
        materialTitle: String,
        kind: ReviewKind,
        draft: String,
        sourceSnippet: String,
        confidence: Double,
        status: ReviewStatus = .pending,
        reason: String? = nil,
        approvedText: String? = nil,
        decidedAt: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.courseId = courseId
        self.materialId = materialId
        self.materialTitle = materialTitle
        self.kind = kind
        self.draft = draft
        self.sourceSnippet = sourceSnippet
        self.confidence = confidence
        self.status = status
        self.reason = reason
        self.approvedText = approvedText
        self.decidedAt = decidedAt
        self.createdAt = createdAt
    }

    /// 0…100, for the confidence badge.
    var confidencePercent: Int { Int((confidence * 100).rounded()) }

    /// Below this the item is flagged for a closer read.
    ///
    /// A documented threshold, matching `TopicMastery.isWeak` and `Enrollment.isAtRisk`: the
    /// tutor can see WHY an item is flagged, and J06 can filter by it.
    var isLowConfidence: Bool { confidence < 0.7 }

    /// The text that should reach students: the edited version when there is one, otherwise
    /// the draft. A rejected item has no published text at all.
    var publishedText: String? {
        switch status {
        case .approved: draft
        case .edited: approvedText ?? draft
        case .pending, .rejected: nil
        }
    }

    /// Records the tutor's decision.
    ///
    /// - Throws: `ReviewError.reasonRequired` on a rejection with no reason, and
    ///   `ReviewError.editedTextRequired` on "edit & approve" with nothing supplied. These are
    ///   the two states `firestore.rules` rejects, refused here so the app cannot even try.
    mutating func decide(
        _ decision: ReviewDecision,
        editedText: String? = nil,
        reason: String? = nil,
        at now: Date = .now
    ) throws {
        let trimmedReason = reason?.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEdit = editedText?.trimmingCharacters(in: .whitespacesAndNewlines)

        if decision.requiresReason, (trimmedReason?.isEmpty ?? true) {
            throw ReviewError.reasonRequired
        }
        if decision.requiresEditedText, (trimmedEdit?.isEmpty ?? true) {
            throw ReviewError.editedTextRequired
        }

        status = decision.resultingStatus
        self.reason = decision.requiresReason ? trimmedReason : nil
        approvedText = decision.requiresEditedText ? trimmedEdit : nil
        decidedAt = now
    }
}

/// Failures from the review layer, in the app's own vocabulary.
enum ReviewError: Error, Equatable {

    /// A rejection was attempted without a reason — the one case the rules forbid outright.
    case reasonRequired

    /// "Edit & approve" was attempted with no edited text.
    case editedTextRequired

    /// Maps to the app's single user-facing error type.
    var asAppError: AppError {
        switch self {
        case .reasonRequired:
            .server(reference: "review-reason-required")
        case .editedTextRequired:
            .server(reference: "review-edit-required")
        }
    }
}
