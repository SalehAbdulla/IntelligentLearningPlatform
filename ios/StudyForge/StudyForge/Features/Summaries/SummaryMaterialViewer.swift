import SwiftUI

struct SummaryMaterialViewer: View {

    let material: Material
    let source: SummarySource

    @Environment(\.dismiss) private var dismiss

    private var sections: [SummaryMaterialSection] {
        SummaryGrounding.sections(of: material)
    }

    var body: some View {
        let allSections = self.sections
        let target = SummaryGrounding.targetSectionID(for: source, in: allSections)

        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: Spacing.s4) {
                        Text(source.fileName)
                            .font(.sfFootnote)
                            .foregroundStyle(ColorTokens.textSecondary)

                        ForEach(allSections) { section in
                            sectionCard(section, isCited: section.id == target)
                                .id(section.id)
                        }
                    }
                    .padding(.horizontal, Layout.screenMargin + Spacing.s3)
                    .padding(.vertical, Spacing.s4)
                    .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
                    .frame(maxWidth: .infinity)
                }
                .onAppear {
                    if let target {
                        proxy.scrollTo(target, anchor: .top)
                    }
                }
            }
            .background(SummaryBackdrop())
            .navigationTitle(material.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.commonDone.string) { dismiss() }
                }
            }
        }
    }

    private func sectionCard(_ section: SummaryMaterialSection, isCited: Bool) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            if let page = section.page {
                Text("Page \(page)")
                    .font(.sfFootnote.weight(.semibold))
                    .foregroundStyle(isCited ? ColorTokens.successText : ColorTokens.textSecondary)
                    .accessibilityAddTraits(.isHeader)
            }
            Text(highlighted(section.body))
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .summaryGlass(strong: true)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                .strokeBorder(isCited ? ColorTokens.success : Color.clear, lineWidth: 2)
        )
    }

    private func highlighted(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)
        if !source.excerpt.isEmpty, let range = attributed.range(of: source.excerpt) {
            attributed[range].backgroundColor = ColorTokens.warning.opacity(0.35)
            attributed[range].font = Font.sfCallout.weight(.semibold)
        }
        return attributed
    }
}
