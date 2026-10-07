//
//  NotificationViewModelTests.swift
//  StudyForgeTests
//
//  Tests for the F14 inbox, preferences and permission-primer flows.
//

import Foundation
import Testing
@testable import StudyForge
// TODO(M3 · F14): Add a test that quiet hours suppress a scheduled reminder, and that a
// reminder outside quiet hours is delivered. Done when both cases have a test here and the
// suite passes.

@Suite("Notifications inbox (F14)")
@MainActor
struct NotificationsInboxViewModelTests {

    private func notification(
        id: String,
        createdAt: Date,
        isRead: Bool = false
    ) -> StudyNotification {
        StudyNotification(id: id, kind: .system, title: "T\(id)", body: "B", isRead: isRead, createdAt: createdAt)
    }

    private func model(
        notifications: [StudyNotification] = [],
        plans: [StudyPlan] = [],
        preferences: NotificationPreferences = .default
    ) -> NotificationsInboxViewModel {
        NotificationsInboxViewModel(
            store: InMemoryNotificationStore(seededWith: notifications, preferences: preferences),
            plans: InMemoryStudyPlanStore(seededWith: plans)
        )
    }

    @Test("An empty inbox shows the empty state")
    func emptyStore() async {
        let viewModel = model()
        await viewModel.load()
        #expect(viewModel.isEmpty)
        #expect(viewModel.hasUnread == false)
    }

    @Test("Loading folds the plan's reminders into the inbox, once per session")
    func loadSyncsPlanReminders() async {
        let plan = StudyPlan(
            id: "p1",
            input: StudyPlanInput(subjects: ["Databases"], weeklyHours: 8, intensity: .balanced),
            sessions: [
                StudySession(id: "s1", subject: "Databases", estimatedMinutes: 45,
                             scheduledAt: .now.addingTimeInterval(3600)),
            ]
        )
        let viewModel = model(plans: [plan])

        await viewModel.load()
        await viewModel.load()   // a second open must not duplicate

        #expect(viewModel.notifications.count == 1)
        #expect(viewModel.notifications.first?.id == "reminder-s1")
        #expect(viewModel.hasUnread)
    }

    @Test("Turning study reminders off keeps the inbox empty even with a plan")
    func mutedPlanProducesNothing() async {
        var preferences = NotificationPreferences.default
        preferences.studyReminders = false
        let plan = StudyPlan(
            id: "p1",
            input: StudyPlanInput(subjects: ["Databases"], weeklyHours: 8, intensity: .balanced),
            sessions: [
                StudySession(id: "s1", subject: "Databases", estimatedMinutes: 45,
                             scheduledAt: .now.addingTimeInterval(3600)),
            ]
        )

        let viewModel = model(plans: [plan], preferences: preferences)
        await viewModel.load()

        #expect(viewModel.isEmpty)
    }

    @Test("The inbox groups by day, newest group first")
    func sectionsGroupByDay() async {
        let viewModel = model(notifications: [
            notification(id: "today", createdAt: .now),
            notification(id: "yesterday", createdAt: .now.addingTimeInterval(-86_400)),
            notification(id: "earlier", createdAt: .now.addingTimeInterval(-5 * 86_400)),
        ])

        await viewModel.load()

        #expect(viewModel.sections.map(\.id) == ["today", "yesterday", "earlier"])
        #expect(viewModel.sections.first?.title == L10n.notificationToday.string)
        #expect(viewModel.sections.last?.items.map(\.id) == ["earlier"])
    }

    @Test("An empty day group is left out rather than shown as a heading")
    func emptyGroupsAreOmitted() async {
        let viewModel = model(notifications: [notification(id: "today", createdAt: .now)])
        await viewModel.load()
        #expect(viewModel.sections.map(\.id) == ["today"])
    }

    @Test("Marking read, marking all read and deleting update the inbox")
    func readAndDelete() async {
        let viewModel = model(notifications: [
            notification(id: "n1", createdAt: .now),
            notification(id: "n2", createdAt: .now.addingTimeInterval(-60)),
        ])
        await viewModel.load()
        #expect(viewModel.unreadCount == 2)

        await viewModel.markRead(viewModel.notifications.first { $0.id == "n1" }!)
        #expect(viewModel.unreadCount == 1)

        await viewModel.markAllRead()
        #expect(viewModel.unreadCount == 0)
        #expect(viewModel.hasUnread == false)

        await viewModel.delete(viewModel.notifications.first { $0.id == "n1" }!)
        #expect(viewModel.notifications.map(\.id) == ["n2"])
    }

    @Test("Every string comes from the catalogue")
    func copyIsLocalised() {
        let viewModel = model()
        #expect(viewModel.title == L10n.notificationInboxTitle.string)
        #expect(viewModel.emptyTitle == L10n.notificationEmptyTitle.string)
        #expect(viewModel.markAllReadTitle == L10n.notificationMarkAllRead.string)
        #expect(viewModel.unreadTitle(2) == L10n.notificationUnread.string(2))
    }
}

@Suite("Notification preferences (F14)")
@MainActor
struct NotificationPreferencesViewModelTests {

    @Test("Loading reads the stored choices, and the defaults when none are saved")
    func loadReadsStoredChoices() async {
        let store = InMemoryNotificationStore()
        let viewModel = NotificationPreferencesViewModel(store: store)

        await viewModel.load()

        #expect(viewModel.studyReminders)
        #expect(viewModel.quizDue)
        #expect(viewModel.groupActivity)
        #expect(viewModel.quietHoursEnabled == false)
    }

    @Test("Only the muteable kinds are offered as switches")
    func muteableKindsOnly() {
        let viewModel = NotificationPreferencesViewModel(store: InMemoryNotificationStore())
        #expect(viewModel.muteableKinds == [.studyReminder, .quizDue, .groupActivity])
    }

    @Test("Setting a kind's switch reads back, and unnoticed kinds stay on")
    func setAndReadBack() {
        let viewModel = NotificationPreferencesViewModel(store: InMemoryNotificationStore())

        viewModel.setOn(.groupActivity, false)

        #expect(viewModel.isOn(.groupActivity) == false)
        #expect(viewModel.isOn(.quizDue))
        #expect(viewModel.preferences.allows(.groupActivity) == false)
    }

    @Test("Saving writes the working copy, and a reload reads it back")
    func savePersists() async {
        let store = InMemoryNotificationStore()
        let viewModel = NotificationPreferencesViewModel(store: store)

        await viewModel.load()
        viewModel.setOn(.quizDue, false)
        viewModel.quietHoursEnabled = true
        viewModel.quietStartHour = 23
        viewModel.quietEndHour = 6
        await viewModel.save()

        #expect(viewModel.didSave)
        let reloaded = NotificationPreferencesViewModel(store: store)
        await reloaded.load()
        #expect(reloaded.quizDue == false)
        #expect(reloaded.quietHoursEnabled)
        #expect(reloaded.quietStartHour == 23)
        #expect(reloaded.quietEndHour == 6)
    }

    @Test("An hour reads as a clock time, and there are 24 of them")
    func hourTitles() {
        let viewModel = NotificationPreferencesViewModel(store: InMemoryNotificationStore())
        #expect(viewModel.hourTitle(7) == "07:00")
        #expect(viewModel.hourTitle(22) == "22:00")
        #expect(viewModel.hours.count == 24)
    }

    @Test("A store that refuses the write is reported rather than swallowed")
    func storeFailureIsReported() async {
        let store = InMemoryNotificationStore()
        let viewModel = NotificationPreferencesViewModel(store: store)
        await store.forceFailure(.storageFailed)

        await viewModel.save()

        #expect(viewModel.error == AppError.server(reference: "notification-store-failed"))
        #expect(viewModel.didSave == false)
    }

    // MARK: Test reminder

    @Test("Sending a test reminder delivers one, and says so")
    func testReminderDelivers() async {
        let scheduler = InMemoryNotificationScheduler()
        let viewModel = NotificationPreferencesViewModel(
            store: InMemoryNotificationStore(),
            authorizer: InMemoryNotificationAuthorizer(status: .granted),
            scheduler: scheduler
        )

        await viewModel.sendTestReminder()

        #expect(scheduler.deliveredNotifications.count == 1)
        #expect(scheduler.deliveredNotifications.first?.kind == .studyReminder)
        #expect(viewModel.testReminderOutcome == .sent)
    }

    @Test("An undecided permission is prompted before anything is sent")
    func testReminderPromptsWhenUndecided() async {
        let scheduler = InMemoryNotificationScheduler()
        let viewModel = NotificationPreferencesViewModel(
            store: InMemoryNotificationStore(),
            authorizer: InMemoryNotificationAuthorizer(status: .notDetermined, outcome: .granted),
            scheduler: scheduler
        )

        await viewModel.sendTestReminder()

        #expect(scheduler.deliveredNotifications.count == 1)
    }

    @Test("A denied permission sends nothing, and says so rather than looking inert")
    func testReminderDeniedSendsNothing() async {
        let scheduler = InMemoryNotificationScheduler()
        let viewModel = NotificationPreferencesViewModel(
            store: InMemoryNotificationStore(),
            authorizer: InMemoryNotificationAuthorizer(status: .denied),
            scheduler: scheduler
        )

        await viewModel.sendTestReminder()

        #expect(scheduler.deliveredNotifications.isEmpty)
        #expect(viewModel.testReminderOutcome == .denied)
    }

    @Test("Every string comes from the catalogue")
    func copyIsLocalised() {
        let viewModel = NotificationPreferencesViewModel(store: InMemoryNotificationStore())
        #expect(viewModel.title == L10n.notificationSettingsTitle.string)
        #expect(viewModel.quietHoursTitle == L10n.notificationQuietHours.string)
        #expect(viewModel.saveTitle == L10n.notificationSave.string)
    }
}

@Suite("Notification permission primer (F14)")
@MainActor
struct NotificationPermissionViewModelTests {

    @Test("A fresh install is unresolved until the student answers")
    func notDetermined() async {
        let viewModel = NotificationPermissionViewModel(authorizer: InMemoryNotificationAuthorizer())

        await viewModel.load()

        #expect(viewModel.isResolved == false)
        #expect(viewModel.statusMessage == nil)
    }

    @Test("Enabling asks the system once and records the answer")
    func enableRecordsAnswer() async {
        let authorizer = InMemoryNotificationAuthorizer(outcome: .granted)
        let viewModel = NotificationPermissionViewModel(authorizer: authorizer)

        await viewModel.load()
        await viewModel.enable()

        #expect(viewModel.status == .granted)
        #expect(viewModel.statusMessage == L10n.notificationPermissionGranted.string)
        #expect(viewModel.isDenied == false)
    }

    @Test("A declined prompt is remembered as declined, with its own message")
    func deniedIsRemembered() async {
        let authorizer = InMemoryNotificationAuthorizer(outcome: .denied)
        let viewModel = NotificationPermissionViewModel(authorizer: authorizer)

        await viewModel.load()
        await viewModel.enable()

        #expect(viewModel.status == .denied)
        #expect(viewModel.isDenied)
        #expect(viewModel.statusMessage == L10n.notificationPermissionDenied.string)
    }

    @Test("An already-answered install no longer offers the prompt")
    func alreadyAnswered() async {
        let viewModel = NotificationPermissionViewModel(
            authorizer: InMemoryNotificationAuthorizer(status: .granted)
        )

        await viewModel.load()

        #expect(viewModel.isResolved)
        // Asking again would be a no-op, so the enable button is hidden rather than shown inert.
        await viewModel.enable()
        #expect(viewModel.status == .granted)
    }

    @Test("Every string comes from the catalogue")
    func copyIsLocalised() {
        let viewModel = NotificationPermissionViewModel(authorizer: InMemoryNotificationAuthorizer())
        #expect(viewModel.title == L10n.notificationPermissionTitle.string)
        #expect(viewModel.body == L10n.notificationPermissionBody.string)
        #expect(viewModel.enableTitle == L10n.notificationPermissionEnable.string)
        #expect(viewModel.notNowTitle == L10n.notificationPermissionNotNow.string)
    }
}