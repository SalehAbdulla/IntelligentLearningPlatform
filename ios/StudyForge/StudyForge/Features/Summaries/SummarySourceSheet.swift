import SwiftUI

struct SummarySourceSheet: View {

    let source: SummarySource
    let onOpen: ((SummarySource) -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s4) {
                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Text("\(L10n.summarySource.string) · p.\(source.page)")
                        .font(.sfTitleS)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text(source.fileName)
                        .font(.sfFootnote)
                        .foregroundStyle(ColorTokens.textSecondary)
                }

                Text(source.quote)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(Spacing.s4)
                    .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
                    .summaryGlass(strong: true)

                Text(source.relevanceLabel)
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.successText)

                SFPrimaryButton(title: "Open in viewer") {
                    dismiss()
                    onOpen?(source)
                }
                .padding(.top, Spacing.s3)
            }
            .padding(.horizontal, Layout.screenMargin + Spacing.s3)
            .padding(.top, Spacing.s6)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .presentationBackground(.regularMaterial)
    }
}
