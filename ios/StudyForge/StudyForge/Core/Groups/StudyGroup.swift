//
//  StudyGroup.swift
//  StudyForge
//
//  F09 — a group revision space: the classmates in it, the chat they share, the resources pinned to
//  its board, and its live quiz (docs/03 §I, I08–I14; docs/05 §2.4 `groups`).
//
//  WHY THE MEMBERS, MESSAGES AND RESOURCES LIVE ON THE GROUP
//  ---------------------------------------------------------
//  Firestore keeps them in subcollections (`groups/{id}/members`, `groups/{id}/messages`) so a group
//  document stays small. The local, on-device store has no such limit and every screen needs the
//  group at once, so a `StudyGroup` owns them here and the store seam hides a future split — the
//  same reasoning as `SharedFolder` and `BookmarkCollection`.
//
//  WHY THE INVITE CODE IS STORED IN THE CLEAR HERE
//  -----------------------------------------------
//  docs/05 §2.4 hashes the code server-side and keeps the map in `folderInvites/{code}`, which is
//  Cloud-Function-only. This is the LOCAL half of a local-first app: there is no server to hash
//  against, and the code has to be matchable to join a group. When the backend lands, `inviteCode`
//  becomes the hash and the seam does not move.
//

import Foundation

/// A classmate in a group.
struct GroupMember: Identifiable, Equatable, Sendable, Codable {
    let id: String
    var name: String
    var isOwner: Bool

    /// Whether the member is currently present. Drives I10's presence dots. Local-first, this is
    /// whatever the last known state is — a real presence feed arrives with the backend.
    //
    // TODO(M4 · F09): Add a presence seam (a `PresenceProvider` protocol) so member presence
    // comes from a live source instead of the last known value.
    // Done when: the provider is injected, a fake provider updates presence in a test, and the
    // UI reflects it.
    var isOnline: Bool

    init(id: String = UUID().uuidString, name: String, isOwner: Bool = false, isOnline: Bool = false) {
        self.id = id
        self.name = name
        self.isOwner = isOwner
        self.isOnline = isOnline
    }
}

/// One line in the group chat.
struct GroupMessage: Identifiable, Equatable, Sendable, Codable {
    let id: String
    var senderName: String
    var text: String
    let sentAt: Date

    /// A system line ("Sara joined the group") rather than something a person typed. Rendered
    /// centred and undecorated, so it does not read as a message awaiting a reply.
    var isSystem: Bool

    init(
        id: String = UUID().uuidString,
        senderName: String,
        text: String,
        sentAt: Date = .now,
        isSystem: Bool = false
    ) {
        self.id = id
        self.senderName = senderName
        self.text = text
        self.sentAt = sentAt
        self.isSystem = isSystem
    }
}

/// What kind of artefact a pinned group resource points at.
enum GroupResourceKind: String, Sendable, CaseIterable, Codable, Identifiable {
    case material
    case deck
    case summary
    case quiz

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .material: "doc.richtext"
        case .deck: "rectangle.stack"
        case .summary: "text.alignleft"
        case .quiz: "checklist"
        }
    }
}

/// A resource pinned to the group board (I10).
struct GroupResource: Identifiable, Equatable, Sendable, Codable {
    let id: String
    var kind: GroupResourceKind

    /// The id of the underlying artefact — a reference, not a copy, exactly as a folder item or a
    /// bookmark is.
    var referenceId: String
    var title: String
    var pinnedBy: String
    let pinnedAt: Date

    init(
        id: String = UUID().uuidString,
        kind: GroupResourceKind,
        referenceId: String,
        title: String,
        pinnedBy: String,
        pinnedAt: Date = .now
    ) {
        self.id = id
        self.kind = kind
        self.referenceId = referenceId
        self.title = title
        self.pinnedBy = pinnedBy
        self.pinnedAt = pinnedAt
    }
}

/// A group revision space.
struct StudyGroup: Identifiable, Equatable, Sendable, Codable {
    let id: String
    var name: String

    /// A stable seed for I08's cover gradient, so a group always looks the same rather than changing
    /// colour between launches. Derived from the name when the group is created.
    var coverSeed: Int

    /// The six-character code a classmate types to join (I09).
    var inviteCode: String

    var members: [GroupMember]
    var messages: [GroupMessage]
    var resources: [GroupResource]

    /// The next live session, when the group has one. Drives I08's countdown.
    var nextSessionAt: Date?

    let createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        coverSeed: Int? = nil,
        inviteCode: String = StudyGroup.makeInviteCode(),
        members: [GroupMember] = [],
        messages: [GroupMessage] = [],
        resources: [GroupResource] = [],
        nextSessionAt: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.coverSeed = coverSeed ?? Self.seed(for: name)
        self.inviteCode = inviteCode
        self.members = members
        self.messages = messages
        self.resources = resources
        self.nextSessionAt = nextSessionAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var memberCount: Int { members.count }

    /// The most recent message, for I08's "last activity" line and unread dot.
    var lastMessage: GroupMessage? {
        messages.max { $0.sentAt < $1.sentAt }
    }

    /// Whether a member with this name is already present — the duplicate-invite guard, matching
    /// `SharedFolder.contains(memberNamed:)`.
    func contains(memberNamed name: String) -> Bool {
        let needle = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return members.contains { $0.name.lowercased() == needle }
    }

    /// Whether a resource is already pinned.
    func contains(resourceReferenceId referenceId: String, kind: GroupResourceKind) -> Bool {
        resources.contains { $0.referenceId == referenceId && $0.kind == kind }
    }

    // MARK: Cover seed

    /// A deterministic seed from the name, so the same group always draws the same cover.
    ///
    /// A stable hash rather than `hashValue`, which is randomised per launch and would reshuffle
    /// every group's colour on every cold start.
    static func seed(for name: String) -> Int {
        name.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0x7fff_ffff }
    }

    /// A six-character invite code from an unambiguous alphabet.
    ///
    /// I, O, 0 and 1 are excluded on purpose: a code is read off a screen and typed by hand, and a
    /// code containing `0`/`O` is a support ticket waiting to happen.
    static func makeInviteCode() -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).map { _ in alphabet.randomElement() ?? "A" })
    }
}