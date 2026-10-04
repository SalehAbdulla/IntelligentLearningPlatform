//
//  CoachChatViewModel.swift
//  StudyForge
//
//  F15 — H02/H03/H07: the conversation, the depth control and the feedback sheet.
//

import Foundation

@MainActor
@Observable
final class CoachChatViewModel {

    /// H02's composer.
    var draft = ""

    private(set) var thread: CoachThread
    private(set) var isThinking = false
    private(set) var error: AppError?

    /// True when no tier could answer — H08's condition.
    private(set) var isUnavailable = false

    /// H03's depth control, applied to the next question and to a re-ask.
    var level: AnswerLevel = .standard

    /// The message a rating sheet is open for (H07).
    var ratingMessage: CoachMessage?

    private(set) var didRate = false

    private let uid: String
    private let service: CoachService
    private let store: any CoachStore

    init(uid: String, thread: CoachThread, service: CoachService, store: any CoachStore) {
        self.uid = uid
        self.thread = thread
        self.service = service
        self.store = store
    }

    // MARK: Derived

    var messages: [CoachMessage] { thread.messages }
    var isEmpty: Bool { thread.messages.isEmpty }
    var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isThinking
    }

    // MARK: Copy

    var title: String { L10n.coachTitle.string }
    var placeholder: String { L10n.coachAskPlaceholder.string }
    var sendTitle: String { L10n.coachAsk.string }
    var thinkingTitle: String { L10n.coachThinking.string }
    var levelLabel: String { L10n.coachLevelLabel.string }
    var citationsLabel: String { L10n.coachCitationsLabel.string }
    var ungroundedBadge: String { L10n.coachUngroundedBadge.string }
    var helpfulTitle: String { L10n.coachHelpful.string }
    var thanksTitle: String { L10n.coachFeedbackThanks.string }

    var levels: [AnswerLevel] { AnswerLevel.allCases }

    func levelName(_ level: AnswerLevel) -> String {
        switch level {
        case .explainSimply: L10n.coachLevelSimply.string
        case .standard: L10n.coachLevelStandard.string
        case .examLevel: L10n.coachLevelExam.string
        case .arabic: L10n.coachLevelArabic.string
        }
    }

    func relevanceLabel(_ citation: Citation) -> String {
        L10n.coachRelevance.string(Int((citation.score * 100).rounded()))
    }

    func engineLabel(_ message: CoachMessage) -> String? {
        message.engineTier.map { L10n.coachEngineLabel.string($0) }
    }

    // MARK: Actions

    /// Answers the question the student arrived with, if there is one.
    func startIfNeeded(question: String?) async {
        guard let question, thread.messages.isEmpty else { return }
        await ask(question)
    }

    /// Sends the composer's question.
    func send() async {
        let question = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }
        draft = ""
        await ask(question)
    }

    /// H03: re-asks the last question at a new depth, appending a NEW answer.
    ///
    /// A new message rather than rewriting the old one — see `CoachThread` for why the level is
    /// stored per message.
    func reask() async {
        guard let question = thread.messages.last(where: { $0.role == .student })?.text else { return }
        await ask(question)
    }

    private func ask(_ question: String) async {
        guard !isThinking else { return }

        isThinking = true
        isUnavailable = false
        error = nil
        defer { isThinking = false }

        thread.append(.question(question))

        do {
            let answer = try await service.ask(question, scope: thread.scope, level: level)
            thread.append(.answer(
                answer.text,
                level: level,
                citations: answer.citations,
                engineTier: answer.engineTier,
                isGrounded: answer.isGrounded
            ))
            try? await store.upsert(thread)
        } catch {
            let appError = AppError.from(error)

            // H08: an unavailable engine is a designed screen, not an error banner. Everything else
            // is a real failure and keeps the banner.
            if appError == .onDeviceAIUnavailable || appError == .notPermitted {
                isUnavailable = true
            } else {
                self.error = appError
            }
        }
    }

    /// Records a rating (H07).
    func rate(stars: Int, reasons: [FeedbackReason], comment: String?) async {
        guard let message = ratingMessage else { return }

        let feedback = AnswerFeedback(
            threadId: thread.id,
            messageId: message.id,
            rating: stars,
            reasons: reasons,
            comment: comment
        )

        try? await store.record(feedback)
        didRate = true
        ratingMessage = nil
    }

    func dismissRating() {
        ratingMessage = nil
    }
}
