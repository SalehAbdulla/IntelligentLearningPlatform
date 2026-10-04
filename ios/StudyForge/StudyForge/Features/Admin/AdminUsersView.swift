//
//  AdminUsersView.swift
//  StudyForge
//
//  K02 + K03 — `110_Admin_Users_List_{M4}` and `111_Admin_User_Detail_{M4}` (docs/03 §K, P0/P1). The
//  roster, and the two decisions an admin makes about one account.
//
//  WHY THE DETAIL IS A SHEET THAT RE-READS
//  --------------------------------------
//  A role change rewrites the account, and a sheet holding the copy it opened with would keep showing
//  the old role until it was closed. It re-reads by id instead, exactly as the folder and collection
//  details do, so the screen shows what was stored.
//

import SwiftUI

struct AdminUsersView: View {

    @State private var viewModel: AdminUsersViewModel

    /// The account whose detail sheet is open, by id so the sheet always reads the live row.
    @State private var selectedUserId: String?

    init(store: any AdminDirectoryStore, audit: any AIConfigurationStore, actorName: String) {
        _viewModel = State(initialValue: AdminUsersViewModel(
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
                list
            }
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.query, prompt: Text(viewModel.searchPlaceholder))
        .toolbar {
            ToolbarItem(placement: .primaryAction) { roleFilterMenu }
        }
        .task { await viewModel.load() }
        .sheet(isPresented: isShowingDetail) {
            if let userId = selectedUserId {
                AdminUserDetailSheet(viewModel: viewModel, userId: userId) { selectedUserId = nil }
            }
        }
    }

    private var isShowingDetail: Binding<Bool> {
        Binding(
            get: { selectedUserId != nil },
            set: { if !$0 { selectedUserId = nil } }
        )
    }

    private var roleFilterMenu: some View {
        Menu {
            Button(viewModel.allRolesTitle) { viewModel.roleFilter = nil }
            ForEach(AppRole.allCases, id: \.self) { role in
                Button(role.displayName) { viewModel.roleFilter = role }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel(viewModel.allRolesTitle)
    }

    // MARK: List

    @ViewBuilder
    private var list: some View {
        if viewModel.isFilteredEmpty {
            emptyState
        } else if viewModel.users.isEmpty {
            emptyState
        } else {
            List {
                ForEach(viewModel.visibleUsers) { user in
                    Button { selectedUserId = user.id } label: { row(user) }
                        .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private func row(_ user: PlatformUser) -> some View {
        HStack(alignment: .top, spacing: Spacing.s3) {
            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(user.displayName)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .lineLimit(1)

                Text(user.email)
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .lineLimit(1)

                Text("\(viewModel.masteryTitle(user)) · \(viewModel.lastActiveTitle(user))")
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textTertiary)
            }

            Spacer(minLength: Spacing.s2)

            VStack(alignment: .trailing, spacing: Spacing.s1) {
                pill(user.role.displayName, tinted: false)
                pill(viewModel.statusTitle(user), tinted: user.isSuspended)
            }
        }
        .padding(.vertical, Spacing.s2)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }

    private func pill(_ text: String, tinted: Bool) -> some View {
        Text(text)
            .font(.sfCaption)
            .foregroundStyle(tinted ? ColorTokens.error : ColorTokens.onPrimaryContainer)
            .padding(.horizontal, Spacing.s2)
            .padding(.vertical, Spacing.s1)
            .background(
                tinted ? ColorTokens.error.opacity(0.15) : ColorTokens.primaryContainer,
                in: .capsule
            )
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

// MARK: - K03 detail

/// One account's detail, with the two decisions an admin makes about it.
///
/// Takes the LIST's view model rather than its own: the two are one screen in two presentations, and a
/// second view model would mean a second loaded copy of the roster that could disagree with the list
/// behind it.
struct AdminUserDetailSheet: View {

    let viewModel: AdminUsersViewModel
    let userId: String
    let onClose: () -> Void

    @State private var pendingRole: AppRole?
    @State private var isConfirmingRole = false
    @State private var isConfirmingSuspend = false

    /// Re-read by id, so a saved change is reflected without reopening the sheet.
    private var user: PlatformUser? { viewModel.user(id: userId) }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let user {
                    VStack(alignment: .leading, spacing: Spacing.s6) {
                        header(user)
                        roleSection(user)
                        accessSection(user)
                    }
                    .padding(Layout.screenMargin)
                    .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
                    .frame(maxWidth: .infinity)
                }
            }
            .background(ColorTokens.surface)
            .navigationTitle(viewModel.accountTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonClose.string) { onClose() }
                }
            }
            // The confirmation is required, not decorative: both actions change what this person can
            // reach, and neither is undoable by the person affected.
            .alert(viewModel.roleConfirmTitle, isPresented: $isConfirmingRole) {
                Button(L10n.commonCancel.string, role: .cancel) { pendingRole = nil }
                Button(viewModel.roleLabel) {
                    guard let pendingRole, let user else { return }
                    self.pendingRole = nil
                    Task { await viewModel.setRole(pendingRole, for: user) }
                }
            } message: {
                Text(viewModel.roleConfirmBody)
            }
            .alert(viewModel.suspendConfirmTitle, isPresented: $isConfirmingSuspend) {
                Button(L10n.commonCancel.string, role: .cancel) {}
                // The button names the action rather than saying "OK", so the confirmation cannot be
                // tapped without reading what it does.
                Button(user?.isSuspended == true ? viewModel.reactivateTitle : viewModel.suspendTitle) {
                    guard let user else { return }
                    Task { await viewModel.toggleSuspension(user) }
                }
            } message: {
                Text(viewModel.suspendConfirmBody)
            }
        }
    }

    private func header(_ user: PlatformUser) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(user.displayName)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)
            Text(user.email)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
            Text(viewModel.lastActiveTitle(user))
                .font(.sfCaption)
                .foregroundStyle(ColorTokens.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func roleSection(_ user: PlatformUser) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(viewModel.roleLabel)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)

            ForEach(AppRole.allCases, id: \.self) { role in
                Button {
                    pendingRole = role
                    isConfirmingRole = true
                } label: {
                    HStack(spacing: Spacing.s3) {
                        Image(systemName: role == user.role ? "checkmark.circle.fill" : "circle")
                            .font(.sfTitleM)
                            .foregroundStyle(ColorTokens.primary)
                            .accessibilityHidden(true)
                        Text(role.displayName)
                            .font(.sfBodyEmph)
                            .foregroundStyle(ColorTokens.textPrimary)
                        Spacer(minLength: 0)
                    }
                    .padding(Spacing.s3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
                }
                .buttonStyle(.plain)
                .disabled(role == user.role)
            }
        }
    }

    private func accessSection(_ user: PlatformUser) -> some View {
        Button(role: user.isSuspended ? nil : .destructive) {
            isConfirmingSuspend = true
        } label: {
            Text(user.isSuspended ? viewModel.reactivateTitle : viewModel.suspendTitle)
                .font(.sfBodyEmph)
                .foregroundStyle(user.isSuspended ? ColorTokens.primary : ColorTokens.error)
                .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("K02 Accounts") {
    NavigationStack {
        AdminUsersView(
            store: InMemoryAdminDirectoryStore(seededWith: PlatformUser.samples),
            audit: InMemoryAIConfigurationStore(),
            actorName: "Shahad Ashoor"
        )
    }
}