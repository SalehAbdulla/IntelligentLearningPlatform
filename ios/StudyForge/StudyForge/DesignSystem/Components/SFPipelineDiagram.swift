//
//  SFPipelineDiagram.swift
//  StudyForge
//
//  The four-step pipeline on A03 (`03_Onboarding_HowItWorks_{M1}`).
//
//  WHY A VERTICAL TIMELINE
//  -----------------------
//  The Figma frame draws the steps as a horizontal row of four numbered nodes. That works
//  at 390 pt in English and breaks twice over in the two cases this app has to survive:
//  Arabic (RTL) and large Dynamic Type. A vertical timeline with a connector rail is the
//  standard adaptive answer — it reads correctly mirrored, and it simply grows taller
//  instead of truncating.
//
//  Each step is one accessibility element reading "Step 2 of 4. Generate. Summaries,
//  flashcards and quizzes." rather than four loose labels, so the ORDER survives being
//  read aloud.
//

import SwiftUI

struct SFPipelineDiagram: View {

    let steps: [PipelineStep]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { offset, step in
                HStack(alignment: .top, spacing: Spacing.s3) {
                    rail(for: step, isLast: offset == steps.count - 1)
                    details(for: step)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    "\(L10n.onboardingStepIndicator.string(step.number, steps.count)). "
                    + "\(step.title). \(step.body)"
                )
            }
        }
    }

    // MARK: Node and connector

    private func rail(for step: PipelineStep, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(ColorTokens.primaryContainer)
                    .frame(width: 36, height: 36)

                Image(systemName: step.symbolName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(ColorTokens.onPrimaryContainer)
            }

            // The rail is what makes the sequence read as a pipeline rather than a list.
            // Omitted after the last node so the line does not dangle.
            if !isLast {
                Rectangle()
                    .fill(ColorTokens.outline)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 36)
    }

    private func details(for step: PipelineStep) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text(step.title)
                .font(.sfTitleS)
                .foregroundStyle(ColorTokens.textPrimary)

            Text(step.body)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, Spacing.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Previews

#Preview("Pipeline diagram") {
    ScrollView {
        SFPipelineDiagram(steps: PipelineStep.all)
            .padding(Layout.screenMargin)
    }
}
