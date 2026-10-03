//
//  GlobalSearchView.swift
//  StudyForge
//
//  M05 — `132_Global_Search_{M1}` (docs/03 §M, P0). One field across everything the student has
//  saved, with scope chips, result-type grouping and recent searches.
//

import SwiftUI

/// One kind's block of hits.
private struct SearchResultGroup: Identifiable {
    let id: String
    let kind: SearchResultKind
    let items: [SearchResult]
}

struct GlobalSearchView: View {

    @State private var viewModel: GlobalSearchViewModel

    init(
        materials: any MaterialStore,
        summaries: any SummaryStore,
        decks: any DeckStore,
        quizzes: any QuizStore,
        folders: any FolderStore,
        bookmarks: any BookmarkStore,
        recents: any RecentSearchStore
    ) {
        _viewModel = State(initialValue: GlobalSearchViewModel(
            materials: materials,
            summaries: summaries,
            decks: decks,
            quizzes: quizzes,
            folders: folders,
            bookmarks: bookmarks,
            recents: recents
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                if let error = viewModel.error {
                    SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
                }

                if viewModel.isSearching {
                    scopeChips
                }

                content
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        // Committed on submit rather than on every keystroke, so the recent list holds searches
        // rather than every prefix the student typed on the way to one.
        .searchable(text: $viewModel.query, prompt: Text(viewModel.prompt))
        .onSubmit(of: .search) { viewModel.commitSearch() }
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.isSearching {
            recentSection
        } else if viewModel.isEmptyResult {
            emptyState
        } else {
            resultsSection
        }
    }

    // MARK: Scope chips

    private var scopeChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s2) {
                scopeChip(
                    title: viewModel.allScopeTitle,
                    count: viewModel.results.count,
                    isSelected: viewModel.scope == nil
                ) {
                    viewModel.scope = nil
                }

                ForEach(SearchResultKind.allCases) { kind in
                    let count = viewModel.matchCount(for: kind)
                    // A kind with no hits is not offered: a chip that empties the screen is a trap.
                    if count > 0 {
                        scopeChip(title: kind.title, count: count, isSelected: viewModel.scope == kind) {
                            viewModel.scope = kind
                        }
                    }
                }
            }
            .padding(.vertical, Spacing.s1)
        }
    }

    private func scopeChip(
        title: String,
        count: Int,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text("\(title) · \(count)")
                .font(.sfCaption)
                .foregroundStyle(isSelected ? ColorTokens.onPrimaryContainer : ColorTokens.textSecondary)
                .padding(.horizontal, Spacing.s3)
                .padding(.vertical, Spacing.s2)
                .background(
                    isSelected ? ColorTokens.primaryContainer : ColorTokens.surfaceVariant,
                    in: .capsule
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: Recent searches

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            if viewModel.hasRecent {
                HStack {
                    Text(viewModel.recentHeading)
                        .font(.sfSubhead)
                        .foregroundStyle(ColorTokens.textSecondary)
                    Spacer(minLength: Spacing.s2)
                    Button(viewModel.clearRecentTitle) { viewModel.clearRecent() }
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.primary)
                }

                VStack(alignment: .leading, spacing: Spacing.s2) {
                    ForEach(viewModel.recent, id: \.self) { remembered in
                        Button { viewModel.use(remembered) } label: {
                            HStack(spacing: Spacing.s3) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.sfCaption)
                                    .foregroundStyle(ColorTokens.textTertiary)
                                    .accessibilityHidden(true)
                                Text(remembered)
                                    .font(.sfCallout)
                                    .foregroundStyle(ColorTokens.textPrimary)
                                Spacer(minLength: 0)
                            }
                            .frame(minHeight: Layout.minTouchTarget)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: Results

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            Text(viewModel.resultCountTitle(viewModel.results.count))
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textSecondary)

            ForEach(resultGroups) { group in
                VStack(alignment: .leading, spacing: Spacing.s3) {
                    Text(group.kind.title)
                        .font(.sfSubhead)
                        .foregroundStyle(ColorTokens.textSecondary)

                    ForEach(group.items) { result in
                        resultRow(result)
                    }
                }
            }
        }
    }

    /// Hits grouped by kind, in the vocabulary's own order, so a result list is a statement rather
    /// than a jumble. With a scope chosen there is exactly one group.
    private var resultGroups: [SearchResultGroup] {
        SearchResultKind.allCases.compactMap { kind in
            let items = viewModel.results.filter { $0.kind == kind }
            guard !items.isEmpty else { return nil }
            return SearchResultGroup(id: kind.rawValue, kind: kind, items: items)
        }
    }

    private func resultRow(_ result: SearchResult) -> some View {
        HStack(alignment: .top, spacing: Spacing.s3) {
            Image(systemName: result.kind.symbolName)
                .font(.sfBody)
                .foregroundStyle(ColorTokens.primary)
                .frame(minWidth: Spacing.s6, alignment: .leading)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(result.title)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .lineLimit(2)

                Text(result.subtitle)
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: Spacing.s2)
        }
        .padding(Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
        .accessibilityElement(children: .combine)
    }

    // MARK: Empty

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
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Previews

#Preview("M05 Global search") {
    NavigationStack {
        GlobalSearchView(
            materials: InMemoryMaterialStore(seededWith: Material.samples),
            summaries: InMemorySummaryStore(),
            decks: InMemoryDeckStore(),
            quizzes: InMemoryQuizStore(),
            folders: InMemoryFolderStore(),
            bookmarks: InMemoryBookmarkStore(),
            recents: InMemoryRecentSearchStore(recent: ["normalisation", "hash tables"])
        )
    }
}