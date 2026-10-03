//
//  SFSegmentedField.swift
//  StudyForge
//
//  A labelled segmented control — "Segmented control" in docs/06 §5's action inventory,
//  used first by B01's year-of-study choice and again by B11's EN/AR language switch.
//
//  WHY A NATIVE `Picker` AND NOT A ROW OF CHIPS
//  -------------------------------------------
//  A segmented control and a row of chips look similar and mean different things: a
//  segment picks exactly one, permanently — there is no empty state to return to. The
//  native control brings the correct traits, the keyboard/menu behaviour and the RTL
//  mirroring with it, so this type exists to add the label, the chrome and the error line
//  rather than to reimplement the control.
//
//  WHY THE SELECTION IS OPTIONAL
//  ----------------------------
//  Because "nothing chosen yet" has to be distinguishable from a choice the student made.
//  Defaulting to the first option would make the form look complete when it is not, and
//  the value that gets saved would be one nobody picked. `nil` renders with no segment
//  selected, which is what the empty state honestly looks like.
//
//  The caller supplies the segment titles, so a numeral range stays compact: "Year of
//  study" with segments 1–4 is announced as "Year of study, 3" and survives AX5, where
//  four spelled-out labels would truncate.
//

import SwiftUI

struct SFSegmentedField<Value: Hashable>: View {

    let label: String

    @Binding var selection: Value?

    /// Options in display order.
    let options: [Value]

    /// Segment title for an option.
    let title: (Value) -> String

    /// Validation message. Non-nil puts the control in an error state.
    var error: String?

    /// Spoken description. The error is carried here rather than on a separate element,
    /// for the same reason `SFTextField` does it: one focus stop, with the message last
    /// where it is most salient.
    private var accessibilityLabel: String {
        guard let error else { return label }
        return "\(label). \(error)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {

            // Hidden from VoiceOver on purpose: the same string is the Picker's label
            // below, so the control is announced once as "Year of study, 3" instead of
            // the caption being read out and then the control reading itself.
            Text(label)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)
                .accessibilityHidden(true)

            Picker(accessibilityLabel, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(title(option)).tag(Optional(option))
                }
            }
            .pickerStyle(.segmented)
            .padding(.vertical, Spacing.s2)

            SFFieldFeedback(error: error, hint: nil)
        }
    }
}

// MARK: - Previews

#Preview("SFSegmentedField states") {
    @Previewable @State var year: Int? = nil
    @Previewable @State var chosen: Int? = 3

    return ScrollView {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            SFSegmentedField(
                label: "Year of study",
                selection: $year,
                options: [1, 2, 3, 4],
                title: { String($0) }
            )

            SFSegmentedField(
                label: "Year of study",
                selection: $chosen,
                options: [1, 2, 3, 4],
                title: { String($0) }
            )

            SFSegmentedField(
                label: "Year of study",
                selection: $year,
                options: [1, 2, 3, 4],
                title: { String($0) },
                error: "Choose your year."
            )
        }
        .padding(Layout.screenMargin)
    }
}
