//
//  NotificationAuthorizer.swift
//  StudyForge
//
//  F14 — the seam over the SYSTEM permission prompt (docs/03 §M, M02).
//
//  WHY M02 EXISTS AT ALL
//  ---------------------
//  iOS shows its own permission dialog exactly once. If the student declines it, the app cannot ask
//  again — it can only send them to Settings. So the design puts a PRIMER before it: a screen that
//  says what the reminders are for, so the one prompt the app gets is answered deliberately rather
//  than reflexively. This protocol is what lets that primer be built, previewed and tested without a
//  real prompt appearing.
//
//  WHY IT IS NOT `UNUserNotificationCenter` DIRECTLY
//  -------------------------------------------------
//  A system prompt is an un-testable side effect. Behind a protocol, the primer's logic — what it
//  says before and after, and what it does when the student declines — is testable with a mock, and
//  the real centre is one conformance rather than a dependency of every screen.
//

import Foundation
@preconcurrency import UserNotifications

/// What the system currently allows.
enum NotificationAuthorization: String, Sendable, Equatable {
    /// Never asked, or the answer was cleared by a reinstall.
    case notDetermined
    case granted
    case denied

    /// Whether the app may post a notification.
    var allowsDelivery: Bool { self == .granted }
}

/// Asks the system for permission to notify.
protocol NotificationAuthorizer: Sendable {

    /// The current answer, without prompting.
    func currentStatus() async -> NotificationAuthorization

    /// Shows the system prompt. Returns what the student chose.
    func requestAuthorization() async -> NotificationAuthorization
}

/// The real authorizer, over `UNUserNotificationCenter`.
struct SystemNotificationAuthorizer: NotificationAuthorizer {

    /// No stored centre: `current()` is asked for at the point of use, so this type stays trivially
    /// `Sendable` and costs nothing to construct.
    func currentStatus() async -> NotificationAuthorization {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return NotificationAuthorization(settings.authorizationStatus)
    }

    func requestAuthorization() async -> NotificationAuthorization {
        let granted = (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        return granted ? .granted : .denied
    }
}

private extension NotificationAuthorization {

    /// Maps the system's status onto ours, so no `UNAuthorizationStatus` reaches a screen.
    init(_ status: UNAuthorizationStatus) {
        switch status {
        case .authorized, .provisional, .ephemeral: self = .granted
        case .denied: self = .denied
        case .notDetermined: self = .notDetermined
        @unknown default: self = .notDetermined
        }
    }
}

/// A mock authorizer for previews and tests.
///
/// `@unchecked Sendable` with a lock because it is mutable test scaffolding, not a service: the
/// alternative is making every test await an actor to set one enum.
final class InMemoryNotificationAuthorizer: NotificationAuthorizer, @unchecked Sendable {

    private let lock = NSLock()
    private var status: NotificationAuthorization
    private let outcome: NotificationAuthorization

    init(status: NotificationAuthorization = .notDetermined, outcome: NotificationAuthorization = .granted) {
        self.status = status
        self.outcome = outcome
    }

    func currentStatus() async -> NotificationAuthorization {
        lock.withLock { status }
    }

    func requestAuthorization() async -> NotificationAuthorization {
        lock.withLock {
            status = outcome
            return outcome
        }
    }
}