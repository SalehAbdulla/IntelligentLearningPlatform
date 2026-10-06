//
//  SFPasswordField.swift
//  StudyForge
//
//  A labelled secure field with a reveal toggle.
//
//  THE FOCUS QUIRK, AND WHY IT IS HANDLED HERE
//  -------------------------------------------
//  SwiftUI cannot toggle secure entry on one control: you must swap `SecureField` for
//  `TextField`. Swapping replaces the underlying UIKit view, which drops first-responder
//  status — so naively toggling visibility dismisses the keyboard mid-typing and loses
//  the caret. The toggle therefore re-asserts focus, which is the difference between a
//  usable reveal button and an infuriating one.
//
//  The reveal control is also a full 44 pt target, not a bare eye glyph, and it
//  announces its own state ("Show password" / "Hide password") rather than just "eye".
//

import SwiftUI

struct SFPasswordField: View {

    let label: String
    @Binding var text: String

    var placeholder: String = ""
    var hint: String?
    var error: String?

    /// `.newPassword` on sign-up so iOS offers a strong password; `.password` on log-in
    /// so it offers the saved one. Getting this backwards makes the Keychain prompt
    /// offer the wrong action.
    var contentType: UITextContentType? = .password

    var submitLabel: SubmitLabel = .go
    var onSubmit: () -> Void = {}

    @State private var isRevealed = false
    @FocusState private var isFocused: Bool

    private var hasError: Bool { error != nil }

    private var accessibilityDescription: String {
        var parts = [label]
        if hasError, let error { parts.append(error) }
        else if let hint { parts.append(hint) }
        return parts.joined(separator: ". ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {

            Text(label)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)

            HStack(spacing: Spacing.s2) {
                Group {
                    if isRevealed {
                        TextField(placeholder, text: $text)
                    } else {
                        SecureField(placeholder, text: $text)
                    }
                }
                .font(.sfBody)
                .foregroundStyle(ColorTokens.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(contentType)
                .submitLabel(submitLabel)
                .focused($isFocused)
                .onSubmit(onSubmit)
                .accessibilityLabel(accessibilityDescription)

                Button {
                    let hadFocus = isFocused
                    isRevealed.toggle()
                    // The control was just replaced; put the caret back. Deferred by one
                    // turn of the run loop so SwiftUI has installed the new field first.
                    if hadFocus {
                        Task { @MainActor in isFocused = true }
                    }
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                        .font(.sfBody)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .frame(width: Layout.minTouchTarget, height: Layout.minTouchTarget)
                        .contentShape(.rect)
                }
                .accessibilityLabel(isRevealed ? L10n.commonHidePassword.string : L10n.commonShowPassword.string)
                .accessibilityAddTraits(.isButton)
            }
            .sfFieldBackground(hasError: hasError)

            if hasError, let error {
                Label {
                    Text(error).font(.sfFootnote)
                } icon: {
                    Image(systemName: "exclamationmark.circle.fill")
                }
                .foregroundStyle(ColorTokens.error)
                .accessibilityHidden(true)
            } else if let hint {
                Text(hint)
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .accessibilityHidden(true)
            }
        }
    }
}

// MARK: - Previews

#Preview("SFPasswordField states") {
    @Previewable @State var empty = ""
    @Previewable @State var weak = "abc"

    return ScrollView {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            SFPasswordField(label: "Password", text: $empty, placeholder: "••••••••")

            SFPasswordField(
                label: "Password",
                text: $weak,
                placeholder: "••••••••",
                error: "Use at least 8 characters so your account stays secure."
            )
        }
        .padding(Layout.screenMargin)
    }
}
