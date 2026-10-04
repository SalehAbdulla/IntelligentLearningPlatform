//
//  CitationSheetView.swift
//  StudyForge
//
//  H04 — `76_Coach_Citation_SourceSheet_{M2}` (docs/03 §H, P0). The anti-hallucination guarantee,
//  made visible: the passage, where it lives, and how relevant it was.
//

import SwiftUI

struct CitationSheetView: View {

    let citation: Citation

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s5) {
                    VStack(alignment: .leading, spacing: Spacing.s1) {
                        Text(citation.materialTitle)
                            .font(.sfBodyEmph)
                            .foregroundStyle(ColorTokens.textPrimary)

                        if let page = citation.pageLabel {
                            Text(page)
                                .font(.sfFootnote)
                                .foregroundStyle(ColorTokens.textSecondary)
                        }

                        Text(L10n.coachRelevance.string(Int((citation.score * 100).rounded())))
                            .font(.sfFootnote)
                            .foregroundStyle(ColorTokens.textTertiary)
                    }

                    VStack(alignment: .leading, spacing: Spacing.s2) {
                        Text(L10n.coachPassage.string)
                            .font(.sfSubhead)
                            .foregroundStyle(ColorTokens.textSecondary)

                        Text(citation.snippet)
                            .font(.sfCallout)
                            .foregroundStyle(ColorTokens.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.s4)
                    .background(ColorTokens.primaryContainer, in: .rect(cornerRadius: Radius.l))
                }
                .padding(Layout.screenMargin)
                .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(ColorTokens.surface)
            .navigationTitle(L10n.coachSourceTitle.string)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.commonDone.string) { dismiss() }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("H04 Citation sheet") {
    CitationSheetView(
        citation: Citation(
            chunk: TextChunk(
                materialId: "m1",
                text: "Normalisation is the process of organising data to minimise redundancy.",
                page: 12,
                ordinal: 3,
                startOffset: 2_100
            ),
            materialTitle: "Lecture 4 — Normalisation",
            score: 0.71
        )
    )
}
