//
//  CollectionDetailView.swift
//  StudyForge
//
//  I16 — `96_Bookmark_Collection_Detail_{M4}` (docs/03 §I, P0). The bookmarks in one collection,
//  each with a source-type icon and saved date, under swipe actions (remove / move) and a
//  select-and-share toolbar mode.
//

import SwiftUI

struct CollectionDetailView: View {

    @State private var viewModel: CollectionDetailViewModel

    /// Select-and-share mode. Off by default so a row tap is inert rather than silently selecting.
    @State private var isSelecting = false
    @State private var selection: Set<String> = []

    /// The bookmark being moved, which drives the move sheet.
    @State private var movingBookmark: Bookmark?

    init(collectionId: String, store: any BookmarkStore) {
        _viewModel = State(initialValue: CollectionDetailViewModel(collectionId: collectionId, store: store))
    }

    private var selectedBookmarks: [Bookmark] {
        viewModel.bookmarks.filter { selection.contains($0.id) }
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
                    .padding(Layout.screenMargin)
            } else if let collection = viewModel.collection {
                content(collection)
            }
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.collection?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !viewModel.bookmarks.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button(isSelecting ? L10n.commonDone.string : viewModel.selectTitle) {
                        isSelecting.toggle()
                        selection.removeAll()
                    }
                }
            }
            if isSelecting && !selection.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: viewModel.shareText(for: selectedBookmarks)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel(viewModel.shareTitle)
                }
            }
        }
        .task { await viewModel.load() }
        .sheet(item: $movingBookmark) { bookmark in moveSheet(bookmark) }
    }

    private func content(_ collection: BookmarkCollection) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                HStack(spacing: Spacing.s3) {
                    Text("\(viewModel.itemCountTitle(collection.bookmarks.count)) · \(viewModel.offlineCountTitle(collection.offlineCount))")
                        .font(.sfFootnote)
                        .foregroundStyle(ColorTokens.textSecondary)

                    if collection.hasOffline {
                        Text(viewModel.offlineBadgeTitle)
                            .font(.sfCaption)
                            .foregroundStyle(ColorTokens.onPrimaryContainer)
                            .padding(.horizontal, Spacing.s2)
                            .padding(.vertical, Spacing.s1)
                            .background(ColorTokens.primaryContainer, in: .capsule)
                    }
                }

                if viewModel.bookmarks.isEmpty {
                    Text(viewModel.noItemsTitle)
                        .font(.sfCallout)
                        .foregroundStyle(ColorTokens.textSecondary)
                } else {
                    ForEach(viewModel.bookmarks) { bookmark in
                        bookmarkRow(bookmark)
                    }
                }
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func bookmarkRow(_ bookmark: Bookmark) -> some View {
        if isSelecting {
            Button { toggleSelection(bookmark) } label: {
                rowContent(bookmark)
            }
            .buttonStyle(.plain)
        } else {
            rowContent(bookmark)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Task { await viewModel.remove(bookmark) }
                    } label: {
                        Label(viewModel.removeTitle, systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        movingBookmark = bookmark
                        Task { await viewModel.loadMoveTargets() }
                    } label: {
                        Label(viewModel.moveTitle, systemImage: "folder")
                    }
                    .tint(ColorTokens.primary)
                }
        }
    }

    private func rowContent(_ bookmark: Bookmark) -> some View {
        HStack(spacing: Spacing.s3) {
            // In selection mode the leading glyph becomes the checkmark; otherwise it is the
            // source-type icon I16 lists. One slot, so the row does not jump when mode changes.
            Image(systemName: isSelecting
                  ? (selection.contains(bookmark.id) ? "checkmark.circle.fill" : "circle")
                  : bookmark.kind.symbolName)
                .font(.sfBody)
                .foregroundStyle(ColorTokens.primary)
                .frame(minWidth: Spacing.s6, alignment: .leading)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(bookmark.title)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .lineLimit(2)

                Text(viewModel.savedOnTitle(bookmark.savedAt))
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textSecondary)
            }

            Spacer(minLength: Spacing.s2)
        }
        .padding(Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
    }

    private func toggleSelection(_ bookmark: Bookmark) {
        if selection.contains(bookmark.id) {
            selection.remove(bookmark.id)
        } else {
            selection.insert(bookmark.id)
        }
    }

    // MARK: Move sheet

    private func moveSheet(_ bookmark: Bookmark) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s3) {
                    if viewModel.moveTargets.isEmpty {
                        Text(viewModel.noMoveTargetsTitle)
                            .font(.sfCallout)
                            .foregroundStyle(ColorTokens.textSecondary)
                    } else {
                        ForEach(viewModel.moveTargets) { target in
                            Button {
                                Task { await viewModel.move(bookmark, to: target.id) }
                                movingBookmark = nil
                            } label: {
                                HStack(spacing: Spacing.s3) {
                                    Image(systemName: "folder")
                                        .font(.sfBody)
                                        .foregroundStyle(ColorTokens.primary)
                                    Text(target.name)
                                        .font(.sfBodyEmph)
                                        .foregroundStyle(ColorTokens.textPrimary)
                                        .lineLimit(2)
                                    Spacer(minLength: 0)
                                }
                                .padding(Spacing.s3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(Layout.screenMargin)
                .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(ColorTokens.surface)
            .navigationTitle(viewModel.moveSheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel.string) { movingBookmark = nil }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("I16 Collection detail") {
    NavigationStack {
        CollectionDetailView(
            collectionId: "preview",
            store: InMemoryBookmarkStore(seededWith: [
                BookmarkCollection(
                    id: "preview",
                    name: "Exam revision",
                    bookmarks: [
                        Bookmark(kind: .material, referenceId: "m1", title: "Lecture 4 — Normalisation", savedOffline: true),
                        Bookmark(kind: .summary, referenceId: "s1", title: "Big-O summary"),
                        Bookmark(kind: .quiz, referenceId: "q1", title: "Databases quiz"),
                    ]
                ),
            ])
        )
    }
}