//
//  ModerationQueueViewModel.swift
//  StudyForge
//
//  Presentation logic for K04 (`112_Admin_Moderation_Queue_{M4}`) and the decision panel K05
//  (`113_Admin_FlaggedReports_{M4}`) requires (docs/03 section K).
//
//  WHY EVERY DECISION DEMANDS A REASON
//  ----------------------------------
//  K05 makes the reason mandatory, and the reason is the whole point: "removed by an admin" is not an
//  audit line, "removed because it doxxed a classmate" is. The decision write is refused until a reason
//  exists, so a record can never be created without one rather than relying on a reviewer to notice.
//

import Foundation

/// The decisions an admin can record on a report (K04's action row).
enum ModerationDecision: String, CaseIterable, Sendable, Identifiable {
    case keep
    case remove
    case escalate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .keep: L10n.adminModerationKeep.string
        case .remove: L10n.adminModerationRemove.string
        case .escalate: L10n.adminModerationEscalate.string
        }
    }

    /// What the decision means, shown under the action so it cannot be tapped blindly.
    var body: String {
        switch self {
        case .keep: L10n.adminModerationKeepBody.string
        case .remove: L10n.adminModerationRemoveBody.string
        case .escalate: L10n.adminModerationEscalateBody.string
        }
    }

    /// The status the report takes once the decision is recorded.
    var resultingStatus: ReportStatus {
        switch self {
        case .keep: .approved
        case .remove: .removed
        case .escalate: .escalated
        }
    }

    /// The audit action the decision writes, so the trail names the decision rather than "moderated".
    var auditAction: AuditAction {
        switch self {
        case .keep: .moderationApproved
        case .remove: .moderationRemoved
        case .escalate: .moderationEscalated
        }
    }

    var isDestructive: Bool { self == .remove }
}

@MainActor
@Observable
final class ModerationQueueViewModel {

    // MARK: Bound state

    var reasonFilter: ReportReason?

    /// Whether already-decided reports stay in the list. Off by default: the queue's job is the
    /// remaining work, and a decided item sitting among pending ones slows that down.
    var showsDecided = false

    /// Set when a decision is attempted with no reason. Cleared by `clearReasonError`.
    ///
    /// The reason STRING itself is held by the detail sheet, not the model: only the sheet edits it, and
    /// keeping it there means switching reports cannot carry the previous reason over. The model keeps
    /// the validation RESULT, which is the part the model owns.
    private(set) var reasonError: String?

    // MARK: Derived state

    private(set) var state: LoadState<[ContentReport]> = .idle
    private(set) var error: AppError?

    private let store: any ModerationStore
    private let audit: any AIConfigurationStore

    /// The signed-in admin's name, so the trail is attributable.
    let actorName: String

    init(store: any ModerationStore, audit: any AIConfigurationStore, actorName: String) {
        self.store = store
        self.audit = audit
        self.actorName = actorName
    }

    // MARK: Derived

    var reports: [ContentReport] { state.value ?? [] }
    var isLoading: Bool { state.isLoading }

    /// The reports the current filter leaves visible: pending only, unless decided ones are shown.
    var visibleReports: [ContentReport] {
        reports
            .filter { showsDecided || $0.isPending }
            .filter { reasonFilter == nil || $0.reason == reasonFilter }
    }

    /// How many reports still need a decision.
    var openCount: Int { reports.filter(\.isPending).count }

    /// True when reports exist but the filter hid them all, a different state from an empty queue.
    var isFilteredEmpty: Bool { !reports.isEmpty && visibleReports.isEmpty }

    /// One report by id, re-read so the detail sheet reflects a decision the moment it is saved.
    func report(id: String) -> ContentReport? { reports.first { $0.id == id } }

    // MARK: Copy

    var title: String { L10n.adminModerationTitle.string }
    var emptyTitle: String { L10n.adminModerationEmptyTitle.string }
    var emptyBody: String { L10n.adminModerationEmptyBody.string }
    var filteredEmptyTitle: String { L10n.adminModerationFilteredEmptyTitle.string }
    var filteredEmptyBody: String { L10n.adminModerationFilteredEmptyBody.string }
    var allReasonsTitle: String { L10n.adminModerationFilterAll.string }
    var contentLabel: String { L10n.adminModerationContentLabel.string }
    var reporterLabel: String { L10n.adminModerationReporterLabel.string }
    var reasonLabel: String { L10n.adminModerationReasonLabel.string }
    var decideHeading: String { L10n.adminModerationDecideHeading.string }
    var reasonPlaceholder: String { L10n.adminModerationReasonPlaceholder.string }
    var showDecidedTitle: String { L10n.adminModerationShowDecided.string }
    var detailTitle: String { L10n.adminModerationDetailTitle.string }
    var statusLabel: String { L10n.adminModerationStatusLabel.string }
    var ageLabel: String { L10n.adminModerationAgeLabel.string }
    var decisionLabel: String { L10n.adminModerationDecisionLabel.string }

    func openCountTitle() -> String { L10n.adminModerationOpenCount.string(openCount) }
    func reasonTitle(_ report: ContentReport) -> String { report.reason.title }
    func kindTitle(_ report: ContentReport) -> String { report.kind.title }
    func statusTitle(_ report: ContentReport) -> String { report.status.title }

    /// "Reported by Sara Ali", the attribution line under a queue row.
    func reporterTitle(_ report: ContentReport) -> String {
        L10n.adminModerationReportedBy.string(report.reporterName)
    }

    /// "Today" or "3 days ago", so an old report stands out from a fresh one.
    func ageTitle(_ report: ContentReport, now: Date = .now) -> String {
        let days = report.ageDays(now: now)
        return days == 0
            ? L10n.adminModerationAgeToday.string
            : L10n.adminModerationAgeDays.string(days)
    }

    // MARK: Loading

    func load() async {
        state = .loading
        error = nil
        do {
            let reports = try await store.reports()
            state = reports.isEmpty ? .empty : .loaded(reports)
        } catch {
            state = .failed(AppError.from(error))
        }
    }

    // MARK: Decisions

    /// Records a decision on a report, and writes the audit line in the same call.
    ///
    /// Returns `true` only when the report was saved AND the trail was written, so the caller can keep
    /// the detail sheet open rather than dismiss it over a save that did not happen. The reason is
    /// required: an empty one sets `reasonError` and the write is refused.
    @discardableResult
    func decide(_ decision: ModerationDecision, for report: ContentReport, reason: String) async -> Bool {
        let trimmed = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            reasonError = L10n.adminModerationReasonRequired.string
            return false
        }

        var updated = report
        updated.status = decision.resultingStatus
        updated.decisionReason = trimmed

        do {
            try await store.save(updated)
            try await audit.record(AuditEntry(
                action: decision.auditAction,
                actorName: actorName,
                detail: "\(report.contentTitle): \(decision.title) - \(trimmed)"
            ))
            reasonError = nil
            await load()
            return true
        } catch {
            self.error = AppError.from(error)
            return false
        }
    }

    /// Clears the validation error, so a fresh attempt starts clean.
    func clearReasonError() {
        reasonError = nil
    }
}

