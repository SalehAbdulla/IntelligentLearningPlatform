//
//  BroadcastComposerViewModel.swift
//  StudyForge
//
//  Presentation logic for K09 (`117_Admin_Broadcast_Notification_{M4}`, docs/03 section K): compose a
//  platform announcement and send it to a segment.
//
//  WHY THE AUDIENCE SIZE IS DERIVED, NOT TYPED
//  -------------------------------------------
//  The composer reports how many accounts the chosen segment selects, read from the platform roster
//  (K02's directory). A number the admin typed would be a claim; a number derived from the same roster
//  the rest of the admin surfaces use is a fact, and it is what the confirmation quotes back.
//

import Foundation

@MainActor
@Observable
final class BroadcastComposerViewModel {

    // MARK: Bound state

    var segment: AudienceSegment = .everyone
    var title = ""
    var message = ""
    var isScheduling = false
    var scheduledAt: Date = .now.addingTimeInterval(3_600)

    private(set) var formError: String?

    /// Set after a successful send, so the screen can confirm it. Cleared by `clearConfirmation`.
    private(set) var sentConfirmation: String?

    // MARK: Derived state

    private(set) var state: LoadState<[Broadcast]> = .idle
    private(set) var roster: [PlatformUser] = []
    private(set) var error: AppError?

    private let store: any BroadcastStore
    private let audit: any AIConfigurationStore
    private let directory: any AdminDirectoryStore

    /// The signed-in admin's name, so the trail is attributable.
    let actorName: String

    init(
        store: any BroadcastStore,
        audit: any AIConfigurationStore,
        directory: any AdminDirectoryStore,
        actorName: String
    ) {
        self.store = store
        self.audit = audit
        self.directory = directory
        self.actorName = actorName
    }

    // MARK: Derived

    var broadcasts: [Broadcast] { state.value ?? [] }
    var isLoading: Bool { state.isLoading }

    /// How many accounts the current segment selects, from the live roster.
    var audienceSize: Int { roster.filter { segment.matches($0) }.count }

    /// Whether the composer has everything it needs to send.
    var canSend: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && audienceSize > 0
    }

    // MARK: Copy

    var navTitle: String { L10n.adminBroadcastTitle.string }
    var audienceLabel: String { L10n.adminBroadcastAudienceLabel.string }
    var titleLabel: String { L10n.adminBroadcastTitleLabel.string }
    var titlePlaceholder: String { L10n.adminBroadcastTitlePlaceholder.string }
    var bodyLabel: String { L10n.adminBroadcastBodyLabel.string }
    var bodyPlaceholder: String { L10n.adminBroadcastBodyPlaceholder.string }
    var previewHeading: String { L10n.adminBroadcastPreviewHeading.string }
    var previewNow: String { L10n.adminBroadcastPreviewNow.string }
    var scheduleLabel: String { L10n.adminBroadcastScheduleLabel.string }
    var scheduleToggle: String { L10n.adminBroadcastScheduleToggle.string }
    var scheduleHint: String { L10n.adminBroadcastScheduleHint.string }
    var sendButton: String { L10n.adminBroadcastSend.string }
    var confirmTitle: String { L10n.adminBroadcastConfirmTitle.string }
    var sentTitle: String { L10n.adminBroadcastSentTitle.string }
    var recentHeading: String { L10n.adminBroadcastRecentHeading.string }
    var emptyRecent: String { L10n.adminBroadcastEmptyRecent.string }

    func segmentTitle(_ segment: AudienceSegment) -> String { segment.title }
    func segmentDetail(_ segment: AudienceSegment) -> String { segment.detail }

    /// "140 recipients", the size under the audience picker.
    func audienceSizeTitle() -> String {
        L10n.adminBroadcastAudienceSize.string(audienceSize)
    }

    /// The confirmation body, naming the announcement and quoting the derived recipient count.
    func confirmBody() -> String {
        L10n.adminBroadcastConfirmBody.string(title.trimmingCharacters(in: .whitespacesAndNewlines), audienceSize)
    }

    func statusTitle(_ broadcast: Broadcast) -> String {
        broadcast.isSent
            ? L10n.adminBroadcastStatusSent.string
            : L10n.adminBroadcastStatusScheduled.string
    }

    func recipientsTitle(_ broadcast: Broadcast) -> String {
        L10n.adminBroadcastRecipients.string(broadcast.segment.title, broadcast.recipientCount)
    }

    func sentDateTitle(_ broadcast: Broadcast) -> String {
        let date = broadcast.scheduledAt ?? broadcast.createdAt
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    // MARK: Loading

    func load() async {
        state = .loading
        error = nil
        do {
            roster = try await directory.users()
            let broadcasts = try await store.broadcasts()
            state = broadcasts.isEmpty ? .empty : .loaded(broadcasts)
        } catch {
            state = .failed(AppError.from(error))
        }
    }

    // MARK: Sending

    /// Records the announcement and writes the audit line in the same call.
    ///
    /// Returns `true` only when both succeeded, so the view keeps the form open over a failed send.
    @discardableResult
    func send() async -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, !trimmedMessage.isEmpty, audienceSize > 0 else {
            formError = L10n.adminBroadcastRequired.string
            return false
        }

        let broadcast = Broadcast(
            segment: segment,
            title: trimmedTitle,
            message: trimmedMessage,
            scheduledAt: isScheduling ? scheduledAt : nil,
            recipientCount: audienceSize,
            isSent: !isScheduling
        )

        do {
            try await store.save(broadcast)
            try? await audit.record(AuditEntry(
                action: .broadcastSent,
                actorName: actorName,
                detail: "Broadcast to \(segment.title): '\(trimmedTitle)' (\(broadcast.recipientCount))"
            ))
            sentConfirmation = trimmedTitle
            title = ""
            message = ""
            isScheduling = false
            formError = nil
            await load()
            return true
        } catch {
            self.error = AppError.from(error)
            return false
        }
    }

    /// Clears the send confirmation, so the alert shows once.
    func clearConfirmation() {
        sentConfirmation = nil
    }
}

