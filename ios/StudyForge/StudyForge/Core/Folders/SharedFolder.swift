//
//  SharedFolder.swift
//  StudyForge
//
//  A shared study folder: the members who can see it, the artefacts inside it, and each member's
//  permission.
//
//  WHY THE MEMBERS AND ITEMS LIVE ON THE FOLDER
//  -------------------------------------------
//  Firestore splits them (`folders/{id}/members`, `folders/{id}/items`) so a folder document stays
//  small and each item can be granted individually. The local, on-device store has no such limit and
//  every screen needs the whole folder at once, so a `SharedFolder` owns its members and items here,
//  and the store seam hides a future split.
//
//  PERMISSIONS ARE A VOCABULARY, NOT A FEATURE
//  -------------------------------------------
//  `FolderPermission` is the same three words the security rules and F12's admin screens use
//  (`view` / `comment` / `edit`). What each one ALLOWS is expressed here as capability properties, so
//  the UI and the tests agree about it — while the actual ENFORCEMENT stays where it belongs, in
//  `backend/firestore.rules`, because a client can always lie about its own permission.
//

import Foundation

/// What a member is allowed to do in a folder. The stored vocabulary from docs/05 §2.4.
enum FolderPermission: String, Sendable, CaseIterable, Codable, Identifiable {
    case view
    case comment
    case edit

    var id: String { rawValue }

    /// Whether this permission allows adding items to the folder.
    ///
    /// Only `edit` can. `comment` may discuss what is already shared; `view` may only read — which is
    /// why the "Add item" control is hidden rather than merely disabled for those members.
    var canAddItems: Bool { self == .edit }
}

/// A person the folder is shared with.
struct FolderMember: Identifiable, Equatable, Sendable, Codable {
    let id: String
    var name: String
    var permission: FolderPermission

    /// The folder's owner. Exactly one member carries this, and the owner's permission is not
    /// editable — there is no "edit the owner's access" that makes sense.
    var isOwner: Bool

    init(
        id: String = UUID().uuidString,
        name: String,
        permission: FolderPermission = .view,
        isOwner: Bool = false
    ) {
        self.id = id
        self.name = name
        self.permission = permission
        self.isOwner = isOwner
    }
}

/// What kind of artefact a folder item points at.
enum FolderItemKind: String, Sendable, CaseIterable, Codable {
    case material
    case deck
    case summary
    case quiz

    var symbolName: String {
        switch self {
        case .material: "doc.richtext"
        case .deck: "rectangle.stack"
        case .summary: "text.alignleft"
        case .quiz: "checklist"
        }
    }
}

/// A reference to an artefact shared into a folder.
///
/// A REFERENCE, not a copy: the artefact keeps living in the owner's own stores, and the folder only
/// records that it is shared and under what name it appears. Copying would fork the student's deck
/// the moment they shared it.
struct FolderItem: Identifiable, Equatable, Sendable, Codable {
    let id: String
    var kind: FolderItemKind

    /// The id of the underlying artefact (a material, deck, summary or quiz).
    var referenceId: String

    /// A copied label, so the folder can list an item without loading the artefact.
    var title: String

    let addedAt: Date

    init(
        id: String = UUID().uuidString,
        kind: FolderItemKind,
        referenceId: String,
        title: String,
        addedAt: Date = .now
    ) {
        self.id = id
        self.kind = kind
        self.referenceId = referenceId
        self.title = title
        self.addedAt = addedAt
    }
}

/// A folder shared with a study group.
struct SharedFolder: Identifiable, Equatable, Sendable, Codable {
    let id: String
    var name: String
    var members: [FolderMember]
    var items: [FolderItem]
    let createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        members: [FolderMember] = [],
        items: [FolderItem] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.members = members
        self.items = items
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// The owner, when one is recorded.
    var owner: FolderMember? { members.first { $0.isOwner } }

    /// Whether the folder already contains a reference to the given artefact.
    ///
    /// Guards against the duplicate the design calls out ("inviting an existing member" has a sibling
    /// here): adding the same material twice would show it twice and share it once.
    func contains(referenceId: String, kind: FolderItemKind) -> Bool {
        items.contains { $0.referenceId == referenceId && $0.kind == kind }
    }

    /// Whether a member with this name is already present.
    func contains(memberNamed name: String) -> Bool {
        let needle = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return members.contains { $0.name.lowercased() == needle }
    }
}