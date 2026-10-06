//
//  DesignSystemGallery.swift
//  StudyForge
//
//  A living proof that the design tokens render correctly in both appearances,
//  and the S0 demoable outcome for the app foundation (docs/10-SPRINT-PLAN.md §4 → M3).
//
//  A development surface, not a product screen. It stays in the app because it is
//  genuinely useful for reviewing a token change at a glance.
//

import SwiftUI

struct DesignSystemGallery: View {

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s6) {
                    brandSection
                    semanticSection
                    typeSection
                    spacingSection
                    componentSection
                }
                .padding(Layout.screenMargin)
                .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
            }
            .background(ColorTokens.surface)
            .navigationTitle("Design System")
        }
    }

    // MARK: - Sections

    private var brandSection: some View {
        section("Brand") {
            swatchRow([
                ("primary", ColorTokens.primary),
                ("primaryContainer", ColorTokens.primaryContainer),
                ("accent", ColorTokens.accent),
                ("secondary", ColorTokens.secondary),
            ])
            caption("Ember (accent) is a fill colour only. Text on it must use onAccent, because white on Ember fails WCAG AA at 2.8:1.")
        }
    }

    private var semanticSection: some View {
        section("Semantic") {
            swatchRow([
                ("success", ColorTokens.success),
                ("warning", ColorTokens.warning),
                ("error", ColorTokens.error),
                ("outline", ColorTokens.outline),
            ])
            swatchRow([
                ("secondaryText", ColorTokens.secondaryText),
                ("accentText", ColorTokens.accentText),
                ("warningText", ColorTokens.warningText),
            ])
            HStack(spacing: Spacing.s3) {
                Text("Correct")
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.onAccent)
                    .padding(.horizontal, Spacing.s3)
                    .padding(.vertical, Spacing.s1)
                    .background(ColorTokens.success, in: Capsule())
                Text("AA-safe text")
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.successText)
            }
            caption("The *Text tokens are the AA-safe text variants of their hue: use them wherever the colour itself is the text. successText 5.5:1, secondaryText 5.5:1, accentText 5.2:1 and warningText 5.0:1 on surface. The bare secondary/accent/warning tokens stay fill-only.")
        }
    }

    private var typeSection: some View {
        section("Type scale") {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                Text("Display L").font(.sfDisplayL)
                Text("Title L").font(.sfTitleL)
                Text("Title M").font(.sfTitleM)
                Text("Title S").font(.sfTitleS)
                Text("Body — the default reading size.").font(.sfBody)
                Text("Callout — secondary body.").font(.sfCallout)
                Text("Footnote — metadata.").font(.sfFootnote)
                Text("CAPTION — CHIPS").font(.sfCaption)
                Text("482913").font(.sfMono)
            }
            .foregroundStyle(ColorTokens.textPrimary)
            caption("Body is 17 pt; nothing user-facing drops below 11 pt. textSecondary is 7.6:1 on surface (AAA); textTertiary is 2.6:1 and is disabled/decorative only.")
        }
    }

    private var spacingSection: some View {
        section("Spacing — 4 pt grid") {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                ForEach(spacingSamples, id: \.0) { name, value in
                    HStack(spacing: Spacing.s3) {
                        Text(name)
                            .font(.sfFootnote)
                            .foregroundStyle(ColorTokens.textSecondary)
                            .frame(width: 34, alignment: .leading)
                        Rectangle()
                            .fill(ColorTokens.primary.opacity(0.25))
                            .frame(width: value, height: Spacing.s4)
                        Text("\(Int(value)) pt")
                            .font(.sfCaption)
                            .foregroundStyle(ColorTokens.textTertiary)
                    }
                }
            }
        }
    }

    private var componentSection: some View {
        section("Components") {
            VStack(alignment: .leading, spacing: Spacing.s3) {
                Button("Primary action") {}
                    .font(.sfTitleS)
                    .foregroundStyle(ColorTokens.onError)
                    .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget)
                    .background(ColorTokens.primary, in: RoundedRectangle(cornerRadius: Radius.m))

                Button("Secondary action") {}
                    .font(.sfTitleS)
                    .foregroundStyle(ColorTokens.primary)
                    .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.m)
                            .strokeBorder(ColorTokens.primary, lineWidth: 1.5)
                    )

                HStack(spacing: Spacing.s3) {
                    Text("F04")
                        .font(.sfMono)
                        .foregroundStyle(ColorTokens.onAccent)
                        .padding(.horizontal, Spacing.s2)
                        .padding(.vertical, Spacing.s1)
                        .background(ColorTokens.accent, in: Capsule())
                    Text("Due today")
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .padding(.horizontal, Spacing.s2)
                        .padding(.vertical, Spacing.s1)
                        .background(ColorTokens.primaryContainer, in: Capsule())
                }
            }
            caption("Minimum touch target is 44x44 pt everywhere. S0 ships the token layer; the full component library lands in Sprint S1.")
        }
    }

    // MARK: - Helpers

    private var spacingSamples: [(String, CGFloat)] {
        [("s1", Spacing.s1), ("s2", Spacing.s2), ("s3", Spacing.s3), ("s4", Spacing.s4),
         ("s6", Spacing.s6), ("s8", Spacing.s8), ("s12", Spacing.s12)]
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(title)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)
            content()
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTokens.surfaceVariant, in: RoundedRectangle(cornerRadius: Radius.l))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.l)
                .strokeBorder(ColorTokens.outline, lineWidth: 1)
        )
    }

    private func swatchRow(_ items: [(String, Color)]) -> some View {
        HStack(spacing: Spacing.s2) {
            ForEach(items, id: \.0) { name, color in
                VStack(spacing: Spacing.s1) {
                    RoundedRectangle(cornerRadius: Radius.s)
                        .fill(color)
                        .frame(height: Layout.minTouchTarget)
                    Text(name)
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
        }
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.sfFootnote)
            .foregroundStyle(ColorTokens.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview("Light") { DesignSystemGallery() }

#Preview("Dark") { DesignSystemGallery().preferredColorScheme(.dark) }

