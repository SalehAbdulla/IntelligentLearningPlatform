//
//  ModeratorPresenceBanner.swift
//  StudyForge
//
//  F16 — N01, `142_GroupChat_Moderator_Presence_Banner_{M5}` (docs/03 §N).
//
//  WHY THE BANNER EXISTS AT ALL
//  ----------------------------
//  The brief's requirement is that an admin is ALWAYS in a group's chat. The guarantee itself
//  cannot live in a view — `ModerationPolicy.canRemoveModerator()` and `firestore.rules` are what
//  make it true — but a guarantee a member cannot see is indistinguishable from one that was never
//  made. The banner is the visible half: it names the moderator, carries the shield badge, and
//  sits above the conversation on every load rather than being dismissible.
//
//  WHY IT TAKES THE MODERATOR RATHER THAN THE VIEW MODEL
//  ----------------------------------------------------
//  It renders one value and decides nothing, so it can be previewed and reused by any screen that
//  knows who moderates. The view model already exposes the fold (`GroupChatViewModel.moderation`);
//  passing the `GroupModerator` keeps this component free of state.
//
//  THE COPY: "Admin · Active" rather than "always in this space"
//  -----------------------------------------------------------
//  Both halves are catalogue keys (`session.role.admin`, `admin.status.active`), so the banner is
//  translated in Arabic and needs no new strings from M1's lane. N01's exact sentence and its
//  plain-language reason for permanence need a `group.moderation.*` family — see
//  `ModerationCopy.swift` for why that is a follow-up rather than a shortcut taken here.
//

import SwiftUI

struct ModeratorPresenceBanner: View {

    let moderator: GroupModerator

    var body: some View {
        HStack(spacing: Spacing.s3) {
            avatar

            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(moderator.displayName)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textSecondary)
            }

            Spacer(minLength: Spacing.s2)
        }
        .padding(.horizontal, Layout.screenMargin)
        .padding(.vertical, Spacing.s2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTokens.primaryContainer)
        .overlay(alignment: .bottom) {
            Divider()
        }
        // One element: "Fatema Ghareeb, Admin, Active". The shield is decorative — the subtitle
        // already says the role, and an icon name read aloud would add noise, not information.
        .accessibilityElement(children: .combine)
    }

    /// The avatar with the shield badge N01 asks for. A badge rather than a colour change,
    /// because colour alone must never be the only signal.
    private var avatar: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(systemName: "person.crop.circle.fill")
                .font(.sfTitleL)
                .foregroundStyle(ColorTokens.onPrimaryContainer)

            Image(systemName: "checkmark.shield.fill")
                .font(.sfCaption)
                .foregroundStyle(ColorTokens.primary)
                .padding(Spacing.s1 / 2)
                .background(ColorTokens.surface, in: .circle)
        }
        .accessibilityHidden(true)
    }

    /// The role and the presence, both from the catalogue.
    ///
    /// `isSystemAdmin` is read rather than assumed: the type stores it so a future tutor-moderator
    /// is expressible without pretending they are an admin.
    private var subtitle: String {
        let role = moderator.isSystemAdmin
            ? L10n.sessionRoleAdmin.string
            : L10n.sessionRoleTutor.string
        return "\(role) · \(L10n.adminStatusActive.string)"
    }
}

// MARK: - Previews

#Preview("N01 Moderator banner") {
    VStack(spacing: 0) {
        ModeratorPresenceBanner(
            moderator: GroupModerator(id: "admin-1", displayName: "Fatema Ghareeb")
        )
        Spacer(minLength: 0)
    }
    .background(ColorTokens.surface)
}
