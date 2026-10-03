//
//  NotificationStoreTests.swift
//  StudyForgeTests
//
//  Tests for the notification models, the quiet-hours rule, the reminder planner and their store.
//

import Foundation
import Testing
@testable import StudyForge

// MARK: - Model

@Suite("Notification model")
struct NotificationModelTests {

    @Test("A notification round-trips through JSON")
    func codableRoundTrip() throws {
        let original = StudyNotification(
            kind: .quizDue,
            title: "Weekly quiz",
            body: "Your quiz is ready.",
            target: .quiz,
            isRead: true
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StudyNotification.self, from: data)
        #expect(decoded == original)
        #expect(decoded.target == .quiz)
    }

    @Test("Only the three student-facing kinds can be muted")
    func muteableKinds() {
        #expect(NotificationKind.studyReminder.isMuteable)
        #expect(NotificationKind.quizDue.isMuteable)
        #expect(NotificationKind.groupActivity.isMuteable)
        // Achievements and system notices are about the student's own progress or the app's health,
        // so B09 offers no switch for them.
        #expect(NotificationKind.achievement.isMuteable == false)
        #expect(NotificationKind.system.isMuteable == false)
    }

    @Test("Preferences allow exactly the kinds the student turned on")
    func allows() {
        var preferences = NotificationPreferences.default
        #expect(preferences.allows(.studyReminder))
        #expect(preferences.allows(.achievement), "an unmuteable kind is always allowed")

        preferences.studyReminders = false
        #expect(preferences.allows(.studyReminder) == false)
        #expect(preferences.allows(.quizDue))
    }

    @Test("Quiet hours wrap past midnight and are off unless asked for")
    func quietHours() {
        let off = NotificationPreferences(quietHoursEnabled: false, quietStartHour: 22, quietEndHour: 7)
        #expect(off.isQuiet(hour: 23) == false, "quiet hours are off by default")

        // 22:00 → 07:00 crosses midnight.
        let overnight = NotificationPreferences(quietHoursEnabled: true, quietStartHour: 22, quietEndHour: 7)
        #expect(overnight.isQuiet(hour: 23))
        #expect(overnight.isQuiet(hour: 3))
        #expect(overnight.isQuiet(hour: 7) == false, "the end hour is when quiet stops")
        #expect(overnight.isQuiet(hour: 12) == false)

        // 09:00 → 17:00 does not cross midnight.
        let daytime = NotificationPreferences(quietHoursEnabled: true, quietStartHour: 9, quietEndHour: 17)
        #expect(daytime.isQuiet(hour: 9))
        #expect(daytime.isQuiet(hour: 16))
        #expect(daytime.isQuiet(hour: 17) == false)
        #expect(daytime.isQuiet(hour: 8) == false)

        // A window that begins and ends on the same hour is empty, not a day of silence.
        let empty = NotificationPreferences(quietHoursEnabled: true, quietStartHour: 10, quietEndHour: 10)
        #expect(empty.isQuiet(hour: 10) == false)
    }
}

// MARK: - Planner

@Suite("Notification reminder planner")
struct NotificationReminderPlannerTests {

    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func session(id: String, hoursFromNow: Double, status: StudySessionStatus = .pending) -> StudySession {
        StudySession(
            id: id,
            subject: "Databases",
            estimatedMinutes: 45,
            scheduledAt: now.addingTimeInterval(hoursFromNow * 3600),
            status: status
        )
    }

    private func plan(_ sessions: [StudySession]) -> StudyPlan {
        StudyPlan(
            id: "p1",
            input: StudyPlanInput(subjects: ["Databases"], weeklyHours: 8, intensity: .balanced),
            sessions: sessions
        )
    }

    @Test("A pending future session becomes one reminder, with a stable id")
    func reminderPerSession() {
        let reminders = NotificationReminderPlanner.reminders(
            for: plan([session(id: "s1", hoursFromNow: 5)]),
            preferences: .default,
            now: now
        )

        #expect(reminders.count == 1)
        #expect(reminders.first?.id == "reminder-s1", "the id is derived, so a re-sync replaces")
        #expect(reminders.first?.kind == .studyReminder)
        #expect(reminders.first?.target == .plan)
        #expect(reminders.first?.createdAt == now.addingTimeInterval(5 * 3600), "dated to the session")
        #expect(reminders.first?.isRead == false)
    }

    @Test("Past and finished sessions produce no reminder")
    func onlyFuturePending() {
        let reminders = NotificationReminderPlanner.reminders(
            for: plan([
                session(id: "past", hoursFromNow: -3),
                session(id: "done", hoursFromNow: 4, status: .completed),
                session(id: "skipped", hoursFromNow: 6, status: .skipped),
                session(id: "future", hoursFromNow: 8),
            ]),
            preferences: .default,
            now: now
        )

        #expect(reminders.map(\.id) == ["reminder-future"])
    }

    @Test("Turning study reminders off produces nothing")
    func mutedProducesNothing() {
        var preferences = NotificationPreferences.default
        preferences.studyReminders = false

        let reminders = NotificationReminderPlanner.reminders(
            for: plan([session(id: "s1", hoursFromNow: 5)]),
            preferences: preferences,
            now: now
        )

        #expect(reminders.isEmpty)
    }

    @Test("A session starting inside quiet hours is held back")
    func quietHoursHoldReminders() {
        let session = session(id: "s1", hoursFromNow: 5)
        // The planner reads the LOCAL hour, so the window is stated in local hours too.
        let start = Calendar.current.component(.hour, from: session.scheduledAt)
        var preferences = NotificationPreferences.default
        preferences.quietHoursEnabled = true
        preferences.quietStartHour = start
        preferences.quietEndHour = (start + 11) % 24

        let reminders = NotificationReminderPlanner.reminders(
            for: plan([session]),
            preferences: preferences,
            now: now
        )

        #expect(reminders.isEmpty, "the session starts inside the quiet window")
    }

    @Test("A plan with no sessions, or no plan, produces nothing")
    func emptyInputs() {
        #expect(NotificationReminderPlanner.reminders(for: nil, preferences: .default, now: now).isEmpty)
        #expect(NotificationReminderPlanner.reminders(for: plan([]), preferences: .default, now: now).isEmpty)
    }

    @Test("No more than the cap is produced, and the soonest come first")
    func capAndOrder() {
        let many = (1...20).map { session(id: "s\($0)", hoursFromNow: Double($0)) }

        let reminders = NotificationReminderPlanner.reminders(
            for: plan(many),
            preferences: .default,
            now: now
        )

        #expect(reminders.count == NotificationReminderPlanner.limit)
        #expect(reminders.first?.id == "reminder-s1", "the soonest session leads")
    }
}

// MARK: - Store

@Suite("Notification store")
struct NotificationStoreTests {

    private func notification(id: String, createdAt: Date) -> StudyNotification {
        StudyNotification(id: id, kind: .system, title: "T", body: "B", createdAt: createdAt)
    }

    @Test("The in-memory store returns notifications newest first")
    func inMemoryOrdersNewestFirst() async throws {
        let store = InMemoryNotificationStore(seededWith: [
            notification(id: "old", createdAt: .now.addingTimeInterval(-3600)),
            notification(id: "new", createdAt: .now),
        ])
        #expect(try await store.all().map(\.id) == ["new", "old"])
    }

    @Test("Adding the same id replaces rather than duplicates")
    func addReplacesById() async throws {
        let store = InMemoryNotificationStore()
        try await store.add(notification(id: "n1", createdAt: .now))
        var updated = notification(id: "n1", createdAt: .now)
        updated.title = "Changed"
        try await store.add(updated)

        let all = try await store.all()
        #expect(all.count == 1)
        #expect(all.first?.title == "Changed")
    }

    @Test("Marking read, marking all read and deleting behave")
    func readAndDelete() async throws {
        let store = InMemoryNotificationStore(seededWith: [
            notification(id: "n1", createdAt: .now),
            notification(id: "n2", createdAt: .now.addingTimeInterval(-60)),
        ])

        try await store.markRead(id: "n1")
        #expect(try await store.all().first { $0.id == "n1" }?.isRead == true)
        #expect(try await store.all().first { $0.id == "n2" }?.isRead == false)

        try await store.markAllRead()
        #expect(try await store.all().allSatisfy(\.isRead))

        try await store.delete(id: "n1")
        #expect(try await store.all().map(\.id) == ["n2"])
    }

    @Test("Preferences default until the student saves some")
    func preferencesDefaultAndSave() async throws {
        let store = InMemoryNotificationStore()
        #expect(try await store.preferences() == .default)

        var preferences = NotificationPreferences.default
        preferences.groupActivity = false
        try await store.savePreferences(preferences)

        #expect(try await store.preferences().groupActivity == false)
    }

    @Test("The in-memory store surfaces a forced failure")
    func inMemoryFailureIsReported() async {
        let store = InMemoryNotificationStore()
        await store.forceFailure(.storageFailed)
        await #expect(throws: NotificationError.self) {
            try await store.all()
        }
    }

    @Test("The file store persists the inbox and the choices across instances")
    func fileStorePersists() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("notification-tests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        var preferences = NotificationPreferences.default
        preferences.quizDue = false

        try await FileNotificationStore(directory: directory).add(notification(id: "n1", createdAt: .now))
        try await FileNotificationStore(directory: directory).savePreferences(preferences)

        let reopened = FileNotificationStore(directory: directory)
        #expect(try await reopened.all().map(\.id) == ["n1"])
        #expect(try await reopened.preferences().quizDue == false)
        #expect(try await reopened.preferences().studyReminders, "the untouched choices survive")
    }

    @Test("Notification failures map to the app's single user-facing error")
    func errorMapsToAppError() {
        let expected = AppError.server(reference: "notification-store-failed")
        #expect(NotificationError.storageFailed.asAppError == expected)
        #expect(AppError.from(NotificationError.storageFailed) == expected)
    }
}