//
//  SFButtonStyles.swift
//  StudyForge
//
//  Rule F — ONE set of button styles, so every button of the same kind shares height, radius,
//  typography, pressed feedback and disabled treatment, and no screen re-derives them.
//
//  WHY STYLES AS WELL AS `SFPrimaryButton`
//  --------------------------------------
//  `SFPrimaryButton` is a `View`, which is what an asynchronous call-to-action needs (it hosts
//  the spinner and blocks double submission). A `View` cannot be applied to a `NavigationLink`,
//  a `Menu` or a `swipeActions` button — those take a `ButtonStyle`. Both paths now read their
//  geometry from `SFButtonMetrics`, so a primary button is 50 pt tall whichever one you use.
//
//  WHY 50 pt AND NOT 44 pt
//  -----------------------
//  Rule F sets the primary minimum at 50 pt. `Layout.minTouchTarget` (44) remains the rule for
//  *hit areas* — icons, chips, toolbar items. The Figma `Button/Primary` symbol draws 48 pt, so
//  the code is deliberately 2 pt taller than the drawing; the requirement governs. Reported
//  rather than silently reconciled.
//
//  CENTERING
//  ---------
//  Every full-width style centres by `frame(maxWidth: .infinity)` on the *label*, then applies
//  `.multilineTextAlignment(.center)` and a vertical `minHeight`. Nothing pads one side only, so
//  a wrapped Arabic label and a short English one share the same optical centre.
//

import SwiftUI

/// Shared geometry for every button style. One declaration, four styles.
enum SFButtonMetrics {

    /// Rule F: the primary call to action is never shorter than this.
    static let minHeight: CGFloat = 50

    /// Compact buttons keep the 44 pt hit target but not the visual weight of a primary.
    static let compactMinHeight: CGFloat = Layout.minTouchTarget

    /// Horizontal breathing room inside a full-width button, from the spacing ladder.
    static let horizontalPadding: CGFloat = Spacing.s4
}

// MARK: - Primary

/// The main call to action. Blue fill, `onError` label.
///
/// `isLoading` keeps the label in the layout at zero opacity so the button does not change
/// height mid-request, and replaces it with a spinner.
struct SFPrimaryButtonStyle: ButtonStyle {

    var isLoading: Bool = false

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.sfBodyEmph)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(ColorTokens.onError)
            .opacity(isLoading ? 0 : 1)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, SFButtonMetrics.horizontalPadding)
            .frame(minHeight: SFButtonMetrics.minHeight)
            .background(
                RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                    .fill(fill)
            )
            .overlay {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(ColorTokens.onError)
                }
            }
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(
                Motion.respecting(Motion.instant, reduceMotion: reduceMotion),
                value: configuration.isPressed
            )
            .contentShape(RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
    }

    /// Loading dims the fill rather than removing it, so the control does not flash back to the
    /// background colour between the tap and the spinner.
    private var fill: Color {
        if isLoading { return ColorTokens.primaryFill.opacity(0.70) }
        return isEnabled ? ColorTokens.primaryFill : ColorTokens.primaryFill.opacity(0.40)
    }
}

// MARK: - Secondary

/// The supporting action: outlined by default, or a filled "elevated" variant.
struct SFSecondaryButtonStyle: ButtonStyle {

    /// Draws a hairline border instead of a filled surface.
    var outlined: Bool = true

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.sfSubhead)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(isEnabled ? ColorTokens.primary : ColorTokens.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, SFButtonMetrics.horizontalPadding)
            .frame(minHeight: SFButtonMetrics.minHeight)
            .background {
                if outlined {
                    RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                        .strokeBorder(ColorTokens.outline, lineWidth: 1)
                } else {
                    RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                        .fill(ColorTokens.surfaceElevated)
                }
            }
            .opacity(configuration.isPressed ? 0.60 : 1)
            .contentShape(RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
    }
}

// MARK: - Tertiary

/// An inline, chromeless action — "Forgot password?", a section header's trailing "See all".
/// Sized to the 44 pt hit target, not the 50 pt primary height, because it is not a CTA.
struct SFTertiaryButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.sfSubhead)
            .foregroundStyle(isEnabled ? ColorTokens.primary : ColorTokens.textTertiary)
            .frame(minHeight: SFButtonMetrics.compactMinHeight)
            .padding(.horizontal, Spacing.s2)
            .opacity(configuration.isPressed ? 0.55 : 1)
            .contentShape(Rectangle())
    }
}

// MARK: - Destructive

/// Delete, sign out, cancel subscription. Always paired with a confirmation at the call site —
/// a style cannot enforce that, so `DiscardGuard` and the per-screen `confirmationDialog`s do.
struct SFDestructiveButtonStyle: ButtonStyle {

    /// A filled red button for the destructive action on a screen. The buttons *inside* a
    /// confirmation dialog are tinted by `role: .destructive` and must not use this style.
    var filled: Bool = false

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let tint = isEnabled ? ColorTokens.error : ColorTokens.error.opacity(0.40)

        return configuration.label
            .font(.sfBodyEmph)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(filled ? ColorTokens.onDanger : tint)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, SFButtonMetrics.horizontalPadding)
            .frame(minHeight: SFButtonMetrics.minHeight)
            .background {
                RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                    .fill(filled ? tint : Color.clear)
            }
            .overlay {
                if !filled {
                    RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                        .strokeBorder(tint.opacity(0.55), lineWidth: 1)
                }
            }
            .opacity(configuration.isPressed ? 0.85 : 1)
            .contentShape(RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
    }
}

// MARK: - Previews

private struct SFButtonStylesGallery: View {
    var body: some View {
        VStack(spacing: Spacing.s4) {
            Button("Start studying") {}
                .buttonStyle(SFPrimaryButtonStyle())

            Button("Start studying", action: {})
                .buttonStyle(SFPrimaryButtonStyle(isLoading: true))

            Button("Start studying") {}
                .buttonStyle(SFPrimaryButtonStyle())
                .disabled(true)

            Button("Choose another material") {}
                .buttonStyle(SFSecondaryButtonStyle())

            Button("Choose another material") {}
                .buttonStyle(SFSecondaryButtonStyle(outlined: false))

            Button("Forgot password?") {}
                .buttonStyle(SFTertiaryButtonStyle())

            Button("Delete deck") {}
                .buttonStyle(SFDestructiveButtonStyle(filled: true))
        }
        .padding(Layout.screenMargin)
        .background(ColorTokens.surface)
    }
}

#Preview("Button styles — light") {
    SFButtonStylesGallery()
}

#Preview("Button styles — dark (default)") {
    SFButtonStylesGallery().preferredColorScheme(.dark)
}

#Preview("Button styles — AX5") {
    SFButtonStylesGallery().environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("Button styles — Arabic RTL") {
    SFButtonStylesGallery().environment(\.layoutDirection, .rightToLeft)
}
