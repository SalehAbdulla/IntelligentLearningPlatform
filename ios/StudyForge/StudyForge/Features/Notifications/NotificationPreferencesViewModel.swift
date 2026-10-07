//
//  NotificationPreferencesViewModel.swift
//  StudyForge
//
//  Presentation logic for B09 (`19_Settings_Notifications_{M1}`) — the per-type toggles and quiet
//  hours.
//
//  WHY THE BOUND VALUES ARE COPIES
//  -------------------------------
//  The screen edits a working copy and writes it on Save, so a half-changed set of toggles is never
//  persisted by a stray tap. That is the same shape B07 uses for the profile: read once, edit
//  locally, write on Save.
//

import Foundation

@MainActor
@Observable
final class NotificationPreferencesViewModel {

    // MARK: Bound state

    var studyReminders = true
    var quizDue = true
    var groupActivity = true
    var quietHoursEnabled = false
    var quietStartHour = 22
    var quietEndHour = 7

    /// What a test reminder did, so the screen can say so rather than look inert.
    enum TestReminderOutcome: Equatable {
        case idle
        case sent
        case denied
    }

    private(set) var isLoading = false
    private(set) var isSaving = false
    private(set) var didSave = false
    private(set) var error: AppError?

    /// What the last "send a test reminder" tap did. `.idle` until the student tries it.
    private(set) var testReminderOutcome: TestReminderOutcome = .idle
    private(set) var isSendingTestReminder = false

    private let store: any NotificationStore
    private let authorizer: any NotificationAuthorizer
    private let scheduler: any NotificationScheduler

    init(
        store: any NotificationStore,
        authorizer: any NotificationAuthorizer = InMemoryNotificationAuthorizer(),
        scheduler: any NotificationScheduler = InMemoryNotificationScheduler()
    ) {
        self.store = store
        self.authorizer = authorizer
        self.scheduler = scheduler
    }

    // MARK: Derived

    /// The kinds B09 offers a switch for — everything the student can reasonably mute.
    var muteableKinds: [NotificationKind] { NotificationKind.allCases.filter(\.isMuteable) }

    /// Every hour of the day, for the quiet-hours pickers.
    var hours: [Int] { Array(0..<24) }

    /// The current edits, as a value to save.
    var preferences: NotificationPreferences {
        NotificationPreferences(
            studyReminders: studyReminders,
            quizDue: quizDue,
            groupActivity: groupActivity,
            quietHoursEnabled: quietHoursEnabled,
            quietStartHour: quietStartHour,
            quietEndHour: quietEndHour
        )
    }

    // MARK: Copy

    var title: String { L10n.notificationSettingsTitle.string }
    var quietHoursTitle: String { L10n.notificationQuietHours.string }
    var quietHoursCaption: String { L10n.notificationQuietHoursCaption.string }
    var saveTitle: String { L10n.notificationSave.string }
    var savingTitle: String { L10n.notificationSaving.string }
    var savedTitle: String { L10n.notificationSaved.string }

    /// "22:00" — a clock reading, so only the digits are formatted, not the words around them.
    func hourTitle(_ hour: Int) -> String { String(format: "%02d:00", hour) }

    /// The current value of one muteable kind's switch.
    func isOn(_ kind: NotificationKind) -> Bool {
        switch kind {
        case .studyReminder: studyReminders
        case .quizDue: quizDue
        case .groupActivity: groupActivity
        case .achievement, .system: true
        }
    }

    /// Sets one muteable kind's switch.
    func setOn(_ kind: NotificationKind, _ value: Bool) {
        switch kind {
        case .studyReminder: studyReminders = value
        case .quizDue: quizDue = value
        case .groupActivity: groupActivity = value
        case .achievement, .system: break
        }
    }

    // MARK: Actions

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let stored = try await store.preferences()
            studyReminders = stored.studyReminders
            quizDue = stored.quizDue
            groupActivity = stored.groupActivity
            quietHoursEnabled = stored.quietHoursEnabled
            quietStartHour = stored.quietStartHour
            quietEndHour = stored.quietEndHour
        } catch {
            self.error = AppError.from(error)
        }
    }

    func save() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        error = nil

        do {
            try await store.savePreferences(preferences)
            didSave = true
        } catch {
            self.error = AppError.from(error)
        }
    }

    /// Sends one reminder right now, so notifications can be demonstrated and verified on demand:
    /// `docs/11` §6 needs the reminder to fire during the demo.
    ///
    /// Permission is resolved first through the same seam M02 uses: undecided prompts, granted
    /// proceeds, denied is reported. A "sent" that never appeared would be the worst possible demo
    /// answer, so the outcome is always one the screen can show.
    func sendTestReminder() async {
        guard !isSendingTestReminder else { return }
        isSendingTestReminder = true
        defer { isSendingTestReminder = false }

        var status = await authorizer.currentStatus()
        if status == .notDetermined {
            status = await authorizer.requestAuthorization()
        }

        guard status.allowsDelivery else {
            testReminderOutcome = .denied
            return
        }

        await scheduler.deliver(
            StudyNotification(
                kind: .studyReminder,
                title: L10n.notificationTestReminder.string,
                body: L10n.notificationTestReminderBody.string
            )
        )
        testReminderOutcome = .sent
    }
}