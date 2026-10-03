//
//  NotificationReminderPlanner.swift
//  StudyForge
//
//  F14 — turns the study plan into the reminders the student should have (docs/03 §M, M03's
//  "your flashcards are ready" is the same idea for a deck).
//
//  WHY THIS IS A PURE FUNCTION
//  ---------------------------
//  "Which reminders should exist right now?" is a question with a right answer, and it should not
//  need a store, a clock or a screen to ask. Keeping it pure means the quiet-hours wrap and the
//  mute rules are testable directly, rather than only through a view model that happens to call them.
//
//  WHY THE IDS ARE STABLE
//  ----------------------
//  A reminder's id is derived from the session it is about, so re-running the planner produces the
//  SAME ids and `NotificationStore.add` replaces rather than duplicates. That is what makes syncing
//  idempotent — the student can open the inbox ten times and still have one reminder per session,
//  with no "already delivered" bookkeeping to keep in step.
//
//  WHY THE TEXT IS BUILT HERE, ONCE
//  --------------------------------
//  `title` and `body` are stored on the notification, exactly as a server would send them. It means
//  the copy is fixed in the language active when the reminder was created — the honest trade for a
//  payload the app can render without knowing what it is about. The alternative (storing structured
//  fields and localising at render time) is the right move the day reminders arrive from a server
//  that knows the student's language.
//

import Foundation

/// Builds the reminders a plan implies, honouring the student's choices.
enum NotificationReminderPlanner {

    /// How many upcoming sessions can produce a reminder. A cap, so a plan with fifty sessions does
    /// not bury the inbox on first open.
    static let limit = 10

    /// The reminders the plan implies right now.
    ///
    /// - Parameters:
    ///   - plan: the student's plan, or `nil` when they have none.
    ///   - preferences: what they have agreed to be told about.
    ///   - now: injected so a test can stand at a fixed moment.
    static func reminders(
        for plan: StudyPlan?,
        preferences: NotificationPreferences,
        now: Date = .now
    ) -> [StudyNotification] {
        guard preferences.studyReminders, let plan else { return [] }

        let calendar = Calendar.current
        return plan.sessions
            .filter { $0.status == .pending && $0.scheduledAt > now }
            .sorted { $0.scheduledAt < $1.scheduledAt }
            .prefix(limit)
            .filter { !preferences.isQuiet(hour: calendar.component(.hour, from: $0.scheduledAt)) }
            .map { session in
                StudyNotification(
                    // Stable per session, so a re-sync replaces rather than duplicates.
                    id: "reminder-\(session.id)",
                    kind: .studyReminder,
                    title: session.subject,
                    body: L10n.notificationReminderBody.string(
                        session.scheduledAt.formatted(date: .omitted, time: .shortened),
                        session.estimatedMinutes
                    ),
                    target: .plan,
                    // Dated to the session, so the inbox's day grouping puts it on the right day.
                    createdAt: session.scheduledAt
                )
            }
    }
}