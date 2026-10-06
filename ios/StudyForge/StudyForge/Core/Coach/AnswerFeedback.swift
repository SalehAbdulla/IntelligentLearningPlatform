//
//  AnswerFeedback.swift
//  StudyForge
//
//  F15 — how a student rates the coach's answer (docs/03 §H H07; docs/05 §2 `aiFeedback/{id}`).
//
//  WHY THE REASONS MATTER MORE THAN THE STARS
//  ------------------------------------------
//  A star rating says an answer was bad; the chips say WHY, and only the "why" improves a prompt.
//  "Too long" and "off-topic" are opposite corrections — one shortens the directive, the other
//  changes retrieval — so collapsing them into a number would throw away the only actionable part
//  of the signal. The comment stays optional for exactly that reason: the chips already carry the
//  meaning, and a required free-text box would collect "bad" instead.
//
//  WHERE IT GOES
//  -------------
//  docs/05 §2 gives `aiFeedback` an owner-plus-admin read, so this is the student's own record of
//  what worked — and the admin's aggregate view of whether the coach is answering well.
//

import Foundation

/// What went wrong, in the student's own terms (H07's chips).
enum FeedbackReason: String, Sendable, Codable, CaseIterable, Identifiable {
    case wrong
    case tooLong
    case offTopic
    case notHelpful

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .wrong: "xmark.circle"
        case .tooLong: "text.alignleft"
        case .offTopic: "arrow.triangle.branch"
        case .notHelpful: "hand.thumbsdown"
        }
    }
}

/// One rating of one answer (docs/05 §2 `aiFeedback/{id}`).
struct AnswerFeedback: Identifiable, Equatable, Sendable, Codable {

    let id: String

    let threadId: String
    let messageId: String

    /// Helpfulness, 1…5 stars. Clamped at construction, so no caller can store a 7 and make the
    /// aggregate meaningless.
    let rating: Int

    /// The chips the student picked. Empty is allowed — a happy student taps the stars and leaves.
    let reasons: [FeedbackReason]

    /// Optional free text. See the note at the top of the file for why it is optional.
    let comment: String?

    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        threadId: String,
        messageId: String,
        rating: Int,
        reasons: [FeedbackReason] = [],
        comment: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.threadId = threadId
        self.messageId = messageId
        self.rating = max(1, min(5, rating))
        self.reasons = reasons
        self.comment = comment?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = createdAt
    }

    /// Whether the student reported the answer as problematic.
    ///
    /// One or two stars, OR any reason chip — because a student who taps "wrong" has told us more
    /// than a student who taps three stars.
    var isNegative: Bool { rating <= 2 || !reasons.isEmpty }
}
