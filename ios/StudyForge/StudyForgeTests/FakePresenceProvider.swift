//
//  FakePresenceProvider.swift
//  StudyForgeTests
//
//  F09 — the presence double the tests inject, so a screen can be driven from a source whose every
//  answer, and every change, the test decides.
//
//  WHY NOT AN ACTOR
//  ----------------
//  `PresenceProvider.presenceChanges(in:)` is SYNCHRONOUS and non-isolated, and an actor cannot satisfy
//  it: an actor's state is reachable only from inside its own isolation, and a `nonisolated` method
//  cannot read that state synchronously. So this is a `final class` whose mutable state sits behind a
//  `Mutex` — the same shape `AuthStateBroadcaster` uses for `AuthService.stateChanges()`. A reference
//  type with a lock is the house answer to this shape of protocol, not a workaround for it.
//
//  WHAT IT DELIBERATELY IS NOT
//  ---------------------------
//  Not a production provider, and not a simulation of one. It never reads the group store, never polls
//  and never fires on its own: presence changes only when a test says so. That is what makes the
//  assertions in `GroupViewModelTests` deterministic rather than timing-dependent.
//
//  WHY THE SUBSCRIBER ID IS A COUNTER, NOT A `UUID`
//  ------------------------------------------------
//  The id only ever identifies a subscription — it is never emitted, never ordered and never compared
//  with anything a test can see. A counter means nothing in this file is random at all, and a flaky
//  test costs more than the two lines it saves.
//
//  WHY DELIVERIES GO THROUGH A QUEUE RATHER THAN STRAIGHT OUT
//  ---------------------------------------------------------
//  Resuming a continuation while the state mutex is held is not allowed, but resuming one after
//  releasing it delivers out of order: two concurrent updates can set their snapshots in one order and
//  hand their values over in the other, so a subscriber ends up holding the OLDER value last. So every
//  value is appended to an ordered `pending` queue INSIDE the state lock — which is what makes the
//  queue's order identical to the order the state actually changed in — and exactly one thread drains
//  that queue, resuming continuations only after the lock is released. `isDraining` is the
//  single-drainer flag, and it is cleared inside the same critical section that finds the queue empty,
//  so there is no interleaving in which work is queued with nobody left to deliver it.
//

import Foundation
import Synchronization
@testable import StudyForge

/// A deterministic `PresenceProvider` whose snapshots and updates a test controls.
final class FakePresenceProvider: PresenceProvider, @unchecked Sendable {

    /// One thing waiting to be handed to subscribers, in the order it was produced.
    ///
    /// The recipients are resolved when the delivery is QUEUED, not when it is drained: a subscriber
    /// that arrives later must not be handed an older value after its own first one.
    private enum Delivery {
        case presence(Set<String>, [AsyncStream<Set<String>>.Continuation])
        case finish([AsyncStream<Set<String>>.Continuation])
    }

    private struct State {
        /// What each group's presence is, whether or not anyone is watching it.
        var snapshots: [String: Set<String>]

        /// Subscribers per group. A group may have more than one watcher, and each gets every update.
        var subscribers: [String: [Int: AsyncStream<Set<String>>.Continuation]] = [:]

        /// The next subscription id, monotonic so that two subscriptions are never mistaken for one
        /// another when one of them ends.
        var nextSubscriberId = 0

        /// Work waiting to be delivered, oldest first. Appended under the lock, so this order IS the
        /// order in which the state changed.
        var pending: [Delivery] = []

        /// Whether a thread is draining `pending`. At most one may be, and the flag is only ever
        /// cleared in the critical section that finds the queue empty.
        var isDraining = false
    }

    /// All of the state, behind one lock.
    ///
    /// `@unchecked Sendable` here is an explicit promise rather than a guess: every read and every write
    /// below goes through this lock, and it is the only stored property — the same choice
    /// `AuthStateBroadcaster` makes.
    private let state: Mutex<State>

    /// - Parameter onlineMemberIds: the presence each group starts with, keyed by group id. A group that
    ///   is absent is simply not known, and answers the way an all-offline group does: nobody online.
    init(onlineMemberIds: [String: Set<String>] = [:]) {
        self.state = Mutex(State(snapshots: onlineMemberIds))
    }

    // MARK: PresenceProvider

    /// The snapshot this fake holds for `groupId` — whatever the test last set, or nothing at all.
    func onlineMemberIds(in groupId: String) async -> Set<String> {
        state.withLock { $0.snapshots[groupId] ?? [] }
    }

    /// The current snapshot immediately, and then every change the test makes for this group, in order.
    ///
    /// Registering, reading the current value and queueing it as this subscriber's FIRST delivery
    /// happen in ONE critical section. An update therefore either happened before it — in which case its
    /// value IS the one being handed over, and this subscriber was not registered in time to receive it
    /// twice — or it happens after, in which case it is queued behind this delivery. There is no
    /// position in between from which a duplicate or an out-of-order value could come.
    func presenceChanges(in groupId: String) -> AsyncStream<Set<String>> {
        AsyncStream { continuation in
            let (id, shouldDrain): (Int, Bool) = state.withLock { state in
                let id = state.nextSubscriberId
                state.nextSubscriberId += 1
                state.subscribers[groupId, default: [:]][id] = continuation
                state.pending.append(.presence(state.snapshots[groupId] ?? [], [continuation]))

                if state.isDraining { return (id, false) }
                state.isDraining = true
                return (id, true)
            }

            // A subscriber that goes away — the board closes, the test cancels or finishes — is
            // forgotten, so the fake never keeps feeding a stream nobody reads.
            continuation.onTermination = { [weak self] _ in
                self?.remove(id, in: groupId)
            }

            if shouldDrain { drain() }
        }
    }

    // MARK: Test controls

    /// Sets a group's presence, and queues that value for every subscriber watching the group.
    ///
    /// The snapshot and the queue entry are written in ONE critical section, and the recipients are
    /// resolved there too. That is the whole guarantee: because both the state change and its position in
    /// the queue happen under the same lock, the queue's order cannot disagree with the order the state
    /// changed in — so two concurrent calls cannot have their values delivered the other way round.
    ///
    /// Every call emits, even when the ids are unchanged — deliberately unlike
    /// `AuthStateBroadcaster.send`, which drops a no-op because SwiftUI would re-render for nothing. A
    /// test that asks for an emission should get one.
    func setOnline(_ memberIds: Set<String>, in groupId: String) {
        let shouldDrain = state.withLock { state -> Bool in
            state.snapshots[groupId] = memberIds
            state.pending.append(.presence(memberIds, (state.subscribers[groupId] ?? [:]).map(\.value)))

            if state.isDraining { return false }
            state.isDraining = true
            return true
        }

        if shouldDrain { drain() }
    }

    /// Ends `groupId`'s streams, so a caller awaiting `presenceChanges` returns.
    ///
    /// This is what makes watching the board testable: set the presence, then finish, then await the
    /// observation.
    ///
    /// The subscribers are unregistered immediately, so an update made afterwards has nobody to hand a
    /// value to — but the end itself goes through the queue like any other delivery, so values queued
    /// BEFORE this call are still handed over first. Nothing a test emitted can be lost by finishing
    /// afterwards, and nothing can be delivered after the end.
    func finishUpdates(in groupId: String) {
        let shouldDrain = state.withLock { state -> Bool in
            let groupSubscribers = (state.subscribers[groupId] ?? [:]).map(\.value)
            state.subscribers[groupId] = nil
            state.pending.append(.finish(groupSubscribers))

            if state.isDraining { return false }
            state.isDraining = true
            return true
        }

        if shouldDrain { drain() }
    }

    // MARK: Delivery

    /// Hands queued work to the continuations, oldest first, until the queue runs out.
    ///
    /// Only the thread that set `isDraining` reaches here, and every continuation is resumed HERE —
    /// outside the lock. That combination is the point of the queue: delivery is serialised in the order
    /// the state changed, without a single resume happening under the mutex.
    private func drain() {
        while let delivery = nextDelivery() {
            switch delivery {
            case .presence(let value, let subscribers):
                for continuation in subscribers {
                    continuation.yield(value)
                }
            case .finish(let subscribers):
                for continuation in subscribers {
                    continuation.finish()
                }
            }
        }
    }

    /// Pops the oldest queued delivery, or ends the drain when there is none left.
    ///
    /// Clearing `isDraining` in the SAME critical section as the emptiness check is what makes the
    /// single-drainer rule airtight. A producer either appends while the flag is still set — and this
    /// loop is then certain to see that item, because it only stops after finding the queue empty under
    /// the lock — or it appends after the flag was cleared, in which case it becomes the drainer itself.
    /// There is no interleaving in which work sits queued with nobody draining it.
    private func nextDelivery() -> Delivery? {
        state.withLock { state in
            guard !state.pending.isEmpty else {
                state.isDraining = false
                return nil
            }
            return state.pending.removeFirst()
        }
    }

    // MARK: Helpers

    private func remove(_ id: Int, in groupId: String) {
        state.withLock { state in
            state.subscribers[groupId]?[id] = nil
            // The group's row goes with its last subscriber, so a test that subscribes repeatedly does
            // not leave empty dictionaries behind.
            if state.subscribers[groupId]?.isEmpty == true {
                state.subscribers[groupId] = nil
            }
        }
    }
}
