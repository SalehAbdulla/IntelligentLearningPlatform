//
//  CoachThread.swift
//  StudyForge
//
//  F15 — a conversation with the coach, its messages, and the depth a message was written at
//  (docs/03 §H H01–H03; docs/05 §2 `coachThreads/{id}/messages/{msgId}`).
//
//  WHY THE LEVEL IS STORED ON THE MESSAGE, NOT ON THE THREAD
//  --------------------------------------------------------
//  H03 lets the student change the depth and see the SAME answer re-rendered. If the level lived
//  on the thread, every earlier answer would appear to change retroactively — and an answer the
//  student read and relied on would silently become a different answer. Storing it per message
//  keeps history honest while still making the control one tap away.
//
//  WHY A GROUNDED FLAG EXISTS
//  --------------------------
//  The most important thing this feature can say is "your materials do not cover that". That is a
//  first-class outcome, not an empty state, so it is a stored fact about the message rather than
//  something the UI infers from an empty citation list.
//

import Foundation

/// Who wrote a message.
enum CoachRole: String, Sendable, Codable, CaseIterable {
    case student
    case coach
}

/// How deeply an answer is explained (H03's segmented control).
enum AnswerLevel: String, Sendable, Codable, CaseIterable, Identifiable {
    case explainSimply
    case standard
    case examLevel
    case arabic

    var id: String { rawValue }

    /// The language the answer comes back in. Arabic is a first-class output, not a translation
    /// pass over an English answer (SDG 10).
    var language: OutputLanguage {
        self == .arabic ? .arabic : .english
    }

    /// The instruction appended to the grounded prompt.
    ///
    /// Kept in English whatever the output language: it is addressed to the model, not the
    /// student, and a directive the model half-understands is worse than none.
    var promptDirective: String {
        switch self {
        case .explainSimply:
            "Explain as if to a curious 12-year-old: short sentences, no jargon, one concrete analogy."
        case .standard:
            "Explain at undergraduate level, in plain academic English."
        case .examLevel:
            "Explain at exam level: precise terminology, formal definitions, and the distinctions a marker looks for."
        case .arabic:
            "Answer in Modern Standard Arabic, at undergraduate level. Keep technical terms in Arabic where a standard translation exists."
        }
    }
}

/// One turn in a coach conversation.
struct CoachMessage: Identifiable, Equatable, Sendable, Codable {

    let id: String
    let role: CoachRole
    let text: String

    /// The depth this particular answer was written at. Always `.standard` for a student turn.
    let level: AnswerLevel

    /// The passages the answer was grounded in — empty on a student turn.
    let citations: [Citation]

    /// The engine's tier, as a raw string.
    ///
    /// Stored as a string rather than as `AITier` so this model does not depend on the AI layer's
    /// enum staying `Codable`; the UI reconstructs it for the badge when it can and shows nothing
    /// when it cannot, which is the right way round for a decoration.
    let engineTier: String?

    /// Whether the answer was supported by the student's own materials.
    ///
    /// `false` means the coach said so rather than guessing — see the note at the top of the file.
    let isGrounded: Bool

    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        role: CoachRole,
        text: String,
        level: AnswerLevel = .standard,
        citations: [Citation] = [],
        engineTier: String? = nil,
        isGrounded: Bool,
        createdAt: Date = .now
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.level = level
        self.citations = citations
        self.engineTier = engineTier
        self.isGrounded = isGrounded
        self.createdAt = createdAt
    }

    /// A student's question.
    static func question(_ text: String) -> CoachMessage {
        CoachMessage(role: .student, text: text, isGrounded: true)
    }

    /// The coach's reply.
    static func answer(
        _ text: String,
        level: AnswerLevel,
        citations: [Citation],
        engineTier: String?,
        isGrounded: Bool
    ) -> CoachMessage {
        CoachMessage(
            role: .coach,
            text: text,
            level: level,
            citations: citations,
            engineTier: engineTier,
            isGrounded: isGrounded
        )
    }
}

/// A conversation with the coach (docs/05 §2 `coachThreads/{threadId}`).
struct CoachThread: Identifiable, Equatable, Sendable, Codable {

    let id: String

    /// The thread's title, taken from its first question so the list is navigable.
    var title: String

    var messages: [CoachMessage]

    /// The material ids this thread searches (H01's library-scope chip). Empty means the whole
    /// library, which is the state H01 starts in.
    var scope: [String]

    let createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        title: String = "",
        messages: [CoachMessage] = [],
        scope: [String] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.scope = scope
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Whether the thread has anything in it — an empty thread is a designed state (H01).
    var isEmpty: Bool { messages.isEmpty }

    /// The most recent answer, for the level control to act on (H03).
    var latestAnswer: CoachMessage? {
        messages.last { $0.role == .coach }
    }

    /// Appends a turn and re-titles the thread from its first question.
    mutating func append(_ message: CoachMessage, at now: Date = .now) {
        messages.append(message)
        updatedAt = now

        if title.isEmpty, message.role == .student {
            title = String(message.text.prefix(60))
        }
    }
}
