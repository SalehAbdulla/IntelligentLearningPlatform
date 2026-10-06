//
//  SFMonogram.swift
//  StudyForge
//
//  A person's initials in a circle — the stand-in for an avatar.
//
//  WHY A STAND-IN RATHER THAN A PHOTO
//  ---------------------------------
//  `avatarUrl` is in the write allowlist, but there is nowhere to PUT a photo: Cloud Storage
//  needs the Blaze plan and is deliberately bypassed (D24, docs/09 R21). So both screens that
//  draw an avatar — B06's profile view and B07's editor — draw initials, and the editor says so
//  on screen.
//
//  WHY THE RULE LIVES IN THE COMPONENT
//  ----------------------------------
//  The initials rule is presentation, and it was about to be written once per screen. Keeping
//  it here, beside the circle it draws, means the two screens cannot disagree about what a
//  name looks like as a monogram. `initials(from:)` is a separate static so the rule is
//  testable without building a view.
//

import SwiftUI

struct SFMonogram: View {

    let name: String

    var body: some View {
        Text(Self.initials(from: name))
            .font(.sfTitleM)
            .foregroundStyle(ColorTokens.onPrimaryContainer)
            // Sized by its own padding rather than a fixed frame, so it grows with Dynamic Type
            // instead of clipping the letters at AX5.
            .padding(Spacing.s4)
            .background(ColorTokens.primaryContainer, in: .circle)
            // Decorative: the person's name is written beside it, so announcing the initials
            // would read that name twice.
            .accessibilityHidden(true)
    }

    /// Up to two initials — the first letter of each of the first two name parts.
    ///
    /// "Up to two", not "always two": a single-word name gives one letter. A space and a hyphen
    /// both separate parts, because a hyphenated given name is still one name. `?` when there
    /// is nothing to take a letter from, so an unnamed account shows something deliberate rather
    /// than an empty circle.
    ///
    /// - Note: `nonisolated` is load-bearing, not a style choice. `View` is main-actor isolated,
    ///   so a method declared here would INHERIT that isolation and its closures with it — and
    ///   calling it from a non-isolated context (a unit test, a background task) then trips
    ///   `dispatch_assert_queue` and takes the process down with a `SIGTRAP` rather than an
    ///   error. This is a pure string transform that touches no UI state, so it belongs off the
    ///   main actor.
    nonisolated static func initials(from name: String) -> String {
        let letters = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: { $0 == " " || $0 == "-" })
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
        return letters.isEmpty ? "?" : letters.joined().uppercased()
    }
}

// MARK: - Previews

#Preview("SFMonogram") {
    HStack(spacing: Spacing.s4) {
        SFMonogram(name: "Sara Ali")
        SFMonogram(name: "Madonna")
        SFMonogram(name: "   ")
    }
    .padding(Layout.screenMargin)
}
