//
//  ModerationSheet.swift
//  StudyForge
//
//  F16 — N02, `143_GroupChat_Message_Moderation_Menu_{M5}`, plus the reason capture that every
//  recorded action needs (docs/03 §N).
//
//  WHY THE MENU AND THE REASON ARE ONE SHEET
//  -----------------------------------------
//  N02 and N03 are two steps of one decision: choose what to do, then say why. Two separate
//  sheets would dismiss one to present the other — a flicker the learner reads as a failure — and
//  would make "go back and pick a different action" impossible without starting again. One sheet
//  with a second step keeps the message under review on screen throughout.
//
//  WHY THE CONSEQUENCE SITS UNDER EACH ROW
//  --------------------------------------
//  Hiding a message is not a preference: it changes what everyone else sees, and it is recorded.
//  A row that names only the verb asks the moderator to infer the effect; a row that states it
//  makes the choice informed. The consequences are existing catalogue strings — see
//  `ModerationCopy.swift` for which ones and why.
//
//  WHY SUBMIT IS DISABLED RATHER THAN REFUSED
//  ------------------------------------------
//  `ModerationPolicy.requiresNote` refuses `other` with no note, and `ChatModerationState.apply`
//  throws in that case. Disabling the button says the same thing before the tap, so the rule is a
//  visible requirement rather than a surprise. The store's refusal remains the authority; this is
//  the same rule surfaced earlier.
//
//  WHY THE SHEET DOES NOT READ `message.text`
//  ------------------------------------------
//  A hidden message must not be re-rendered by any screen — `GroupChatViewModel.visibleBody(of:)`
//  is the only sanctioned read, and it returns `nil` for a tombstone. The quoted line is therefore
//  passed in already resolved, so this sheet cannot accidentally show a body the room removed.
//

import SwiftUI

struct ModerationSheet: View {

    /// The message being acted on. Read for its sender and time; never for its body.
    let message: GroupMessage

    /// The body a member sees, or `nil` when the message is already hidden.
    let quotedText: String?

    /// A store failure from the last attempt, so a retry happens against honest information.
    let error: AppError?

    /// Applies the chosen action. Returns whether it landed, so the sheet closes only on success:
    /// a sheet that vanished after a failed write would claim a moderation that never happened.
    let onApply: @MainActor (ModerationActionKind, ModerationReason, String?) async -> Bool

    @Environment(\.dismiss) private var dismiss

    /// `nil` until an action is chosen — step one is the action list, step two the reason.
    @State private var chosen: ModerationActionKind?

    @State private var reason: ModerationReason = .spam
    @State private var note = ""
    @State private var isSubmitting = false

    private var trimmedNote: String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// `other` with no note explains nothing, which is exactly the case `ModerationPolicy` refuses.
    private var noteRequired: Bool { ModerationPolicy.requiresNote(reason: reason) }

    private var canSubmit: Bool {
        !isSubmitting && (!noteRequired || !trimmedNote.isEmpty)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s4) {
                    if let error {
                        SFErrorBanner(error: error)
                    }

                    quotedMessage

                    if let chosen {
                        reasonStep(for: chosen)
                    } else {
                        actionStep
                    }
                }
                .padding(Layout.screenMargin)
                .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(ColorTokens.surface)
            .navigationTitle(chosen?.title ?? L10n.adminAuditLogActions.string)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if chosen == nil {
                        Button(L10n.commonClose.string) { dismiss() }
                    } else {
                        // Back, not Close: the message is still the thing being moderated and the
                        // moderator may have picked the wrong verb.
                        Button(L10n.commonBack.string) { chosen = nil }
                    }
                }
            }
        }
    }


    // MARK: The message under review

    private var quotedMessage: some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text(message.senderName)
                .font(.sfCaption)
                .foregroundStyle(ColorTokens.textSecondary)

            if let quotedText {
                Text(quotedText)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(L10n.adminReportStatusRemoved.string)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
        }
        .padding(Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            quotedText.map { "\(message.senderName). \($0)" }
                ?? "\(message.senderName). \(L10n.adminReportStatusRemoved.string)"
        )
    }

    // MARK: Step one — the action

    private var actionStep: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            ForEach(ModerationActionKind.allCases) { kind in
                actionRow(kind)
            }
        }
    }

    private func actionRow(_ kind: ModerationActionKind) -> some View {
        // Deleting is the irreversible choice, so it is drawn in the error colour — and the row
        // still names itself in words, because colour alone must not carry meaning.
        let isDestructive = kind == .delete

        return Button {
            chosen = kind
        } label: {
            HStack(alignment: .top, spacing: Spacing.s3) {
                Image(systemName: kind.symbolName)
                    .font(.sfCallout)
                    .foregroundStyle(isDestructive ? ColorTokens.error : ColorTokens.primary)
                    .frame(minWidth: Spacing.s6, alignment: .leading)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Text(kind.title)
                        .font(.sfBodyEmph)
                        .foregroundStyle(isDestructive ? ColorTokens.error : ColorTokens.textPrimary)

                    if let consequence = kind.consequence {
                        Text(consequence)
                            .font(.sfCaption)
                            .foregroundStyle(ColorTokens.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: Spacing.s2)

                Image(systemName: "chevron.right")
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textTertiary)
                    .accessibilityHidden(true)
            }
            .padding(Spacing.s3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .frame(minHeight: Layout.minTouchTarget)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: Step two — the reason

    private func reasonStep(for kind: ModerationActionKind) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {

            // The chosen action, repeated so the moderator can see what the reason is about
            // without leaving the step.
            HStack(spacing: Spacing.s2) {
                Image(systemName: kind.symbolName)
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.primary)
                    .accessibilityHidden(true)
                Text(kind.title)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textPrimary)
            }
            .accessibilityElement(children: .combine)

            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(L10n.adminModerationReasonLabel.string)
                    .font(.sfSubhead)
                    .foregroundStyle(ColorTokens.textSecondary)

                ForEach(ModerationReason.allCases) { option in
                    reasonRow(option)
                }
            }

            SFTextField(
                label: L10n.adminModerationReasonLabel.string,
                text: $note,
                placeholder: L10n.adminModerationReasonPlaceholder.string,
                error: noteRequired && trimmedNote.isEmpty
                    ? L10n.adminModerationReasonRequired.string
                    : nil,
                autocapitalization: .sentences,
                autocorrectionDisabled: false
            )

            SFPrimaryButton(
                title: kind.title,
                isLoading: isSubmitting,
                isEnabled: canSubmit
            ) {
                Task { await submit(kind) }
            }
        }
    }

    private func reasonRow(_ option: ModerationReason) -> some View {
        let isSelected = reason == option

        return Button {
            reason = option
        } label: {
            HStack(spacing: Spacing.s3) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? ColorTokens.primary : ColorTokens.textTertiary)
                    .accessibilityHidden(true)

                Text(option.title)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textPrimary)

                Spacer(minLength: 0)
            }
            .frame(minHeight: Layout.minTouchTarget)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        // The tick is decorative; the selected trait is what a screen reader reports.
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: Submitting

    private func submit(_ kind: ModerationActionKind) async {
        guard canSubmit else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        let note = trimmedNote.isEmpty ? nil : trimmedNote
        if await onApply(kind, reason, note) {
            dismiss()
        }
    }
}



// MARK: - Previews

#Preview("N02 Moderation sheet") {
    ModerationSheet(
        message: GroupMessage(
            id: "m1",
            senderName: "Omar",
            text: "Anyone free at 6 for normalisation?"
        ),
        quotedText: "Anyone free at 6 for normalisation?",
        error: nil,
        onApply: { _, _, _ in true }
    )
}
