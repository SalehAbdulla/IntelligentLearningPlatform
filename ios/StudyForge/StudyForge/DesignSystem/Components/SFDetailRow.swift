//
//  SFDetailRow.swift
//  StudyForge
//
//  One label/value line in a read-only summary — "University … Bahrain Polytechnic".
//
//  WHY THE MODEL LIVES WITH THE VIEW
//  --------------------------------
//  `DetailRow` exists only to feed this view: a screen's view model produces them and the view
//  draws them. Keeping the pair in one file stops a screen inventing its own row shape and
//  drifting from the others — which is exactly what happened when B04 and B06 each grew a
//  private `Row` struct that was meant to be the same thing.
//
//  WHY NOT A PLAIN `HStack` AT THE CALL SITE
//  ----------------------------------------
//  Accessibility is the reason this is a component. A bare label-then-value `HStack` is read
//  by VoiceOver as two unrelated fragments ("University", then "Bahrain Polytechnic") with no
//  indication they belong together; combining them into one element makes the line a
//  statement.
//

import SwiftUI

/// One summary line: what the line is about, and what it says.
struct DetailRow: Identifiable, Equatable, Sendable {

    /// Stable identity derived from the FIELD rather than the position, so a list does not
    /// re-animate when an unrelated row appears or disappears.
    let id: String

    let label: String
    let value: String
}

/// Draws a `DetailRow`.
struct SFDetailRow: View {

    let row: DetailRow

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(row.label)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)

            Spacer(minLength: Spacing.s3)

            Text(row.value)
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(row.label)
        .accessibilityValue(row.value)
    }
}

// MARK: - Previews

#Preview("SFDetailRow") {
    VStack(alignment: .leading, spacing: Spacing.s3) {
        SFDetailRow(row: DetailRow(
            id: "university",
            label: "University",
            value: "Bahrain Polytechnic"
        ))
        // A long value, to show it wraps rather than truncating a course list at AX5.
        SFDetailRow(row: DetailRow(
            id: "courses",
            label: "Enrolled courses",
            value: "IT8108, Introduction to Programming, Data Structures, Databases"
        ))
    }
    .padding(Layout.screenMargin)
}
