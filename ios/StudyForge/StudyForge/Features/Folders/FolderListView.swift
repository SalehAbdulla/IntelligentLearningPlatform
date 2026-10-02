//
//  FolderListView.swift
//  StudyForge
//
//  I01 + I03 — `81_Folder_Shared_List_{M4}` (docs/03 §I, P0). The student's shared folders, with a
//  create sheet.
//

import SwiftUI

struct FolderListView: View {

    @State private var viewModel: FolderListViewModel
    @State private var isCreating = false

    private let store: any FolderStore
    private let materials: any MaterialStore
    private let ownerName: String

    init(store: any FolderStore, materials: any MaterialStore, ownerName: String) {
        self.store = store
        self.materials = materials
        self.ownerName = ownerName
        _viewModel = State(initialValue: FolderListViewModel(store: store))
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
                folderList
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
                .accessibilityLabel(viewModel.newFolderTitle)
            }
        }
        .sheet(isPresented: $isCreating) { createSheet }
        .task { await viewModel.load() }
    }

    private var folderList: some View {
        List {
            ForEach(viewModel.folders) { folder in
                NavigationLink {
                    FolderDetailView(folderId: folder.id, store: store, materials: materials)
                } label: {
                    row(folder)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func row(_ folder: SharedFolder) -> some View {
        HStack(spacing: Spacing.s3) {
            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(folder.name)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .lineLimit(2)

                Text("\(viewModel.memberCount(folder)) · \(viewModel.itemCount(folder))")
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
            }

            Spacer(minLength: Spacing.s2)

            Text(viewModel.ownerRoleTitle)
                .font(.sfCaption)
                .foregroundStyle(ColorTokens.onPrimaryContainer)
                .padding(.horizontal, Spacing.s2)
                .padding(.vertical, Spacing.s1)
                .background(ColorTokens.primaryContainer, in: .capsule)
        }
        .padding(.vertical, Spacing.s2)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task { await viewModel.delete(folder) }
            } label: {
                Label(L10n.commonDelete.string, systemImage: "trash")
            }
        }
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

    // MARK: Create

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
            .navigationTitle(viewModel.newFolderTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel.string) { isCreating = false }
                }
            }
        }
    }

    private func create() async {
        await viewModel.create(ownerName: ownerName)
        if viewModel.error == nil { isCreating = false }
    }
}

// MARK: - Previews

#Preview("I01 Shared folders — empty") {
    NavigationStack {
        FolderListView(
            store: InMemoryFolderStore(),
            materials: InMemoryMaterialStore(seededWith: Material.samples),
            ownerName: "Sara Ali"
        )
    }
}