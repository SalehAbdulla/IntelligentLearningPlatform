//
//  AuditLogView.swift
//  StudyForge
//
//  K08: `116_Admin_AuditLog_{M4}` (docs/03 section K, P1). The audit trail the app already writes, as a
//  filterable and exportable screen rather than a footnote inside the AI settings page.
//
//  WHY THIS IS ITS OWN SCREEN AND NOT A SECTION
//  --------------------------------------------
//  The trail was written by K03 and K07 and shown inline on K07. That made it a by-product of one
//  screen: reachable only after opening AI settings, and impossible to filter by actor. K08 is what
//  turns "we log admin actions" into something an auditor can actually use, which is the claim the
//  security model makes (docs/05 section 9).
//

import SwiftUI

// Accessibility: the export button and the actor/action filters are labelled, the type glyph is hidden, and
// each log row reads as one element.

struct AuditLogView: View {

    @State private var viewModel: AuditLogViewModel

    init(audit: any AIConfigurationStore) {
        _viewModel = State(initialValue: AuditLogViewModel(audit: audit))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
                    .padding(Layout.screenMargin)
            } else if viewModel.entries.isEmpty {
                emptyState
            } else if viewModel.isFilteredEmpty {
                filteredEmptyState
            } else {
                list
            }
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.query, prompt: Text(viewModel.searchPlaceholder))
        .toolbar {
            ToolbarItem(placement: .primaryAction) { actorFilterMenu }
            ToolbarItem(placement: .primaryAction) { actionFilterMenu }
            ToolbarItem(placement: .primaryAction) { exportButton }
        }
        .task { await viewModel.load() }
    }

    private var exportButton: some View {
        ShareLink(item: viewModel.exportText, preview: SharePreview(viewModel.exportFileName)) {
            Label(viewModel.exportTitle, systemImage: "square.and.arrow.up")
        }
        .disabled(viewModel.visibleEntries.isEmpty)
        .accessibilityLabel(viewModel.exportTitle)
    }

    private var actorFilterMenu: some View {
        Menu {
            Button(viewModel.allActorsTitle) { viewModel.actorFilter = nil }
            ForEach(viewModel.actors, id: \.self) { actor in
                Button(actor) { viewModel.actorFilter = actor }
            }
        } label: {
            Image(systemName: "person.crop.circle")
        }
        .accessibilityLabel("\(viewModel.actorLabel): \(viewModel.actorMenuTitle())")
    }

    private var actionFilterMenu: some View {
        Menu {
            Button(viewModel.allActionsTitle) { viewModel.actionFilter = nil }
            ForEach(viewModel.actions) { action in
                Button(action.title) { viewModel.actionFilter = action }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel("\(viewModel.actionLabel): \(viewModel.actionMenuTitle())")
    }

    private var list: some View {
        List {
            ForEach(viewModel.visibleEntries) { entry in
                row(entry)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func row(_ entry: AuditEntry) -> some View {
        HStack(alignment: .top, spacing: Spacing.s3) {
            Image(systemName: entry.action.symbolName)
                .font(.sfBody)
                .foregroundStyle(ColorTokens.primary)
                .frame(minWidth: Spacing.s6, alignment: .leading)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(viewModel.entryTitle(entry))
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textPrimary)
                Text(entry.detail)
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(viewModel.timestampTitle(entry))
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textTertiary)
            }

            Spacer(minLength: Spacing.s2)
        }
        .padding(.vertical, Spacing.s2)
        .accessibilityElement(children: .combine)
    }

    private var emptyState: some View {
        message(title: viewModel.emptyTitle, body: viewModel.emptyBody)
    }

    private var filteredEmptyState: some View {
        message(title: viewModel.filteredEmptyTitle, body: viewModel.filteredEmptyBody)
    }

    private func message(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(title)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)
            Text(body)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(viewModel.appendOnlyNote)
                .font(.sfCaption)
                .foregroundStyle(ColorTokens.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Layout.screenMargin)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Previews

#Preview("K08 Audit log") {
    NavigationStack {
        AuditLogView(audit: InMemoryAIConfigurationStore(auditLog: AuditEntry.samples))
    }
}
