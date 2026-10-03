//
//  CollectionListView.swift
//  StudyForge
//
//  I15 + I18 — `95_Bookmarks_Collections_{M4}` and `98_Bookmarks_EmptyState_{M4}`
//  (docs/03 §I, P0/P1). The student's bookmark collections, each card carrying an item count and
//  an offline badge, over a create sheet and a designed empty state.
//

import SwiftUI

struct CollectionListView: View {

    @State private var viewModel: CollectionListViewModel
    @State private var isCreating = false

    private let store: any BookmarkStore

    // Held only so the empty state's "Browse your library" CTA can push the library. Defaulted, so
    // a preview needs nothing but the bookmark store — the same reason the library itself takes
    // stores rather than a container.
    private let materials: any MaterialStore
    private let summaries: any SummaryStore
    private let decks: any DeckStore
    private let router: AIRouter

    init(
        store: any BookmarkStore,
        materials: any MaterialStore = InMemoryMaterialStore(),
        summaries: any SummaryStore = InMemorySummaryStore(),
        decks: any DeckStore = InMemoryDeckStore(),
        router: AIRouter = AIRouter.standard(governor: AICostGovernor())
    ) {
        self.store = store
        self.materials = materials
        self.summaries = summaries
        self.decks = decks
        self.router = router
        _viewModel = State(initialValue: CollectionListViewModel(store: store))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
                    .padding(Layout.screenMargin)
            } else if viewModel.isEmpty {
                emptyState
            } else {
                collectionList
            }
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { isCreating = true } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(viewModel.newCollectionTitle)
            }
        }
        .sheet(isPresented: $isCreating) { createSheet }
        .task { await viewModel.load() }
    }

    private var collectionList: some View {
        List {
            ForEach(viewModel.collections) { collection in
                NavigationLink {
                    CollectionDetailView(collectionId: collection.id, store: store)
                } label: {
                    row(collection)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func row(_ collection: BookmarkCollection) -> some View {
        HStack(spacing: Spacing.s3) {
            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(collection.name)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .lineLimit(2)

                Text("\(viewModel.itemCount(collection)) · \(viewModel.offlineCount(collection))")
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
            }

            Spacer(minLength: Spacing.s2)

            // The badge is earned, not decorative: it appears only when something here is saved
            // for offline use, so it never lies about the offline-first story I18 tells.
            if collection.hasOffline {
                Text(viewModel.offlineBadgeTitle)
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.onPrimaryContainer)
                    .padding(.horizontal, Spacing.s2)
                    .padding(.vertical, Spacing.s1)
                    .background(ColorTokens.primaryContainer, in: .capsule)
            }
        }
        .padding(.vertical, Spacing.s2)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task { await viewModel.delete(collection) }
            } label: {
                Label(L10n.commonDelete.string, systemImage: "trash")
            }
        }
    }

    // MARK: Empty state (I18)

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(viewModel.emptyTitle)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)
            Text(viewModel.emptyBody)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(viewModel.offlineNote)
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textTertiary)
                .fixedSize(horizontal: false, vertical: true)

            NavigationLink {
                MaterialLibraryView(
                    store: materials,
                    summaryStore: summaries,
                    deckStore: decks,
                    router: router,
                    bookmarkStore: store
                )
            } label: {
                Text(viewModel.browseLibraryTitle)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.primary)
                    .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Layout.screenMargin)
        .accessibilityElement(children: .contain)
    }

    // MARK: Create (I15)

    private var createSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s6) {
                    SFTextField(
                        label: viewModel.nameLabel,
                        text: $viewModel.name,
                        placeholder: viewModel.namePlaceholder,
                        submitLabel: .done,
                        autocorrectionDisabled: false,
                        onSubmit: { Task { await create() } }
                    )

                    SFPrimaryButton(
                        title: viewModel.createTitle,
                        isLoading: viewModel.isCreating,
                        isEnabled: !viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                        action: { Task { await create() } },
                        loadingTitle: viewModel.creatingTitle
                    )
                }
                .padding(Layout.screenMargin)
                .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(ColorTokens.surface)
            .navigationTitle(viewModel.newCollectionTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel.string) { isCreating = false }
                }
            }
        }
    }

    private func create() async {
        await viewModel.create()
        if viewModel.error == nil { isCreating = false }
    }
}

// MARK: - Previews

#Preview("I15 Collections — with collections") {
    NavigationStack {
        CollectionListView(store: InMemoryBookmarkStore(seededWith: [
            BookmarkCollection(
                name: "Exam revision",
                bookmarks: [
                    Bookmark(kind: .material, referenceId: "m1", title: "Lecture 4 — Normalisation", savedOffline: true),
                    Bookmark(kind: .deck, referenceId: "d1", title: "Normalisation cards"),
                ]
            ),
        ]))
    }
}

#Preview("I18 Collections — empty") {
    NavigationStack {
        CollectionListView(store: InMemoryBookmarkStore())
    }
}