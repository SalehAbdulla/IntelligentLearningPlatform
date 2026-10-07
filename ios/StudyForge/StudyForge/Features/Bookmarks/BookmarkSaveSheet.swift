//
//  BookmarkSaveSheet.swift
//  StudyForge
//
//  I17 — `97_Bookmark_Save_Sheet_{M4}` (docs/03 §I, P0). Raised from any screen to file a
//  reference into a collection: a picker with a checkmark, an inline "create new", an
//  "also save offline" toggle, and Save.
//

import SwiftUI

// Accessibility: the picker rows hide the checkmark glyph and announce the chosen collection, and the
// "already saved" bookmark is labelled, so the selection is legible without sight of the tick.

struct BookmarkSaveSheet: View {

    @State private var viewModel: BookmarkSaveViewModel
    @Environment(\.dismiss) private var dismiss

    init(
        store: any BookmarkStore,
        kind: BookmarkKind,
        referenceId: String,
        itemTitle: String,
        saveOffline: Bool = false
    ) {
        _viewModel = State(initialValue: BookmarkSaveViewModel(
            store: store,
            kind: kind,
            referenceId: referenceId,
            itemTitle: itemTitle,
            saveOffline: saveOffline
        ))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.error {
                    SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
                        .padding(Layout.screenMargin)
                } else {
                    form
                }
            }
            .background(ColorTokens.surface)
            .navigationTitle(viewModel.sheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel.string) { dismiss() }
                }
            }
            .task { await viewModel.load() }
        }
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                Text(viewModel.itemTitle)
                    .font(.sfTitleM)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                picker

                VStack(alignment: .leading, spacing: Spacing.s3) {
                    Text(viewModel.createNewTitle)
                        .font(.sfSubhead)
                        .foregroundStyle(ColorTokens.textSecondary)

                    SFTextField(
                        label: viewModel.nameLabel,
                        text: $viewModel.createName,
                        placeholder: viewModel.namePlaceholder,
                        submitLabel: .done,
                        autocorrectionDisabled: false,
                        onSubmit: {}
                    )
                }

                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Toggle(viewModel.offlineTitle, isOn: $viewModel.saveOffline)
                        .tint(ColorTokens.primary)
                    Text(viewModel.offlineHint)
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                SFPrimaryButton(
                    title: viewModel.saveTitle,
                    isLoading: viewModel.isSaving,
                    isEnabled: viewModel.canSave,
                    action: { Task { await save() } },
                    loadingTitle: viewModel.savingTitle
                )
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var picker: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(viewModel.saveToTitle)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)

            if viewModel.collections.isEmpty {
                Text(viewModel.noCollectionsTitle)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
            } else {
                ForEach(viewModel.collections) { collection in
                    Button { viewModel.selectedCollectionId = collection.id } label: {
                        collectionRow(collection)
                    }
                    .buttonStyle(.plain)
                    // The row is a single-choice control, so its chosen state must be announced; the
                    // checkmark that shows it on screen is decorative and hidden.
                    .accessibilityAddTraits(
                        viewModel.selectedCollectionId == collection.id && !viewModel.isCreatingNew
                            ? .isSelected : []
                    )
                }
            }
        }
    }

    private func collectionRow(_ collection: BookmarkCollection) -> some View {
        // The checkmark moves to the picked row, and typing a new name takes it away entirely —
        // which is what makes "create new" and "pick one" mutually exclusive without a separate
        // control to explain it.
        let isSelected = viewModel.selectedCollectionId == collection.id && !viewModel.isCreatingNew

        return HStack(spacing: Spacing.s3) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.primary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(collection.name)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .lineLimit(2)

                Text(viewModel.itemCount(collection))
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textSecondary)
            }

            Spacer(minLength: Spacing.s2)

            // A filled bookmark means "this is already in here", so a Save is a no-op rather than a
            // surprise duplicate.
            if viewModel.alreadySaved(in: collection) {
                Image(systemName: "bookmark.fill")
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.primary)
                    .accessibilityLabel(viewModel.existsTitle)
            }
        }
        .padding(Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
    }

    private func save() async {
        await viewModel.save()
        if viewModel.didSave { dismiss() }
    }
}

// MARK: - Previews

#Preview("I17 Save sheet") {
    BookmarkSaveSheet(
        store: InMemoryBookmarkStore(seededWith: [
            BookmarkCollection(name: "Exam revision"),
            BookmarkCollection(name: "Reading list"),
        ]),
        kind: .material,
        referenceId: "m1",
        itemTitle: "Lecture 4 — Normalisation"
    )
}