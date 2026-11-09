//
//  GroupListViewModel.swift
//  StudyForge
//
//  Presentation logic for I08 (`88_GroupSpace_List_{M4}`) and I09
//  (`89_GroupSpace_JoinByCode_{M4}`) — the student's group revision spaces.
//
//  WHY JOINING IS A STORE LOOKUP AND NOT A LIST SCAN
//  -------------------------------------------------
//  Joining creates a membership the student did not have a moment ago, which is a write — so it
//  belongs behind the store seam beside every other write. `GroupStore.group(withInviteCode:)` is
//  that seam, and it is also exactly the call a server-side code index replaces.
//
//  WHERE THE PER-GROUP ONLINE COUNT COMES FROM
//  -------------------------------------------
//  Each row's "3 online" is read from an injected `PresenceProvider`, not from the `isOnline` flags
//  the list happened to load with — the same seam the board uses. The provider is asked once per load,
//  for every group at a time: I08 shows them all at once, and one subscription per row would be one
//  watcher per row, which is why the live watch lives on the board instead.
//

import Foundation

@MainActor
@Observable
final class GroupListViewModel {

    // MARK: Bound state

    var name = ""
    var code = ""

    private(set) var isCreating = false
    private(set) var isJoining = false

    private(set) var state: LoadState<[StudyGroup]> = .idle

    /// A rejected join — I09's error state, kept beside the code field rather than as a banner.
    private(set) var joinError: String?

    private let store: any GroupStore

    /// Where each row's online count comes from. Optional at the call site and defaulted from the store
    /// below, so an existing call site keeps the behaviour it had and a test — or a future realtime
    /// source — passes its own.
    private let presence: any PresenceProvider

    /// The ids the provider last reported online, per group id. Empty until a load has read them, which
    /// renders as "0 online" — the same thing an all-offline group renders as.
    private(set) var onlineMemberIdsByGroup: [String: Set<String>] = [:]

    init(store: any GroupStore, presence: (any PresenceProvider)? = nil) {
        self.store = store
        // Resolved HERE rather than as a default argument, because a default value cannot reference
        // another parameter — and the store is the only thing the default provider needs.
        self.presence = presence ?? StoredPresenceProvider(store: store)
    }

    // MARK: Derived

    var groups: [StudyGroup] { state.value ?? [] }
    var isEmpty: Bool { if case .empty = state { return true }; return false }
    var isLoading: Bool { state.isLoading }
    var error: AppError? { if case .failed(let error) = state { return error }; return nil }

    // MARK: Copy

    var title: String { L10n.groupTitle.string }
    var newGroupTitle: String { L10n.groupNewGroup.string }
    var emptyTitle: String { L10n.groupEmptyTitle.string }
    var emptyBody: String { L10n.groupEmptyBody.string }
    var nameLabel: String { L10n.groupNameLabel.string }
    var namePlaceholder: String { L10n.groupNamePlaceholder.string }
    var createTitle: String { L10n.groupCreate.string }
    var creatingTitle: String { L10n.groupCreating.string }
    var joinTitle: String { L10n.groupJoinTitle.string }
    var codeLabel: String { L10n.groupJoinCodeLabel.string }
    var codePlaceholder: String { L10n.groupJoinCodePlaceholder.string }
    var joinButtonTitle: String { L10n.groupJoin.string }
    var joiningTitle: String { L10n.groupJoining.string }
    var liveNowTitle: String { L10n.groupLiveNow.string }
    var nextSessionTitle: String { L10n.groupNextSession.string }

    func memberCount(_ group: StudyGroup) -> String {
        L10n.groupMemberCount.string(group.members.count)
    }

    /// "3 online" — I08's presence summary, counted from what the provider last reported rather than
    /// from the flags the group was loaded with.
    ///
    /// Counted against the members the row is showing, so the number can never exceed the member count
    /// beside it — a provider that still lists someone who has left cannot inflate it.
    func onlineCount(_ group: StudyGroup) -> String {
        let ids = onlineMemberIdsByGroup[group.id] ?? []
        return L10n.groupPresenceOnline.string(group.members.filter { ids.contains($0.id) }.count)
    }

    /// I08's "live now" badge.
    ///
    /// Driven by the SCHEDULED session time until a realtime presence feed exists: a group whose
    /// session is starting within the next few minutes reads as live. That is a real signal (the
    /// session is on the calendar) rather than a fabricated one.
    func isLive(_ group: StudyGroup) -> Bool {
        guard let at = group.nextSessionAt else { return false }
        return abs(at.timeIntervalSinceNow) <= 300
    }

    /// The next session phrased as a countdown, or `nil` when the group has none scheduled.
    func nextSessionText(_ group: StudyGroup) -> String? {
        guard let at = group.nextSessionAt else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "\(nextSessionTitle) \(formatter.localizedString(for: at, relativeTo: .now))"
    }

    // MARK: Actions

    func load() async {
        state = .loading
        do {
            let groups = try await store.all()
            // Presence is read BEFORE the list is published, so the counts are right on the first
            // render instead of correcting themselves a moment later.
            await refreshPresence(for: groups)
            state = groups.isEmpty ? .empty : .loaded(groups)
        } catch {
            state = .failed(AppError.from(error))
        }
    }

    /// Reads the provider's snapshot for every group just loaded, replacing what was known before.
    ///
    /// A snapshot per group rather than a subscription, because this screen lists all of them at once:
    /// a stream per row would be a watcher per row with no screen to show them on. Asking the provider
    /// is not polling — it happens exactly once per load, and a load happens when the list appears and
    /// after the three actions that change its contents.
    ///
    /// Nothing here throws or sets `error`: a presence read that fails answers with an empty set, so a
    /// group with no answer simply counts nobody online — the list itself is unaffected.
    private func refreshPresence(for groups: [StudyGroup]) async {
        var onlineIds: [String: Set<String>] = [:]
        for group in groups {
            onlineIds[group.id] = await presence.onlineMemberIds(in: group.id)
        }
        onlineMemberIdsByGroup = onlineIds
    }

    /// Creates a group owned by `ownerName`, who is the first member and the host of its quizzes.
    func create(ownerName: String) async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isCreating else { return }

        isCreating = true
        defer { isCreating = false }

        let group = StudyGroup(
            name: trimmed,
            members: [GroupMember(name: ownerName, isOwner: true, isOnline: true)]
        )

        do {
            try await store.add(group)
            name = ""
            await load()
        } catch {
            state = .failed(AppError.from(error))
        }
    }

    /// Joins the group carrying `code`.
    ///
    /// Two failures are expected and both are named rather than generic: a code no group carries, and
    /// a code for a group the student is already in. I09 designs an error state for exactly these.
    func join(as me: String) async {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmed.isEmpty, !isJoining else { return }

        isJoining = true
        defer { isJoining = false }
        joinError = nil

        do {
            guard var group = try await store.group(withInviteCode: trimmed) else {
                joinError = L10n.groupJoinCodeInvalid.string
                return
            }
            guard !group.contains(memberNamed: me) else {
                joinError = L10n.groupJoinAlreadyMember.string
                return
            }
            group.members.append(GroupMember(name: me, isOnline: true))
            group.updatedAt = .now
            try await store.add(group)
            code = ""
            await load()
        } catch {
            joinError = AppError.from(error).message
        }
    }

    func delete(_ group: StudyGroup) async {
        do {
            try await store.delete(id: group.id)
            await load()
        } catch {
            state = .failed(AppError.from(error))
        }
    }

    func clearJoinError() { joinError = nil }
}