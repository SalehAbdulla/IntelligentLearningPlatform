//
//  StudyNotification.swift
//  StudyForge
//
//  F14 — one line in the student's inbox (docs/03 §M, M01; docs/05 §2.5 `notifications`).
//
//  WHY THE APP KEEPS ITS OWN COPY OF A NOTIFICATION
//  ------------------------------------------------
//  A `UNUserNotificationCenter` request is scheduled, delivered and then gone — iOS keeps no
//  queryable inbox. The design's M01 IS an inbox, with unread dots and swipe-to-mark-read, so the app
//  records what it has raised: the banner in the system tray and the row in the inbox are two views
//  of one `StudyNotification`. That is also what makes "mark as read" a real state change rather than
//  a lie the next launch forgets.
//
//  WHY THE DEEP LINK IS A TARGET AND NOT A URL
//  -------------------------------------------
//  M03 deep-links "your flashcards are ready" into the review screen. Storing a destination the app
//  can resolve (`NotificationTarget`) keeps that working without a URL scheme to register and
//  maintain, and it is what a row tap will read when the inbox rows become navigable.
//

import Foundation

/// What a notification is about. The three the student can mute are the three B09 toggles.
enum NotificationKind: String, Sendable, CaseIterable, Codable, Identifiable {
    case studyReminder
    case quizDue
    case groupActivity
    case achievement
    case system

    var id: String { rawValue }

    /// The type icon M01 lists.
    var symbolName: String {
        switch self {
        case .studyReminder: "calendar.badge.clock"
        case .quizDue: "checklist"
        case .groupActivity: "person.3"
        case .achievement: "rosette"
        case .system: "info.circle"
        }
    }

    /// The localised name, for the toggle in B09 and the row's accessibility label.
    var title: String {
        switch self {
        case .studyReminder: L10n.notificationKindStudyReminder.string
        case .quizDue: L10n.notificationKindQuizDue.string
        case .groupActivity: L10n.notificationKindGroupActivity.string
        case .achievement: L10n.notificationKindAchievement.string
        case .system: L10n.notificationKindSystem.string
        }
    }

    /// Whether B09 offers a mute switch for this kind.
    ///
    /// Achievements and system notices are not muteable: they are rare, they are about the student's
    /// own progress or the app's health, and a student who muted them would be muting something they
    /// cannot reasonably want to lose.
    var isMuteable: Bool {
        switch self {
        case .studyReminder, .quizDue, .groupActivity: true
        case .achievement, .system: false
        }
    }
}

/// Where a notification points, so a tap can open the right screen.
enum NotificationTarget: String, Sendable, CaseIterable, Codable {
    case flashcards
    case quiz
    case plan
    case group
    case progress
}

/// One notification, as the app remembers it.
struct StudyNotification: Identifiable, Equatable, Sendable, Codable {

    let id: String
    var kind: NotificationKind
    var title: String
    var body: String

    /// Where tapping should land. `nil` for a notice with no destination.
    var target: NotificationTarget?

    var isRead: Bool
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        kind: NotificationKind,
        title: String,
        body: String,
        target: NotificationTarget? = nil,
        isRead: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.body = body
        self.target = target
        self.isRead = isRead
        self.createdAt = createdAt
    }
}