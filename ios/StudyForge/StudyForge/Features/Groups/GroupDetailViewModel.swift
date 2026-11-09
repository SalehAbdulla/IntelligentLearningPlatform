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
//  WHY PRESENCE ARRIVES THROUGH A SEAM
//  -----------------------------------
//  A member's dot is presence, not membership: `GroupMember.isOnline` is only whatever the store last
//  saved. So the board asks a `PresenceProvider` instead, and that provider is defaulted from the SAME
//  store this view model already holds — behaviour is unchanged until a realtime provider is passed
//  in, and passing one changes no call site.
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

    /// Where the member dots get their answer. Optional at the call site and defaulted from the store
    /// above, so an existing call site keeps the behaviour it had and a test — or a future realtime
    /// source — passes its own.
    private let presence: any PresenceProvider

    /// The ids the provider last reported online. Empty until it has spoken, which the UI renders the
    /// same way it renders "nobody online": no dot lit.
    private(set) var onlineMemberIds: Set<String> = []

    /// Which observation owns `onlineMemberIds`. Only the newest one writes; an older one may still be
    /// awaiting its cancellation for a moment while the switch happens.
    private var presenceGeneration = 0

    /// How the newest observation ends the one it replaces — by `finish()`ing the interrupt stream the
    /// older call is waiting on.
    ///
    /// A continuation rather than a `Task`, deliberately: `finish()` is the only handle needed to wake
    /// the older observation, and a continuation cannot keep anything running on its own. That is what
    /// lets a second observation genuinely cancel the first without introducing an unstructured task
    /// that could outlive the view's `.task`.
    ///
    /// The observation that installs a handle also clears it again when it exits — see the cleanup in
    /// `observePresence()`, which is generation-aware so that a replaced observation cannot clear the
    /// handle belonging to the observation that replaced it.
    private var presenceInterrupt: AsyncStream<Void>.Continuation?

    init(
        groupId: String,
        store: any GroupStore,
        materials: any MaterialStore,
        presence: (any PresenceProvider)? = nil
    ) {
        self.groupId = groupId
        self.store = store
        self.materials = materials
        // Resolved HERE rather than as a default argument, because a default value cannot reference
        // another parameter — and the store is the only thing the default provider needs.
        self.presence = presence ?? StoredPresenceProvider(store: store)
    }

    // MARK: Derived

    var group: StudyGroup? { state.value }
    var isLoading: Bool { state.isLoading }
    var resources: [GroupResource] { state.value?.resources.sorted { $0.pinnedAt > $1.pinnedAt } ?? [] }
    var members: [GroupMember] { state.value?.members ?? [] }
    var hasResources: Bool { !resources.isEmpty }

    /// Whether this member's dot is lit, according to the provider.
    func isOnline(_ member: GroupMember) -> Bool { onlineMemberIds.contains(member.id) }

    /// "· N online" — counted against the members the board is actually showing, so the header can
    /// never claim more people online than it has rows for.
    var onlineCount: Int { members.filter { isOnline($0) }.count }

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

    // MARK: Presence

    /// Watches presence for this group and keeps `onlineMemberIds` current.
    ///
    /// Meant to be driven by the view's `.task`, which SwiftUI cancels when the board goes away. That
    /// cancellation reaches the reading below because everything here is STRUCTURED: the work runs in
    /// child tasks of this call, so it cannot outlive the caller's task, and when the provider's stream
    /// is dropped its own `onTermination` runs — which is what stops its read and leaves nothing
    /// subscribed behind.
    ///
    /// Starting a second observation ENDS the first. The older observation is woken through
    /// `presenceInterrupt`, and its group then cancels the reader it shares the group with — so a
    /// provider whose stream stays open without ever emitting again cannot leave a loop suspended.
    /// That is precisely the case a generation check alone could not fix: it could stop the old loop
    /// from WRITING, but it could not stop it WAITING.
    ///
    /// The reader is a child task rather than this task itself for that reason — the caller's task is
    /// not ours to cancel, so a design that claims to end the older observation has to own the work it
    /// ends. A cancellation that only looks like one is worse than none at all.
    func observePresence() async {
        presenceGeneration += 1
        let generation = presenceGeneration

        // Wake the observation this one replaces: finishing its interrupt ends the child that was
        // waiting on it, and cancelling the group is what stops the reader.
        presenceInterrupt?.finish()
        let (interrupt, interrupted) = AsyncStream<Void>.makeStream()
        presenceInterrupt = interrupt

        // On the way out — finished, replaced or cancelled — this observation drops the handle it put
        // there, so the view model keeps no reference to a stream nobody is reading any more.
        //
        // The generation IS the ownership test. The stored continuation belongs to whichever call last
        // incremented `presenceGeneration`, so comparing that number with this call's own decides
        // whether the handle above is still ours. An older observation that exits after a newer one has
        // started sees a different generation and leaves the newer handle alone — clearing it
        // unconditionally is the bug this guard prevents, because it would silently disable the
        // cancellation of the observation that is still running.
        defer {
            if generation == presenceGeneration {
                // Finishing first is idempotent (a replaced observation's handle is already finished),
                // and it also ends the interrupt child deterministically rather than leaving that to
                // cancellation reaching it. Then the handle itself goes.
                presenceInterrupt?.finish()
                presenceInterrupt = nil
            }
        }

        await withTaskGroup(of: Void.self) { group in
            // The reader: every emission is applied on the main actor, and only if this observation
            // is still the newest one.
            group.addTask { [presence, groupId] in
                for await ids in presence.presenceChanges(in: groupId) {
                    await self.applyPresence(ids, generation: generation)
                }
            }

            // The interrupt: it spends its whole life waiting to be told this observation is over.
            group.addTask {
                for await _ in interrupted { return }
            }

            // Whichever finishes first ends the observation, and takes the other with it. `cancelAll`
            // is what ends the reader's `for await` — which finishes a stream that never emitted again.
            // Discarded explicitly: `next()` is not `@discardableResult`.
            _ = await group.next()
            group.cancelAll()
        }
    }

    /// Stores an emission, unless this observation has already been replaced by a newer one.
    ///
    /// A separate main-actor method because the reader is a child task: it is not main-actor isolated,
    /// so the hop is explicit here rather than assumed.
    private func applyPresence(_ ids: Set<String>, generation: Int) {
        guard generation == presenceGeneration else { return }
        onlineMemberIds = ids
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