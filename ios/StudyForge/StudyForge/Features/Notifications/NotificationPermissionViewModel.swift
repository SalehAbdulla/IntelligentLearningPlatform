//
//  NotificationPermissionViewModel.swift
//  StudyForge
//
//  Presentation logic for M02 (`129_Notification_Permission_Request_{M1}`) — the primer shown BEFORE
//  the system prompt.
//
//  WHY THE PRIMER IS WORTH A SCREEN
//  --------------------------------
//  iOS grants one prompt, ever. A student who taps "Don't Allow" reflexively has muted the whole
//  feature, and the app cannot ask again. So M02 does the persuading first, and the system's own
//  dialog only appears once the student has already decided they want reminders. The copy is the
//  feature: it says what the reminders are FOR, which is the thing the system dialog cannot say.
//
//  WHY IT KEEPS THE ANSWER
//  -----------------------
//  The screen has three states, not one: never asked, granted, denied. A primer that forgot which
//  answer it got would send the student back into a prompt that never appears again — the dead end
//  the design's error-state thinking exists to prevent.
//

import Foundation

@MainActor
@Observable
final class NotificationPermissionViewModel {

    private(set) var status: NotificationAuthorization = .notDetermined
    private(set) var isRequesting = false
    private(set) var error: AppError?

    private let authorizer: any NotificationAuthorizer

    init(authorizer: any NotificationAuthorizer) {
        self.authorizer = authorizer
    }

    // MARK: Derived

    /// Whether the question has been answered — by the student or by a previous launch.
    var isResolved: Bool { status != .notDetermined }

    /// What to say once the answer is in, or `nil` while it is not.
    var statusMessage: String? {
        switch status {
        case .granted: L10n.notificationPermissionGranted.string
        case .denied: L10n.notificationPermissionDenied.string
        case .notDetermined: nil
        }
    }

    /// The permission was refused, so the enable button must not promise a prompt that will not come.
    var isDenied: Bool { status == .denied }

    // MARK: Copy

    var title: String { L10n.notificationPermissionTitle.string }
    var body: String { L10n.notificationPermissionBody.string }
    var enableTitle: String { L10n.notificationPermissionEnable.string }
    var notNowTitle: String { L10n.notificationPermissionNotNow.string }

    // MARK: Actions

    /// Reads the standing answer without prompting.
    func load() async {
        status = await authorizer.currentStatus()
    }

    /// Shows the system prompt and records what the student chose.
    ///
    /// Guarded so the prompt cannot be asked for twice from this screen — a second request while the
    /// status is already settled does nothing, because there is nothing the system will show.
    func enable() async {
        guard !isRequesting, status == .notDetermined else { return }
        isRequesting = true
        defer { isRequesting = false }
        status = await authorizer.requestAuthorization()
    }
}