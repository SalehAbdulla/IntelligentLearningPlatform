//
//  FolderDetailView.swift
//  StudyForge
//
//  I02 + I04 + I06 — `82_Folder_Detail_{M4}` (docs/03 §I, P0). Items and members, with per-member
//  permissions and an invite sheet.
//

import SwiftUI

// Accessibility: item and member rows hide their decorative glyphs, the owner row's lock and the
// per-member permission menu are labelled, and the add-item and add-member sheets are labelled fields
// and a labelled segmented control.

struct FolderDetailView: View {

    enum Tab: String, CaseIterable, Identifiable {
        case items
        case members
        var id: String { rawValue }
    }

    @State private var viewModel: FolderDetailViewModel
    @State private var tab: Tab = .items
    @State private var isAddingItem = false
    @State private var isAddingMember = false

    // Add-item / add-member sheet state.
    @State private var availableMaterials: [Material] = []
    @State private var memberName = ""
    @State private var memberPermission: FolderPermission? = .view

    init(folderId: String, store: any FolderStore, materials: any MaterialStore) {
        _viewModel = State(initialValue: FolderDetailViewModel(
            folderId: folderId, folders: store, materials: materials
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
            } else if let folder = viewModel.folder {
                content(folder)
            }
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.folder?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .sheet(isPresented: $isAddingItem) { addItemSheet }
        .sheet(isPresented: $isAddingMember) { addMemberSheet }
    }

    private func content(_ folder: SharedFolder) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                Text("\(viewModel.memberCountTitle(folder.members.count)) · \(viewModel.itemCountTitle(folder.items.count))")
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)

                Picker(viewModel.itemsTabTitle, selection: $tab) {
                    Text(viewModel.itemsTabTitle).tag(Tab.items)
                    Text(viewModel.membersTabTitle).tag(Tab.members)
                }
                .pickerStyle(.segmented)

                switch tab {
                case .items: itemsSection
                case .members: membersSection
                }
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Items (I02)

    @ViewBuilder
    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            if viewModel.canAddItems {
                SFPrimaryButton(title: viewModel.addItemTitle) {
                    isAddingItem = true
                    Task { availableMaterials = await viewModel.availableMaterials() }
                }
            }

            if viewModel.items.isEmpty {
                Text(viewModel.noItemsTitle)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
            } else {
                ForEach(viewModel.items) { item in
                    itemRow(item)
                }
            }
        }
    }

    private func itemRow(_ item: FolderItem) -> some View {
        HStack(spacing: Spacing.s3) {
            Image(systemName: item.kind.symbolName)
                .font(.sfBody)
                .foregroundStyle(ColorTokens.primary)
                .frame(minWidth: Spacing.s6, alignment: .leading)
                .accessibilityHidden(true)

            Text(item.title)
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.textPrimary)
                .lineLimit(2)

            Spacer(minLength: Spacing.s2)
        }
        .padding(Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task { await viewModel.removeItem(item) }
            } label: {
                Label(L10n.commonDelete.string, systemImage: "trash")
            }
        }
    }

    // MARK: Members (I04 + I06)

    @ViewBuilder
    private var membersSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            SFPrimaryButton(title: viewModel.addMemberTitle) { isAddingMember = true }

            ForEach(viewModel.members) { member in
                memberRow(member)
            }
        }
    }

    private func memberRow(_ member: FolderMember) -> some View {
        HStack(spacing: Spacing.s3) {
            Image(systemName: "person.circle.fill")
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.primary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(member.name)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textPrimary)

                Text(member.isOwner
                     ? viewModel.ownerRoleTitle
                     : viewModel.permissionTitle(member.permission))
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textSecondary)
            }

            Spacer(minLength: Spacing.s2)

            if member.isOwner {
                // The owner's access is locked, and says so — a dimmed control with no explanation is
                // the thing the design's "owner row is locked with explanation" guards against.
                Image(systemName: "lock.fill")
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textTertiary)
                    .accessibilityLabel(viewModel.ownerRoleTitle)
            } else {
                permissionMenu(member)
            }
        }
        .padding(Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
    }

    private func permissionMenu(_ member: FolderMember) -> some View {
        Menu {
            ForEach(FolderPermission.allCases) { permission in
                Button(viewModel.permissionTitle(permission)) {
                    Task { await viewModel.setPermission(permission, for: member) }
                }
            }
            Divider()
            Button(L10n.commonDelete.string, role: .destructive) {
                Task { await viewModel.removeMember(member) }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.sfBody)
                .foregroundStyle(ColorTokens.primary)
                .frame(minWidth: Layout.minTouchTarget, minHeight: Layout.minTouchTarget)
        }
        .accessibilityLabel("\(member.name), \(viewModel.permissionTitle(member.permission))")
    }

    // MARK: Add item sheet

    private var addItemSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s3) {
                    if availableMaterials.isEmpty {
                        Text(viewModel.noItemsTitle)
                            .font(.sfCallout)
                            .foregroundStyle(ColorTokens.textSecondary)
                    } else {
                        ForEach(availableMaterials) { material in
                            Button {
                                Task {
                                    await viewModel.addMaterial(material)
                                    isAddingItem = false
                                }
                            } label: {
                                HStack(spacing: Spacing.s3) {
                                    Image(systemName: material.source.symbolName)
                                        .font(.sfBody)
                                        .foregroundStyle(ColorTokens.primary)
                                    Text(material.title)
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
            .navigationTitle(viewModel.addItemsSheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel.string) { isAddingItem = false }
                }
            }
        }
    }

    // MARK: Add member sheet

    private var addMemberSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s6) {
                    SFTextField(
                        label: viewModel.memberNameLabel,
                        text: $memberName,
                        placeholder: viewModel.memberNamePlaceholder,
                        error: viewModel.memberError,
                        submitLabel: .done,
                        autocorrectionDisabled: false,
                        onSubmit: {}
                    )

                    SFSegmentedField(
                        label: viewModel.permissionLabel,
                        selection: $memberPermission,
                        options: FolderPermission.allCases,
                        title: { viewModel.permissionTitle($0) }
                    )

                    SFPrimaryButton(
                        title: viewModel.addMemberTitle,
                        isEnabled: !memberName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                        action: { Task { await addMember() } }
                    )
                }
                .padding(Layout.screenMargin)
                .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(ColorTokens.surface)
            .navigationTitle(viewModel.addMemberTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel.string) {
                        viewModel.clearMemberError()
                        isAddingMember = false
                    }
                }
            }
        }
    }

    private func addMember() async {
        await viewModel.addMember(name: memberName, permission: memberPermission ?? .view)
        guard viewModel.memberError == nil else { return }
        memberName = ""
        isAddingMember = false
    }
}

// MARK: - Previews

#Preview("I02 Folder detail") {
    NavigationStack {
        FolderDetailView(
            folderId: "preview",
            store: InMemoryFolderStore(seededWith: [
                SharedFolder(
                    id: "preview",
                    name: "Database revision",
                    members: [
                        FolderMember(name: "Sara Ali", permission: .edit, isOwner: true),
                        FolderMember(name: "Omar", permission: .comment),
                    ],
                    items: [
                        FolderItem(kind: .material, referenceId: "m1", title: "Lecture 4 — Normalisation")
                    ]
                )
            ]),
            materials: InMemoryMaterialStore(seededWith: Material.samples)
        )
    }
}