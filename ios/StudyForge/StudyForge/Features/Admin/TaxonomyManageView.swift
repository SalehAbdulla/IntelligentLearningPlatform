//
//  TaxonomyManageView.swift
//  StudyForge
//
//  K06: `114_Admin_Taxonomy_Manage_{M4}` (docs/03 section K, P1). The platform's subjects and tags,
//  curated: add, rename, reorder, delete and merge.
//
//  WHY REORDER NEEDS EDIT MODE
//  ---------------------------
//  A taxonomy is a curated ORDER, but the rows are also tap targets, and a list where a drag both
//  reorders and triggers an action is ambiguous. Edit mode separates the two, which is the standard
//  iOS answer rather than inventing a custom gesture.
//

import SwiftUI

struct TaxonomyManageView: View {

    @State private var viewModel: TaxonomyManageViewModel

    /// The term being renamed, or `nil`.
    @State private var renameTerm: TaxonomyTerm?
    @State private var renameText = ""

    /// The term whose merge sheet is open, by id so the sheet reads the live row.
    @State private var mergingTermId: String?

    init(store: any TaxonomyStore, audit: any AIConfigurationStore, actorName: String) {
        _viewModel = State(initialValue: TaxonomyManageViewModel(
            store: store,
            audit: audit,
            actorName: actorName
        ))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
                    .padding(Layout.screenMargin)
            } else {
                content
            }
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) { EditButton() }
        }
        .task { await viewModel.load() }
        .alert(renameAlertTitle, isPresented: isShowingRename) {
            TextField("", text: $renameText)
            Button(L10n.commonCancel.string, role: .cancel) { renameTerm = nil }
            Button(viewModel.renameTitle) {
                guard let term = renameTerm else { return }
                Task { await viewModel.rename(term, to: renameText) }
                renameTerm = nil
            }
        }
        .sheet(isPresented: isShowingMerge) {
            if let source = mergingTerm {
                TaxonomyMergeSheet(viewModel: viewModel, source: source) { mergingTermId = nil }
            }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.s4) {
                SFSegmentedField(
                    label: viewModel.title,
                    selection: kindBinding,
                    options: TaxonomyKind.allCases,
                    title: { viewModel.kindTitle($0) }
                )
                addRow
            }
            .padding(Layout.screenMargin)

            if viewModel.isKindEmpty {
                emptyState
            } else {
                list
            }
        }
    }

    private var kindBinding: Binding<TaxonomyKind?> {
        Binding(
            get: { viewModel.kind },
            set: { viewModel.kind = $0 ?? viewModel.kind }
        )
    }

    private var addRow: some View {
        HStack(alignment: .top, spacing: Spacing.s3) {
            SFTextField(
                label: viewModel.kindTitle(viewModel.kind),
                text: $viewModel.newName,
                placeholder: viewModel.addPlaceholder,
                error: viewModel.formError
            )

            Button {
                Task { await viewModel.add() }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.sfTitleM)
                    .foregroundStyle(ColorTokens.primary)
                    .frame(minWidth: Layout.minTouchTarget, minHeight: Layout.minTouchTarget)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.newName.trimmingCharacters(in: .whitespaces).isEmpty)
            .accessibilityLabel(viewModel.addButton)
        }
    }

    private var list: some View {
        List {
            ForEach(viewModel.visibleTerms) { term in
                row(term)
            }
            .onMove { offsets, destination in
                var ordered = viewModel.visibleTerms
                ordered.move(fromOffsets: offsets, toOffset: destination)
                Task { await viewModel.persistOrder(ordered) }
            }
            .onDelete { offsets in
                let terms = offsets.map { viewModel.visibleTerms[$0] }
                Task { for term in terms { await viewModel.delete(term) } }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func row(_ term: TaxonomyTerm) -> some View {
        HStack(spacing: Spacing.s3) {
            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(term.name)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textPrimary)
                Text(viewModel.usageTitle(term))
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textTertiary)
            }

            Spacer(minLength: Spacing.s2)
        }
        .padding(.vertical, Spacing.s2)
        .contentShape(.rect)
        .contextMenu {
            Button(viewModel.renameTitle) {
                renameText = term.name
                renameTerm = term
            }
            if !viewModel.mergeTargets(for: term).isEmpty {
                Button(viewModel.mergeTitle) { mergingTermId = term.id }
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Derived state

    private var mergingTerm: TaxonomyTerm? {
        guard let mergingTermId else { return nil }
        return viewModel.terms.first { $0.id == mergingTermId }
    }

    private var isShowingRename: Binding<Bool> {
        Binding(
            get: { renameTerm != nil },
            set: { if !$0 { renameTerm = nil } }
        )
    }

    private var isShowingMerge: Binding<Bool> {
        Binding(
            get: { mergingTerm != nil },
            set: { if !$0 { mergingTermId = nil } }
        )
    }

    private var renameAlertTitle: String {
        renameTerm.map { viewModel.renameTitle(for: $0) } ?? viewModel.renameTitle
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(viewModel.emptyTitle)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)
            Text(viewModel.emptyBody)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Layout.screenMargin)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - K06 merge

/// Picks the term to fold the source into. Merging is a two-step decision, so it gets its own sheet
/// with the target list and the consequence spelled out, rather than a one-tap action on the row.
struct TaxonomyMergeSheet: View {

    let viewModel: TaxonomyManageViewModel
    let source: TaxonomyTerm
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(viewModel.mergeTargets(for: source)) { target in
                        targetRow(target)
                    }
                } footer: {
                    Text(viewModel.mergeBody(source: source))
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(ColorTokens.surface)
            .navigationTitle(viewModel.mergeSheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel.string) { onClose() }
                }
            }
        }
    }

    private func targetRow(_ target: TaxonomyTerm) -> some View {
        Button {
            Task {
                await viewModel.merge(source, into: target)
                onClose()
            }
        } label: {
            HStack(spacing: Spacing.s3) {
                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Text(target.name)
                        .font(.sfBodyEmph)
                        .foregroundStyle(ColorTokens.textPrimary)
                    Text(viewModel.usageTitle(target))
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.textTertiary)
                }
                Spacer(minLength: Spacing.s2)
                Image(systemName: "arrow.right")
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textTertiary)
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Previews

#Preview("K06 Taxonomy") {
    NavigationStack {
        TaxonomyManageView(
            store: InMemoryTaxonomyStore(seededWith: TaxonomyTerm.samples),
            audit: InMemoryAIConfigurationStore(auditLog: AuditEntry.samples),
            actorName: "Shahad Ashoor"
        )
    }
}

