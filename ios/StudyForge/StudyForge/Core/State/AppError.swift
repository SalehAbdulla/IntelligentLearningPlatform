//
//  AppError.swift
//  StudyForge
//
//  One error type with user-facing copy. A raw NSError or a server string must
//  never reach the UI (docs/04-TECH-ARCHITECTURE-COST.md §8).
//
//  Every case carries a recovery suggestion, because the brief requires error
//  states that help the user recover (docs/06-DESIGN-SYSTEM.md §4.2).
//

import Foundation

enum AppError: Error, Equatable, Identifiable {

    // MARK: - Connectivity

    /// No network and nothing cached to fall back on.
    case offline

    /// The request took too long.
    case timedOut

    /// The server returned an error. `reference` is shown so support can trace it.
    case server(reference: String)

    // MARK: - Auth

    /// Sign-in or sign-up input was rejected: a typo, a weak password, or an email
    /// that already has an account. `reason` is the specific, actionable part.
    case authInvalidInput(reason: String)

    /// Authentication failed in a way the user can retry — bad credentials, rate
    /// limiting. Kept separate from `authInvalidInput` because the user's next action
    /// differs: fix the input, or wait and retry.
    case authFailed(reason: String)

    // MARK: - Domain

    /// The user's daily AI generation budget is exhausted.
    case aiQuotaExceeded(resetsAt: Date)

    /// On-device Apple Intelligence is unavailable and the cloud path is unavailable too.
    case onDeviceAIUnavailable

    /// The uploaded material could not be read (unsupported format, no text found).
    case materialUnreadable(reason: String)

    /// A payment was declined or failed verification.
    case paymentFailed(reason: String)

    /// The user does not have permission for this action.
    case notPermitted

    /// Catch-all for anything unmapped.
    case unknown

    var id: String { title + (recoveryAction ?? "") }

    // MARK: - Presentation

    /// Short, plain-language title. No jargon (docs/06-DESIGN-SYSTEM.md §4.3).
    var title: String {
        switch self {
        case .offline: "You're offline"
        case .timedOut: "That took too long"
        case .server: "Something went wrong on our side"
        case .authInvalidInput: "Check your details"
        case .authFailed: "We couldn't sign you in"
        case .aiQuotaExceeded: "You've reached today's AI limit"
        case .onDeviceAIUnavailable: "On-device AI isn't available"
        case .materialUnreadable: "We couldn't read that file"
        case .paymentFailed: "Payment didn't go through"
        case .notPermitted: "You don't have access to this"
        case .unknown: "Something went wrong"
        }
    }

    /// What happened, in one sentence, without blaming the user.
    var message: String {
        switch self {
        case .offline:
            "StudyForge works offline for your saved material. Reconnect to sync your latest changes."
        case .timedOut:
            "The request didn't finish in time. Your work is safe — try again."
        case .server(let reference):
            "We've logged the problem. If it keeps happening, quote reference \(reference)."
        case .authInvalidInput(let reason):
            reason
        case .authFailed(let reason):
            reason
        case .aiQuotaExceeded(let resetsAt):
            "Your free AI generations reset at \(resetsAt.formatted(date: .omitted, time: .shortened))."
        case .onDeviceAIUnavailable:
            "This device can't run the private on-device model. You can use the cloud model instead, or keep working offline."
        case .materialUnreadable(let reason):
            "\(reason) Try a PDF or a clearer scan."
        case .paymentFailed(let reason):
            "\(reason) No money has left your account."
        case .notPermitted:
            "Your account doesn't have permission for this. If you think that's wrong, contact your tutor."
        case .unknown:
            "Please try again. If it happens again, let us know."
        }
    }

    /// The primary recovery affordance, or `nil` when there is nothing useful to offer.
    var recoveryAction: String? {
        switch self {
        case .offline, .timedOut, .server, .unknown: "Try again"
        case .authInvalidInput: "Edit and try again"
        case .authFailed: "Try again"
        case .aiQuotaExceeded: "Use on-device instead"
        case .onDeviceAIUnavailable: "Use the cloud model"
        case .materialUnreadable: "Choose another file"
        case .paymentFailed: "Try another method"
        case .notPermitted: nil
        }
    }
}

extension AppError {

    /// Maps a thrown error onto a user-presentable `AppError`.
    /// Call this at the repository boundary so view models never see raw errors.
    static func from(_ error: any Error) -> AppError {
        if let appError = error as? AppError { return appError }

        // The AI layer has its own error type carrying richer reasons. Without this
        // branch an AI failure would degrade to `.unknown`, losing the one thing the
        // user needs: which engine failed and what to do about it.
        if let aiError = error as? AIError { return aiError.asAppError }

        // Same reasoning for auth: an unmapped AuthError would lose the reason the
        // sign-in form needs to show.
        if let authError = error as? AuthError { return authError.asAppError }

        // And for the profile write: `writeRejected` in particular must not decay to
        // `.unknown`, because it is the one failure that means the field allowlist and
        // the app disagree — a bug worth naming rather than a generic apology.
        if let profileError = error as? ProfileError { return profileError.asAppError }

        // Same reasoning again for the material store: failing to read the student's OWN library
        // is our defect, so it carries a reference and a retry rather than a generic apology.
        if let materialError = error as? MaterialError { return materialError.asAppError }

        // Same reasoning again for the summary store: a failure to read the student's OWN
        // saved summaries is our defect, so it carries a reference and a retry rather than
        // a generic apology.
        if let summaryError = error as? SummaryError { return summaryError.asAppError }

        // Same reasoning again for the deck store: a failure to read the student's OWN decks is
        // our defect, so it carries a reference and a retry rather than a generic apology.
        if let deckError = error as? DeckError { return deckError.asAppError }

        // Same reasoning again for the quiz store: a failure to read the student's OWN quizzes is
        // our defect, so it carries a reference and a retry rather than a generic apology.
        if let quizError = error as? QuizError { return quizError.asAppError }

        // Same reasoning again for the study-plan store: a failure to read the student's OWN plan is
        // our defect, so it carries a reference and a retry rather than a generic apology.
        if let planError = error as? StudyPlanError { return planError.asAppError }

        // Same reasoning again for the folder store: a failure to read the student's OWN folders is
        // our defect, so it carries a reference and a retry rather than a generic apology.
        if let folderError = error as? FolderError { return folderError.asAppError }

        // And for the bookmark store: failing to read the student's OWN collections is our defect,
        // so it carries a reference and a retry rather than a generic apology.
        if let bookmarkError = error as? BookmarkError { return bookmarkError.asAppError }

        // And for the group store. `codeNotFound` and `alreadyAMember` are not storage faults in the
        // same sense — they are the join-code outcomes I09 designs an error state for, which is why
        // they map to their own copy rather than to a generic server apology.
        if let groupError = error as? GroupError { return groupError.asAppError }

        // And for the notification store: failing to read the student's OWN inbox is our defect, so
        // it carries a reference and a retry rather than a generic apology.
        if let notificationError = error as? NotificationError { return notificationError.asAppError }

        // And for the admin store: failing to read the platform's own settings is our defect, so it
        // carries a reference and a retry rather than a generic apology.
        if let adminError = error as? AdminError { return adminError.asAppError }

        // And for the payment layer: a refused checkout (already subscribed, bad plan) is a
        // designed outcome, not an apology — `PaymentError` carries the sentence the screen
        // should show.
        if let paymentError = error as? PaymentError { return paymentError.asAppError }

        // And for the subscription store: failing to read the student's OWN entitlement is our
        // defect, so it carries a reference and a retry rather than a generic apology.
        if let subscriptionError = error as? SubscriptionError { return subscriptionError.asAppError }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                return .offline
            case .timedOut:
                return .timedOut
            default:
                return .unknown
            }
        }

        return .unknown
    }
}
