//
//  AdminUsersViewModel.swift
//  StudyForge
//
//  Presentation logic for K02 (`110_Admin_Users_List_{M4}`) and K03
//  (`111_Admin_User_Detail_{M4}`) — the platform's accounts, and the two decisions an admin makes
//  about one.
//
//  WHY A ROLE CHANGE IS AUDITED
//  ----------------------------
//  K08's premise is that admin actions are provably logged, and changing somebody's role is the single
//  most consequential thing this screen does — it hands over the tutor and admin surfaces. The audit
//  line is written in the same call that saves the account, so the two cannot come apart.
//

import Foundation

@MainActor
@Observable
final class AdminUsersViewModel {

    // MARK: Bound state

    var query = ""
    var roleFilter: AppRole?

    // MARK: Derived state

    private(set) var state: LoadState<[PlatformUser]> = .idle
    private(set) var error: AppError?

    private let store: any AdminDirectoryStore
    private let audit: any AIConfigurationStore

    /// The signed-in admin's name, so the trail is attributable.
    let actorName: String

    init(store: any AdminDirectoryStore, audit: any AIConfigurationStore, actorName: String) {
        self.store = store
        self.audit = audit
        self.actorName = actorName
    }

    // MARK: Derived

    var users: [PlatformUser] { state.value ?? [] }
    var isLoading: Bool { state.isLoading }

    /// The accounts the current search and filter leave visible.
    var visibleUsers: [PlatformUser] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return users.filter { user in
            let matchesRole = roleFilter == nil || user.role == roleFilter
            let matchesQuery = needle.isEmpty
                || user.displayName.lowercased().contains(needle)
                || user.email.lowercased().contains(needle)
            return matchesRole && matchesQuery
        }
    }

    /// True when there are accounts but the search hid them all — a different state from an empty
    /// platform, and the one that needs different copy.
    var isFilteredEmpty: Bool { !users.isEmpty && visibleUsers.isEmpty }

    /// One account by id, re-read so the detail sheet reflects a change the moment it is saved.
    func user(id: String) -> PlatformUser? { users.first { $0.id == id } }

    // MARK: Copy

    var title: String { L10n.adminUsersTitle.string }
    var searchPlaceholder: String { L10n.adminUsersSearchPlaceholder.string }
    var emptyTitle: String { L10n.adminUsersEmptyTitle.string }
    var emptyBody: String { L10n.adminUsersEmptyBody.string }
    var allRolesTitle: String { L10n.adminFilterAll.string }
    var accountTitle: String { L10n.adminAccountTitle.string }
    var roleLabel: String { L10n.adminRoleLabel.string }
    var suspendTitle: String { L10n.adminSuspend.string }
    var reactivateTitle: String { L10n.adminReactivate.string }
    var suspendConfirmTitle: String { L10n.adminSuspendConfirmTitle.string }
    var suspendConfirmBody: String { L10n.adminSuspendConfirmBody.string }
    var roleConfirmTitle: String { L10n.adminRoleConfirmTitle.string }
    var roleConfirmBody: String { L10n.adminRoleConfirmBody.string }
    var noMasteryTitle: String { L10n.adminNoMastery.string }

    func masteryTitle(_ user: PlatformUser) -> String {
        user.role == .student ? L10n.adminMasteryValue.string(user.masteryPercent) : noMasteryTitle
    }

    func lastActiveTitle(_ user: PlatformUser) -> String {
        L10n.adminLastActive.string(user.lastLoginAt.formatted(date: .abbreviated, time: .omitted))
    }

    func statusTitle(_ user: PlatformUser) -> String { user.status.title }

    // MARK: Actions

    func load() async {
        state = .loading
        error = nil
        do {
            let accounts = try await store.users()
            state = accounts.isEmpty ? .empty : .loaded(accounts)
        } catch {
            state = .failed(AppError.from(error))
        }
    }

    /// Changes an account's role and records it.
    func setRole(_ role: AppRole, for user: PlatformUser) async {
        var updated = user
        updated.role = role
        await persist(
            updated,
            action: .roleChanged,
            detail: "\(user.displayName): \(user.role.displayName) → \(role.displayName)"
        )
    }

    /// Suspends or reactivates an account, and records it.
    func toggleSuspension(_ user: PlatformUser) async {
        var updated = user
        updated.status = user.isSuspended ? .active : .suspended
        await persist(
            updated,
            action: .accountSuspended,
            detail: "\(user.displayName): \(updated.status.title)"
        )
    }

    private func persist(_ user: PlatformUser, action: AuditAction, detail: String) async {
        do {
            try await store.save(user)
            try await audit.record(AuditEntry(action: action, actorName: actorName, detail: detail))
            await load()
        } catch {
            self.error = AppError.from(error)
        }
    }
}