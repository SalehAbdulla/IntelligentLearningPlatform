//
//  SFFieldStyle.swift
//  StudyForge
//
//  The shared chrome for form fields.
//
//  WHY THIS EXISTS AS ITS OWN FILE
//  ------------------------------
//  `SFTextField` and `SFPasswordField` must look identical — same height, radius,
//  border weight, error colour. Duplicating that styling in two files guarantees they
//  eventually diverge, and "the password field looks slightly different" is exactly the
//  kind of drift nobody notices until a marker does. One modifier, both fields.
//

import SwiftUI

/// Background, padding, and the error-aware border for a form field.
///
/// Applied to the field itself (or to the row containing a field and its trailing
/// button) so the tappable area and the visible box stay the same rectangle.
struct SFFieldBackground: ViewModifier {

    /// Drives both the border colour and its weight.
    ///
    /// The weight change matters as much as the colour: relying on red alone fails
    /// WCAG 1.4.1 for colour-vision-deficient users, so a heavier border is a second,
    /// non-colour signal.
    let hasError: Bool

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, Spacing.s4)
            .padding(.vertical, Spacing.s3)
            .frame(minHeight: Layout.minTouchTarget)
            .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.m)
                    .strokeBorder(
                        hasError ? ColorTokens.error : ColorTokens.outline,
                        lineWidth: hasError ? 1.5 : 1
                    )
            }
    }
}

extension View {
    /// Applies the standard form-field chrome.
    func sfFieldBackground(hasError: Bool) -> some View {
        modifier(SFFieldBackground(hasError: hasError))
    }
}

/// The feedback line that sits under a form field.
///
/// Extracted into this file for the same reason `SFFieldBackground` is here: B01 adds a
/// quoted picker and a segmented control, and three controls that each invent their own
/// error line is exactly the drift this file exists to prevent. Exactly one of error /
/// hint is ever shown, so a field cannot contradict itself.
struct SFFieldFeedback: View {

    /// Validation message. Non-nil means the control is in an error state.
    let error: String?

    /// Guidance shown when there is no error.
    let hint: String?

    var body: some View {
        if let error {
            Label {
                Text(error).font(.sfFootnote)
            } icon: {
                Image(systemName: "exclamationmark.circle.fill")
            }
            .foregroundStyle(ColorTokens.error)
            // Colour is not the only signal — the icon and the text carry the meaning,
            // which matters at WCAG 1.4.1 for anyone with a colour-vision deficiency.
            //
            // Hidden from VoiceOver because the message is already spoken as part of the
            // control's own accessibility label; announcing it twice is noise.
            .accessibilityHidden(true)
        } else if let hint {
            Text(hint)
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textSecondary)
                .accessibilityHidden(true)
        }
    }
}

