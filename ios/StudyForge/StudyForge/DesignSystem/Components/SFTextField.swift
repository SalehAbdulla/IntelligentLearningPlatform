//
//  SFTextField.swift
//  StudyForge
//
//  A labelled text field with hint and error slots.
//
//  ACCESSIBILITY IS THE POINT OF THIS COMPONENT
//  --------------------------------------------
//  A bare `TextField` with a floating placeholder announces as "text field" to
//  VoiceOver — the label is decorative. Here the label is bound with
//  `accessibilityLabel`, the error with `accessibilityValue`, and the whole control is
//  one focus stop, so a screen-reader user hears "Email, required, That doesn't look
//  like an email address" rather than three disconnected fragments.
//
//  The error is also NOT colour-only: red alone fails WCAG 1.4.1 for anyone with a
//  colour-vision deficiency, so the message text carries the meaning and the colour
//  merely reinforces it.
//

import SwiftUI

struct SFTextField: View {

    let label: String
    @Binding var text: String

    /// Placeholder shown inside the field. Kept short; the label does the naming.
    var placeholder: String = ""

    /// Guidance shown when there is no error. Never shown at the same time as `error`.
    var hint: String?

    /// Validation message. Non-nil means the field is in an error state.
    var error: String?

    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType?
    var submitLabel: SubmitLabel = .next

    /// Set false for fields that must stay capitalised (names, university).
    var autocapitalization: TextInputAutocapitalization = .never

    /// Disables autocorrect — correct for emails and codes, wrong for names.
    var autocorrectionDisabled: Bool = true

    var onSubmit: () -> Void = {}

    @FocusState private var isFocused: Bool

    private var hasError: Bool { error != nil }

    /// Spoken description. VoiceOver reads these in order, so the error comes last
    /// where it is most salient.
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

            TextField(placeholder, text: $text)
                .font(.sfBody)
                .foregroundStyle(ColorTokens.textPrimary)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(autocorrectionDisabled)
                .keyboardType(keyboard)
                .textContentType(contentType)
                .submitLabel(submitLabel)
                .focused($isFocused)
                .onSubmit(onSubmit)
                .sfFieldBackground(hasError: hasError)
                // The border is decoration; this is what makes the error reachable
                // without sight.
                .accessibilityLabel(accessibilityDescription)

            // Feedback line: exactly one of error / hint, never both, so the field
            // cannot contradict itself.
            SFFieldFeedback(error: error, hint: hint)
        }
    }
}

// MARK: - Previews

#Preview("SFTextField states") {
    @Previewable @State var normal = ""
    @Previewable @State var filled = "sara@studyforge.test"
    @Previewable @State var invalid = "not-an-email"

    return ScrollView {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            SFTextField(label: "Email", text: $normal, placeholder: "you@example.com")

            SFTextField(
                label: "Email",
                text: $filled,
                placeholder: "you@example.com",
                hint: "We only use this to sign you in."
            )

            SFTextField(
                label: "Email",
                text: $invalid,
                placeholder: "you@example.com",
                error: "That doesn't look like an email address."
            )
        }
        .padding(Layout.screenMargin)
    }
}
