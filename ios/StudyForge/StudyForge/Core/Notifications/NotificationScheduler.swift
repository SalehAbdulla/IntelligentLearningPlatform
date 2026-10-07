//
//  NotificationScheduler.swift
//  StudyForge
//
//  F14 — the seam over posting a notification to the SYSTEM (docs/03 §M, M01/M03).
//
//  WHY THIS EXISTS SEPARATELY FROM THE AUTHORIZER
//  ---------------------------------------------
//  `NotificationAuthorizer` answers "may we notify?"; this answers "notify". They are different
//  questions with different side effects, and keeping them apart means the permission primer never
//  grows a delivery method it has no business owning.
//
//  WHY THE INBOX IS NOT ENOUGH
//  ---------------------------
//  `NotificationStore` keeps the app's own inbox (see `StudyNotification`), which is what M01 lists.
//  But an inbox the student has to open is not a notification: a reminder has to reach them while the
//  app is closed, which is exactly what a `UNNotificationRequest` does and a stored row cannot. Until
//  this seam existed the app could ask for permission and keep an inbox but never actually notify.
//
//  WHY IT IS A PROTOCOL
//  --------------------
//  Posting is an un-testable side effect (and, in a unit-test host, an unwanted one). Behind the
//  protocol, the "send a test reminder" action is testable with `InMemoryNotificationScheduler`, and
//  the real centre is one conformance rather than a dependency of the screen.
//

import Foundation
@preconcurrency import UserNotifications

/// Delivers a notification to the system so it reaches the student as a banner.
protocol NotificationScheduler: Sendable {

    /// Delivers one notification immediately.
    ///
    /// Takes a `StudyNotification` rather than raw strings because the two views of a notification
    /// — the inbox row and the banner — are meant to carry the SAME title and body.
    func deliver(_ notification: StudyNotification) async
}

/// The real scheduler, over `UNUserNotificationCenter`.
struct SystemNotificationScheduler: NotificationScheduler {

    func deliver(_ notification: StudyNotification) async {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default

        // `trigger: nil` delivers straight away; a dated reminder would build a calendar trigger from
        // `createdAt` instead. A failure is swallowed deliberately: there is nothing the student can
        // do about it here, and the caller already reports whether permission was granted.
        let request = UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: nil
        )
        try? await UNUserNotificationCenter.current().add(request)
    }
}

/// Records what it was asked to deliver, for previews and tests.
///
/// `@unchecked Sendable` with a lock, matching `InMemoryNotificationAuthorizer`: it is mutable test
/// scaffolding, not a service.
final class InMemoryNotificationScheduler: NotificationScheduler, @unchecked Sendable {

    private let lock = NSLock()
    private var delivered: [StudyNotification] = []

    /// What has been delivered, oldest first.
    var deliveredNotifications: [StudyNotification] {
        lock.withLock { delivered }
    }

    func deliver(_ notification: StudyNotification) async {
        lock.withLock { delivered.append(notification) }
    }
}
