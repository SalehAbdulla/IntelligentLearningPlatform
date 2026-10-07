//
//  AuditLogViewModel.swift
//  StudyForge
//
//  Presentation logic for K08 (`116_Admin_AuditLog_{M4}`, docs/03 section K): the append-only trail as
//  a filterable, exportable screen.
//
//  WHY IT FILTERS THE VISIBLE SET AND EXPORTS THAT SAME SET
//  -------------------------------------------------------
//  K08 asks for a filterable trail with an export. Exporting something OTHER than what is on screen is
//  how an audit tool lies: the admin narrows to one actor, taps export, and gets the whole trail. The
//  export is built from `visibleEntries`, so what leaves the screen is what the screen shows.
//

import Foundation

@MainActor
@Observable
final class AuditLogViewModel {

    // MARK: Bound state

    var query = ""
    var actorFilter: String?
    var actionFilter: AuditAction?

    // MARK: Derived state

    private(set) var state: LoadState<[AuditEntry]> = .idle
    private(set) var error: AppError?

    private let audit: any AIConfigurationStore

    init(audit: any AIConfigurationStore) {
        self.audit = audit
    }

    // MARK: Derived

    var entries: [AuditEntry] { state.value ?? [] }
    var isLoading: Bool { state.isLoading }

    /// Every actor that actually appears in the trail, sorted.
    ///
    /// Derived from the data rather than from the roster: offering a name that never acted would be a
    /// filter that can only ever return nothing.
    var actors: [String] { Array(Set(entries.map(\.actorName))).sorted() }

    /// The actions that actually appear, kept in the enum's canonical order.
    var actions: [AuditAction] {
        let present = Set(entries.map(\.action))
        return AuditAction.allCases.filter { present.contains($0) }
    }

    /// The entries the current filters and search leave visible, newest first.
    var visibleEntries: [AuditEntry] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return entries.filter { entry in
            let matchesActor = actorFilter == nil || entry.actorName == actorFilter
            let matchesAction = actionFilter == nil || entry.action == actionFilter
            let matchesQuery = needle.isEmpty
                || entry.actorName.lowercased().contains(needle)
                || entry.action.title.lowercased().contains(needle)
                || entry.detail.lowercased().contains(needle)
            return matchesActor && matchesAction && matchesQuery
        }
    }

    /// True when the trail has entries but the filters hid them all, a different state from an empty
    /// trail and the one that needs different copy.
    var isFilteredEmpty: Bool { !entries.isEmpty && visibleEntries.isEmpty }

    // MARK: Copy

    var title: String { L10n.adminAuditLogTitle.string }
    var searchPlaceholder: String { L10n.adminAuditLogSearchPlaceholder.string }
    var actorLabel: String { L10n.adminAuditLogActors.string }
    var actionLabel: String { L10n.adminAuditLogActions.string }
    var allActorsTitle: String { L10n.adminAuditLogAllActors.string }
    var allActionsTitle: String { L10n.adminAuditLogAllActions.string }
    var emptyTitle: String { L10n.adminAuditLogEmptyTitle.string }
    var emptyBody: String { L10n.adminAuditLogEmptyBody.string }
    var filteredEmptyTitle: String { L10n.adminAuditLogFilteredEmptyTitle.string }
    var filteredEmptyBody: String { L10n.adminAuditLogFilteredEmptyBody.string }
    var exportTitle: String { L10n.adminAuditLogExport.string }
    var exportFileName: String { L10n.adminAuditLogExportFileName.string }
    var appendOnlyNote: String { L10n.adminAuditLogAppendOnly.string }

    /// "Action, Actor" for one row, so the list reads as a sentence.
    func entryTitle(_ entry: AuditEntry) -> String {
        L10n.adminAuditLogEntry.string(entry.action.title, entry.actorName)
    }

    func timestampTitle(_ entry: AuditEntry) -> String {
        entry.createdAt.formatted(date: .abbreviated, time: .shortened)
    }

    func actorMenuTitle() -> String { actorFilter ?? allActorsTitle }
    func actionMenuTitle() -> String { actionFilter?.title ?? allActionsTitle }

    // MARK: Loading

    func load() async {
        state = .loading
        error = nil
        do {
            let entries = try await audit.auditLog()
            state = entries.isEmpty ? .empty : .loaded(entries)
        } catch {
            state = .failed(AppError.from(error))
        }
    }

    // MARK: Export (K08)

    /// The visible trail as CSV, one line per entry, with a header row.
    ///
    /// Built from `visibleEntries`, so the export matches the screen. Fields are quoted and embedded
    /// quotes doubled, which is the CSV rule that keeps a comma inside a detail sentence from splitting
    /// a row.
    var exportText: String {
        let formatter = ISO8601DateFormatter()
        var lines = ["Actor,Action,Detail,Timestamp"]
        for entry in visibleEntries {
            let fields = [
                csvField(entry.actorName),
                csvField(entry.action.title),
                csvField(entry.detail),
                csvField(formatter.string(from: entry.createdAt)),
            ]
            lines.append(fields.joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    private func csvField(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

}
