//
//  ModerationCopy.swift
//  StudyForge
//
//  F16 — the words N01–N03 put on screen, in one place (docs/03 §N).
//
//  WHY THE COPY IS REUSED RATHER THAN ADDED
//  ----------------------------------------
//  `Core/Localisation/` belongs to M1's lane, so F16 may not add cases to `L10n`, and a screen
//  may not carry a bare key string either — see the header of `L10n.swift`, which explains why a
//  typo'd key compiles and only shows up in a screenshot. Every string below therefore resolves an
//  EXISTING key from the app's vocabulary, which is the same approach `StudyPlanWizardView`
//  documents for its subject rows. The wording is close rather than exact in three places and each
//  is called out: when M1 adds a `group.moderation.*` family, these become one-line swaps and no
//  view changes.
//
//  WHY THE MAPPINGS LIVE IN THE VIEW LAYER AND NOT IN THE MODEL
//  -----------------------------------------------------------
//  `Core/Groups/Moderation/GroupModeration.swift` deliberately holds no prose: it is the state and
//  the rules, readable and testable without a bundle. The words belong with the screens that show
//  them, so they live here, beside the tombstone and the reason sheet that use them.
//

import Foundation

extension ModerationReason {

    /// The reason's name, for N03's tombstone line and N02's picker.
    ///
    /// `unsafe` borrows the admin queue's "Harassment" until a group-chat reason key exists: it is
    /// the only harm category the catalogue already names, and the alternatives — the raw value
    /// `unsafe`, or a new hard-coded English word — would be worse in the Arabic build. `spam`,
    /// `offTopic` and `other` resolve to keys that already mean exactly what they say.
    var title: String {
        switch self {
        case .spam: L10n.adminReportReasonSpam.string
        case .offTopic: L10n.coachReasonOffTopic.string
        case .unsafe: L10n.adminReportReasonHarassment.string
        case .other: L10n.adminReportReasonOther.string
        }
    }
}

extension ModerationActionKind {

    /// The action's name, used as N02's row title and as the reason sheet's title.
    ///
    /// `hide` reads "Remove content" and `pin` reads "Pinned resources" — the closest existing
    /// phrases. N02's frame specifies "Hide for everyone" and "Pin to board"; those two lines are
    /// the ones a `group.moderation.*` key family should replace first.
    var title: String {
        switch self {
        case .hide: L10n.adminModerationRemove.string
        case .delete: L10n.commonDelete.string
        case .pin: L10n.groupBoardHeading.string
        case .flag: L10n.adminModerationEscalate.string
        }
    }

    /// What the action does to the room, shown under its row so the choice is made with the
    /// consequence in view rather than after it.
    ///
    /// `pin` and `delete` have no honest existing sentence — the catalogue's only removal body
    /// mentions the reporter, which a group chat does not have — so they carry no subtitle rather
    /// than a wrong one.
    var consequence: String? {
        switch self {
        case .hide: L10n.adminModerationRemoveBody.string
        case .delete: nil
        case .pin: nil
        case .flag: L10n.adminModerationEscalateBody.string
        }
    }

    /// The SF Symbol N02's row uses. Destructive things look destructive before they are read.
    var symbolName: String {
        switch self {
        case .hide: "eye.slash"
        case .delete: "trash"
        case .pin: "pin"
        case .flag: "flag"
        }
    }
}
