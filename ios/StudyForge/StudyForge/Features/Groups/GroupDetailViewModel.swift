//
//  GroupDetailViewModel.swift
//  StudyForge
//
//  Presentation logic for I10 (`90_GroupSpace_Detail_Board_{M4}`) — the group board: pinned
//  resources, the member list, and the way into the chat and the live quiz.
//
//  WHY IT RELOADS BY ID
//  --------------------
//  Pinning a resource rewrites the group, so the screen reads it back from the store rather than
//  mutating a held copy. One source of truth is what keeps the member count and the pins in step.
//

import Foundation

@MainActor
@Observable
final class GroupDetailViewModel {

    private(set) var state: LoadState<StudyGroup> = .idle

    /// Kept SEPARATE from `state` so a failed action does not blank out the board already on screen.
    private(set) var error: AppError?

    private let groupId: String
    private let store: any GroupStore
    private let materials: any MaterialStore

    init(groupId: String, store: any GroupStore, materials: any MaterialStore) {
        self.groupId = groupId
        self.store = store
        self.materials = materials
    }

    // MARK: Derived

    var group: StudyGroup? { state.value }
    var isLoading: Bool { state.isLoading }
    var resources: [GroupResource] { state.value?.resources.sorted { $0.pinnedAt > $1.pinnedAt } ?? [] }
    var members: [GroupMember] { state.value?.members ?? [] }
    var hasResources: Bool { !resources.isEmpty }

    /// Whether the signed-in student owns this group — and so hosts its quizzes.
    func isHost(_ me: String) -> Bool {
        group?.members.contains { $0.name == me && $0.isOwner } ?? false
    }

    // MARK: Copy

    var boardHeading: String { L10n.groupBoardHeading.string }
    var membersHeading: String { L10n.groupMembersHeading.string }
    var noResourcesTitle: String { L10n.groupNoResources.string }
    var addResourceTitle: String { L10n.groupBoardHeading.string }
    var inviteCodeLabel: String { L10n.groupInviteCodeLabel.string }
    var chatTitle: String { L10n.groupChatTitle.string }
    var startQuizTitle: String { L10n.groupStartQuiz.string }
    var liveNowTitle: String { L10n.groupLiveNow.string }

    func memberCountTitle(_ count: Int) -> String { L10n.groupMemberCount.string(count) }
    func onlineTitle(_ count: Int) -> String { L10n.groupPresenceOnline.string(count) }

    // MARK: Loading

    func load() async {
        state = .loading
        error = nil
        do {
            guard let group = try await store.group(id: groupId) else {
                state = .empty
                return
            }
            state = .loaded(group)
        } catch {
            self.error = AppError.from(error)
        }
    }

    /// Materials not already pinned here, for the pin picker.
    func availableMaterials() async -> [Material] {
        guard let group else { return [] }
        do {
            return try await materials.all().filter {
                !group.contains(resourceReferenceId: $0.id, kind: .material)
            }
        } catch {
            self.error = AppError.from(error)
            return []
        }
    }

    // MARK: Actions

    func pin(_ material: Material, by me: String) async {
        await mutate { group in
            guard !group.contains(resourceReferenceId: material.id, kind: .material) else { return }
            group.resources.append(
                GroupResource(kind: .material, referenceId: material.id, title: material.title, pinnedBy: me)
            )
        }
    }

    func unpin(_ resource: GroupResource) async {
        await mutate { $0.resources.removeAll { $0.id == resource.id } }
    }

    // MARK: Mutation

    private func mutate(_ change: (inout StudyGroup) -> Void) async {
        guard var group else { return }
        change(&group)
        group.updatedAt = .now
        do {
            try await store.add(group)
            state = .loaded(group)
        } catch {
            self.error = AppError.from(error)
        }
    }
}