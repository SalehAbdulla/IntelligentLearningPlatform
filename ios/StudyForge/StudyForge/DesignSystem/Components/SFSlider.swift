//
//  SFSlider.swift
//  StudyForge
//
//  A labelled slider with a visible value — "Slider" in docs/06 §5's input inventory, used
//  first by B03's weekly study time and again by F06's plan controls.
//
//  WHY THE VALUE IS ON SCREEN
//  -------------------------
//  A slider with no readout is a control that cannot be answered: the student can move it
//  but not see what they are agreeing to, and the value that gets saved is one they never
//  read. So the readout is part of the component rather than something a caller may forget,
//  and it carries `.monospacedDigit()` so a changing number does not make the label jump
//  sideways as the width changes.
//
//  WHY THE VALUE IS AN `Int`
//  ------------------------
//  Hours are whole numbers, and SwiftUI's `Slider` is generic over a floating-point value.
//  Bridging once here keeps `Double` out of the model and out of the write: a stored
//  `11.999999` hours would be a rounding artefact of the control, not an answer.
//
//  The caller supplies the already-formatted readout, because plural forms are a language
//  question (see `WeekHoursReadout`) and this type should not know that Arabic counts to
//  two differently from English.
//

import SwiftUI

struct SFSlider: View {

    let label: String

    @Binding var value: Int

    /// The inclusive bounds the student may choose. Typed, so a caller cannot pass a range
    /// the model would reject.
    let range: ClosedRange<Int>

    /// The formatted current value, e.g. "12 hours a week".
    let readout: String

    /// How far one drag moves the value. Hours step by one.
    var step: Int = 1

    /// `Slider` needs a floating-point binding; this is the single place the two meet.
    private var sliderValue: Binding<Double> {
        Binding(
            get: { Double(value) },
            set: { value = Int($0.rounded()) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {

            HStack(alignment: .firstTextBaseline, spacing: Spacing.s2) {
                // Hidden from VoiceOver: the same string is the slider's own label below,
                // so the control is announced once as "Weekly study time, 12 hours a week"
                // rather than the caption being read out and then the control repeating it.
                Text(label)
                    .font(.sfSubhead)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .accessibilityHidden(true)

                Spacer(minLength: Spacing.s2)

                // Also hidden: it is the slider's `.accessibilityValue`. Announcing it twice
                // is the same mistake in both directions.
                Text(readout)
                    .font(.sfBodyEmph)
                    .monospacedDigit()
                    .foregroundStyle(ColorTokens.textPrimary)
                    .accessibilityHidden(true)
            }

            Slider(
                value: sliderValue,
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: Double(step)
            )
            .tint(ColorTokens.primary)
            .accessibilityLabel(label)
            .accessibilityValue(readout)
        }
    }
}

// MARK: - Previews

#Preview("SFSlider states") {
    @Previewable @State var low = 1
    @Previewable @State var typical = 12
    @Previewable @State var high = 40

    return ScrollView {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            SFSlider(label: "Weekly study time", value: $low, range: 1...40, readout: "1 hour a week")
            SFSlider(label: "Weekly study time", value: $typical, range: 1...40, readout: "12 hours a week")
            // The top of the range, to show the readout past two digits does not shift the label.
            SFSlider(label: "Weekly study time", value: $high, range: 1...40, readout: "40 hours a week")
        }
        .padding(Layout.screenMargin)
    }
}
