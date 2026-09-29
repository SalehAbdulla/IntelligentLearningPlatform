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
