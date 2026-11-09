//
//  StoredPresenceProvider.swift
//  StudyForge
//
//  F09 — the presence source the app runs on today: the flags the group store already holds.
//
//  WHAT IT IS
//  ----------
//  The default `PresenceProvider`. `GroupMember.isOnline` is persisted by the group store, so asking
//  that store IS asking the only presence source the app currently has. This conformance therefore
//  adds the seam and changes no behaviour — which is what makes swapping in a realtime provider a
//  change at the call site rather than a rewrite of every screen that shows a dot.
//
//  WHY IT RE-READS THE STORE INSTEAD OF BEING HANDED THE GROUP
//  ----------------------------------------------------------
//  The obvious shortcut is to pass the `StudyGroup` the screen has already loaded and read its flags.
//  That would make the provider a copy of a snapshot, and the moment the group is written anywhere
//  else — a member joins, a resource is pinned — the copy is stale with nothing able to tell. Asking
//  the store by id keeps ONE source of truth, and it is the only shape a realtime provider can also
//  have: "give me the online member ids for this group", without being handed the model first.
//
//  WHAT IT DELIBERATELY DOES NOT DO
//  --------------------------------
//  No timer, no polling, no network, no invented backend. `GroupStore` publishes NO change notification
//  — it is five async methods and nothing else, and neither `FileGroupStore` nor `InMemoryGroupStore`
//  announces a write — so there is no event to subscribe to. The consequence is documented on
//  `presenceChanges(in:)` rather than hidden behind a poll that would fake liveliness.
//

import Foundation

/// Answers presence from the last-known value the local group store holds.
///
/// The default `PresenceProvider`. It reads the group by id on every call, so it can never become a
/// stale copy of whatever group the screen happens to be holding.
struct StoredPresenceProvider: PresenceProvider {

    /// The groups, and so the member flags, this provider reads. Injected exactly as the group screens
    /// take it, so a test or a preview drives it with `InMemoryGroupStore`.
    private let store: any GroupStore

    init(store: any GroupStore) {
        self.store = store
    }

    // MARK: PresenceProvider

    /// The ids of the members the store currently records as online in `groupId`.
    ///
    /// - Returns: the ids flagged `isOnline` on the stored group, and an EMPTY SET in two different
    ///   situations: no group is stored under that id, and the READ FAILED. Both return empty because
    ///   `PresenceProvider` deliberately does not throw, and the consequence is worth stating plainly
    ///   rather than glossing over: this cannot distinguish a failed read from a group whose members
    ///   are all offline, and nothing here guarantees that such a failure reaches the student. The
    ///   screen's own load is a SEPARATE read — it may well have succeeded before this one failed — so
    ///   its error is not a stand-in for this one.
    ///
    ///   A caller that must tell the two apart cannot do so through this protocol as it stands; that
    ///   would need a throwing or status-returning variant, which is a deliberate non-goal here.
    func onlineMemberIds(in groupId: String) async -> Set<String> {
        do {
            guard let group = try await store.group(id: groupId) else { return [] }
            return Set(group.members.filter(\.isOnline).map(\.id))
        } catch {
            return []
        }
    }

    /// The current presence, emitted once and then finished.
    ///
    /// WHY THERE IS NO SECOND EMISSION, AND WHY THAT IS NOT AN OVERSIGHT
    /// ----------------------------------------------------------------
    /// A subscription here would have nothing to subscribe TO. `GroupStore` publishes no changes (see
    /// this file's header), so any other implementation would either poll on a timer or replay a value
    /// it had invented — and a dot that lights up because a timer guessed is worse than a dot that is
    /// merely behind. The honest implementation is the one the protocol already describes for a source
    /// with no live feed: emit the current value once and finish, which leaves the subscriber holding
    /// exactly what the snapshot would have given it.
    ///
    /// The cost, stated plainly: while the board is open, a member whose flag changes in the store is
    /// NOT reflected until the provider is asked again. Making that live is the realtime provider's
    /// job, and it is a swap at the call site rather than a change to any screen.
    func presenceChanges(in groupId: String) -> AsyncStream<Set<String>> {
        AsyncStream { continuation in
            // A task, because the stream's builder closure is not itself async.
            let read = Task {
                continuation.yield(await onlineMemberIds(in: groupId))
                continuation.finish()
            }
            // A subscriber that stops early — the board closes — must not leave the read running.
            continuation.onTermination = { _ in read.cancel() }
        }
    }
}
