//
//  PresenceProvider.swift
//  StudyForge
//
//  F09 — where "who is online in this group" comes from, and the seam that hides FROM WHERE.
//
//  WHY THIS SEAM EXISTS
//  --------------------
//  `GroupMember.isOnline` is a STORED flag, so the I10 presence dots and I08's "3 online" summary can
//  only ever show what the last save happened to record — and a real presence feed belongs to a
//  realtime backend that is not wired up yet. This protocol is the seam that feed arrives behind,
//  exactly as `GroupStore` is the seam for the groups themselves, so the SOURCE of the answer can
//  change without any screen changing.
//
//  WHY IT HOLDS NO STATE
//  ---------------------
//  A provider is asked one question and answers it; it is not a second cache of the group. Keeping
//  the group itself out of this file is what lets a socket-backed implementation be added later
//  without a single view model learning about sockets.
//
//  WHY TWO METHODS, NOT ONE
//  ------------------------
//  The two screens need different things from the same answer:
//    · I08's list needs "how many are online" when the list loads — a snapshot.
//    · I10's board shows a dot per member and must keep showing the truth while it is open — a
//      subscription.
//  This is the same shape `AuthService` already uses (`currentSession()` for the one-off read,
//  `stateChanges()` for the live one), so it is the house pattern rather than an invention.
//

import Foundation

/// Answers which members are currently present in a group, and reports changes while one is open.
///
/// Conformers are `Sendable` because presence is read from view models that hop actors. The
/// production conformance answers from the last-known flags the local store holds; a realtime feed
/// replaces it without any screen changing.
protocol PresenceProvider: Sendable {

    /// The ids of the members online in `groupId` right now.
    ///
    /// A SNAPSHOT, for a screen that renders presence once and moves on. It is `async` because a
    /// source may have to be asked, and deliberately NOT `throws`: a presence read that fails is not
    /// worth an error banner over a board that is otherwise fine, and the honest fallback — the last
    /// known value — is exactly what the screen showed before this seam existed.
    ///
    /// - Returns: the online member ids. An empty set means "nobody, or nothing known", and the UI
    ///   renders both the same way: no dot lit.
    func onlineMemberIds(in groupId: String) async -> Set<String>

    /// The ids of the members online in `groupId`, emitted immediately and then on every change.
    ///
    /// A STREAM rather than a callback, for the reason `AuthService.stateChanges()` is one: the
    /// subscription's lifetime belongs to the caller, so a view model cannot leak a closure into a
    /// longer-lived object.
    ///
    /// The first element is the CURRENT value, so a subscriber never has to take a snapshot first and
    /// then race it. A provider with no live source emits that value once and finishes, which leaves
    /// a subscriber holding exactly what the snapshot would have given it.
    func presenceChanges(in groupId: String) -> AsyncStream<Set<String>>
}
