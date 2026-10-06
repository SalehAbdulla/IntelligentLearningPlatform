//
//  NotificationPreferences.swift
//  StudyForge
//
//  F14 — what the student wants to be told about (docs/03 §B, B09; docs/05 §2.1 `notificationPrefs`).
//
//  WHY QUIET HOURS ARE TWO INTEGERS AND NOT A `Date`
//  ------------------------------------------------
//  Quiet hours are a daily WINDOW, not a moment: "22:00 to 07:00" means every night, and it wraps
//  past midnight, which is exactly what a naive `start < end` comparison gets wrong. Two hours as
//  integers plus a wrap-aware `isQuiet(hour:)` keeps the bug out of the scheduler rather than in it.
//
//  WHY THE DEFAULT IS ON FOR THE THREE THAT MATTER
//  ----------------------------------------------
//  The brief is a study app whose whole promise is "it keeps you on track", so the three
//  study-related kinds default to on and the student turns them off — the alternative, defaulting to
//  silence, makes the feature invisible. `NotificationPreferences.default` is the single place that
//  decision lives.
//

import Foundation

/// The student's notification choices.
struct NotificationPreferences: Equatable, Sendable, Codable {

    var studyReminders: Bool
    var quizDue: Bool
    var groupActivity: Bool

    /// Whether quiet hours are enforced at all.
    var quietHoursEnabled: Bool

    /// The hour quiet hours begin, and the hour they end, as 0–23.
    var quietStartHour: Int
    var quietEndHour: Int

    init(
        studyReminders: Bool = true,
        quizDue: Bool = true,
        groupActivity: Bool = true,
        quietHoursEnabled: Bool = false,
        quietStartHour: Int = 22,
        quietEndHour: Int = 7
    ) {
        self.studyReminders = studyReminders
        self.quizDue = quizDue
        self.groupActivity = groupActivity
        self.quietHoursEnabled = quietHoursEnabled
        self.quietStartHour = quietStartHour
        self.quietEndHour = quietEndHour
    }

    /// What a student starts with: the study-related kinds on, quiet hours off.
    static let `default` = NotificationPreferences()

    /// Whether a kind is allowed to reach the student.
    func allows(_ kind: NotificationKind) -> Bool {
        switch kind {
        case .studyReminder: studyReminders
        case .quizDue: quizDue
        case .groupActivity: groupActivity
        case .achievement, .system: true
        }
    }

    /// Whether an hour of the day sits inside quiet hours.
    ///
    /// Wrap-aware on purpose: `start > end` means the window crosses midnight, so the hour is quiet
    /// when it is at or after the start OR before the end. A window that begins and ends on the same
    /// hour is treated as empty rather than as a 24-hour silence.
    func isQuiet(hour: Int) -> Bool {
        guard quietHoursEnabled, quietStartHour != quietEndHour else { return false }
        if quietStartHour < quietEndHour {
            return hour >= quietStartHour && hour < quietEndHour
        }
        return hour >= quietStartHour || hour < quietEndHour
    }
}