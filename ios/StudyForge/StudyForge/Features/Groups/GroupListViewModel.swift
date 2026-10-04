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

    init(store: any GroupStore) {
        self.store = store
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

    /// "3 online" — I08's presence summary.
    func onlineCount(_ group: StudyGroup) -> String {
        L10n.groupPresenceOnline.string(group.members.filter(\.isOnline).count)
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
            state = groups.isEmpty ? .empty : .loaded(groups)
        } catch {
            state = .failed(AppError.from(error))
        }
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