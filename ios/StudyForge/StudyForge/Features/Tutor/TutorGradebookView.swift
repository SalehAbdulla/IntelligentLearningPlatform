import SwiftUI

struct TutorGradebookView: View {

    @State private var viewModel: TutorGradebookViewModel

    init(container: AppContainer, course: Course) {
        _viewModel = State(initialValue: TutorGradebookViewModel(course: course, store: container.courses))
    }

    var body: some View {
        ZStack {
            SummaryBackdrop()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.s5) {
                        formatSection
                        columnsSection
                        scopeSection
                        preview
                        Text(TutorStudioCopy.gradebookNote)
                            .font(.sfCaption)
                            .foregroundStyle(ColorTokens.textSecondary)
                        if let error = viewModel.error {
                            SFErrorBanner(error: error, onRecover: nil)
                        }
                    }
                    .padding(.horizontal, TutorStudioLayout.margin)
                    .padding(.vertical, Spacing.s4)
                    .frame(maxWidth: Layout.maxContentWidth)
                    .frame(maxWidth: .infinity)
                }
                exportBar
            }
        }
        .navigationTitle(TutorStudioCopy.exportGradebook)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .onChange(of: viewModel.format) { viewModel.settingsChanged() }
        .onChange(of: viewModel.limitsToStartDate) { viewModel.settingsChanged() }
        .onChange(of: viewModel.startDate) { viewModel.settingsChanged() }
        .onChange(of: viewModel.includesRemoved) { viewModel.settingsChanged() }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.sfCaption.weight(.semibold))
            .foregroundStyle(ColorTokens.textSecondary)
            .textCase(.uppercase)
    }

    private var formatSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            sectionLabel(TutorStudioCopy.formatLabel)
            SummaryOptionPicker(
                title: TutorStudioCopy.fileType,
                options: TutorGradebookFormat.allCases,
                selection: $viewModel.format,
                optionTitle: { TutorStudioCopy.formatTitle($0) }
            )
        }
    }

    private var columnsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            sectionLabel(TutorStudioCopy.includeLabel)
            VStack(spacing: 0) {
                ForEach(TutorGradebookColumn.allCases) { column in
                    Toggle(column.title, isOn: Binding(
                        get: { viewModel.isIncluded(column) },
                        set: { _ in viewModel.toggle(column) }
                    ))
                    .font(.sfCallout)
                    .tint(ColorTokens.primary)
                    .frame(minHeight: Layout.minTouchTarget)
                }
            }
            .padding(.horizontal, Spacing.s4)
            .summaryGlass()
        }
    }

    private var scopeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            sectionLabel(TutorStudioCopy.scopeLabel)
            VStack(alignment: .leading, spacing: Spacing.s2) {
                LabeledContent(TutorStudioCopy.courseLabel, value: TutorStudioCopy.courseTitle(viewModel.course.code, viewModel.course.name))
                LabeledContent(TutorStudioCopy.studentsLabel, value: viewModel.scopeSummary)
                Toggle(TutorStudioCopy.activeSinceToggle, isOn: $viewModel.limitsToStartDate)
                    .tint(ColorTokens.primary)
                if viewModel.limitsToStartDate {
                    DatePicker(TutorStudioCopy.fromLabel, selection: $viewModel.startDate, displayedComponents: .date)
                }
                Toggle(TutorStudioCopy.includeRemoved, isOn: $viewModel.includesRemoved)
                    .tint(ColorTokens.primary)
            }
            .font(.sfCallout)
            .padding(Spacing.s4)
            .summaryGlass()
        }
    }

    @ViewBuilder
    private var preview: some View {
        if !viewModel.hasLoaded {
            ProgressView().frame(maxWidth: .infinity)
        } else if viewModel.rows.isEmpty {
            Text(TutorStudioCopy.noRows)
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.textSecondary)
                .padding(Spacing.s4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .summaryGlass()
        } else {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                sectionLabel(TutorStudioCopy.previewLabel)
                ScrollView(.horizontal, showsIndicators: false) {
                    Grid(alignment: .leading, horizontalSpacing: Spacing.s4, verticalSpacing: Spacing.s2) {
                        GridRow {
                            ForEach(viewModel.orderedColumns) { column in
                                Text(column.title)
                                    .font(.sfCaption.weight(.semibold))
                                    .foregroundStyle(ColorTokens.textSecondary)
                            }
                        }
                        Divider().gridCellUnsizedAxes(.horizontal)
                        ForEach(viewModel.rows.prefix(8)) { enrollment in
                            GridRow {
                                ForEach(viewModel.orderedColumns) { column in
                                    Text(viewModel.value(column, for: enrollment))
                                        .font(.sfFootnote)
                                        .foregroundStyle(ColorTokens.textPrimary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .padding(Spacing.s4)
                }
                .summaryGlass(strong: true)
            }
        }
    }

    private var exportBar: some View {
        VStack(spacing: Spacing.s2) {
            if let url = viewModel.exportedURL {
                ShareLink(item: url) {
                    Label(TutorStudioCopy.shareFile(url.lastPathComponent), systemImage: "square.and.arrow.up")
                        .font(.sfCallout.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .foregroundStyle(ColorTokens.onError)
                        .background(ColorTokens.primary, in: .rect(cornerRadius: Radius.m))
                }
            } else {
                SFPrimaryButton(
                    title: TutorStudioCopy.exportButton(TutorStudioCopy.formatTitle(viewModel.format)),
                    isLoading: viewModel.isExporting,
                    isEnabled: viewModel.canExport
                ) {
                    Task { await viewModel.export() }
                }
            }
        }
        .padding(.horizontal, TutorStudioLayout.margin)
        .padding(.vertical, Spacing.s3)
    }
}

#Preview("108 Gradebook") {
    NavigationStack {
        TutorGradebookView(container: .previewing(), course: Course.sample)
    }
}
