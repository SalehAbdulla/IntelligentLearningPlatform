//
//  HiddenMessageTombstone.swift
//  StudyForge
//
//  F16 — N03, `144_GroupChat_Hidden_Message_Placeholder_{M5}` (docs/03 §N).
//
//  WHY A TOMBSTONE AND NOT AN EMPTY ROW
//  ------------------------------------
//  A hidden message that simply disappears is read as a glitch: the conversation jumps, and the
//  next person to arrive has no idea a moderator intervened. The tombstone states that the body
//  was removed, WHY, and by whom, so the room never silently loses its history and the decision is
//  accountable. That is the reason `ChatModerationState.visibleBody(of:)` returns `nil` instead of
//  a placeholder string: the decision about what to show belongs to the screen, and the tombstone
//  is what it shows.
//
//  WHY THE REASON IS REQUIRED AND THE ATTRIBUTION IS OPTIONAL
//  ---------------------------------------------------------
//  The reason is always in the log — `ChatModerationState.apply` refuses a hide without one — so
//  the tombstone takes it non-optionally. Who and when are read from the action that hid it; if a
//  log written by another client has not arrived yet, the tombstone still says what it can rather
//  than inventing a name.
//

import SwiftUI

struct HiddenMessageTombstone: View {

    /// Why the message was removed. Required, because a hide cannot be recorded without one.
    let reason: ModerationReason

    /// Who removed it, when the log carries the action. Data, not prose.
    var moderatorName: String?

    /// When it was removed, when the log carries the action.
    var at: Date?

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.s3) {
            Image(systemName: "eye.slash")
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.s1) {
                // "Removed" is the catalogue's own word for moderated content
                // (`admin.reportStatus.removed`). N03's full sentence, "Removed by a moderator",
                // needs a `group.moderation.*` key — see `ModerationCopy.swift`.
                Text(L10n.adminReportStatusRemoved.string)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textSecondary)

                Text("\(L10n.adminModerationReasonLabel.string) · \(reason.title)")
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let attribution {
                    Text(attribution)
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.textTertiary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
        // Dashed rather than solid: the row is a place-holder for something that was here, and the
        // outline says so without relying on colour to carry the meaning.
        .overlay {
            RoundedRectangle(cornerRadius: Radius.m)
                .strokeBorder(
                    ColorTokens.outline,
                    style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                )
        }
        // One element, so VoiceOver reads "Removed. Reason · Spam. Fatema, 14 Nov" as a statement
        // rather than four fragments.
        .accessibilityElement(children: .combine)
    }

    /// "Name · 14 Nov 2026 at 10:32", or whichever half the log has.
    private var attribution: String? {
        let name = moderatorName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let author = (name?.isEmpty == false) ? name : nil
        let stamp = at?.formatted(date: .abbreviated, time: .shortened)

        // A plain switch with explicit returns: this body has statements before it, and
        // `return switch` relies on a newer language mode than the rest of the file needs.
        switch (author, stamp) {
        case let (author?, stamp?): return "\(author) · \(stamp)"
        case let (author?, nil): return author
        case let (nil, stamp?): return stamp
        case (nil, nil): return nil
        }
    }
}

// MARK: - Previews

#Preview("N03 Tombstone") {
    VStack(alignment: .leading, spacing: Spacing.s4) {
        HiddenMessageTombstone(
            reason: .spam,
            moderatorName: "Fatema Ghareeb",
            at: .now
        )
        HiddenMessageTombstone(reason: .offTopic)
    }
    .padding(Layout.screenMargin)
    .background(ColorTokens.surface)
}
