import SwiftUI

struct SummaryEditablePoint: Identifiable, Equatable {
    let id = UUID()
    var text: String
}

struct SummaryEditSheet: View {

    let viewModel: SummaryScreensViewModel
    let summary: GeneratedSummary

    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var tldr: String
    @State private var points: [SummaryEditablePoint]
    @State private var showsAIDraftLabel: Bool
    @State private var isConfirmingDiscard = false

    init(viewModel: SummaryScreensViewModel, summary: GeneratedSummary) {
        self.viewModel = viewModel
        self.summary = summary
        _title = State(initialValue: summary.title)
        _tldr = State(initialValue: summary.tldr)
        _points = State(initialValue: summary.keyPoints.map { SummaryEditablePoint(text: $0) })
        _showsAIDraftLabel = State(initialValue: summary.showsAIDraftLabel)
    }

    private var error: String? {
        viewModel.editError(title: title, tldr: tldr, keyPoints: points.map(\.text))
    }

    private var hasChanges: Bool {
        title != summary.title
            || tldr != summary.tldr
            || points.map(\.text) != summary.keyPoints
            || showsAIDraftLabel != summary.showsAIDraftLabel
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(SummaryCopy.titleField, text: $title)
                        .onChange(of: title) {
                            if title.count > SummaryLimits.titleMaxCharacters {
                                title = String(title.prefix(SummaryLimits.titleMaxCharacters))
                            }
                        }
                } header: {
                    Text(SummaryCopy.titleField)
                }

                Section {
                    TextField(SummaryCopy.tldr, text: $tldr, axis: .vertical)
                        .lineLimit(3...6)
                        .onChange(of: tldr) {
                            if tldr.count > SummaryLimits.tldrMaxCharacters {
                                tldr = String(tldr.prefix(SummaryLimits.tldrMaxCharacters))
                            }
                        }
                } header: {
                    Text(SummaryCopy.tldr)
                } footer: {
                    Text(verbatim: "\(tldr.count)/\(SummaryLimits.tldrMaxCharacters)")
                        .monospacedDigit()
                }

                Section {
                    ForEach($points) { $point in
                        HStack {
                            TextField(L10n.summaryKeyPointsHeading.string, text: $point.text, axis: .vertical)
                                .onChange(of: point.text) {
                                    if point.text.count > SummaryLimits.keyPointMaxCharacters {
                                        point.text = String(point.text.prefix(SummaryLimits.keyPointMaxCharacters))
                                    }
                                }
                            Button {
                                points.removeAll { $0.id == point.id }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(ColorTokens.error)
                                    .frame(minWidth: Layout.minTouchTarget, minHeight: Layout.minTouchTarget)
                            }
                            .buttonStyle(.plain)
                            .disabled(points.count <= 1)
                            .accessibilityLabel(L10n.commonDelete.string)
                        }
                    }

                    if points.count < SummaryLimits.keyPointMaxCount {
                        Button {
                            points.append(SummaryEditablePoint(text: ""))
                        } label: {
                            Label(SummaryCopy.addKeyPoint, systemImage: "plus.circle.fill")
                        }
                    }
                } header: {
                    Text(L10n.summaryKeyPointsHeading.string)
                } footer: {
                    Text(SummaryCopy.pointsFooter(count: SummaryLimits.keyPointMaxCount, characters: SummaryLimits.keyPointMaxCharacters))
                }

                Section {
                    Toggle(isOn: $showsAIDraftLabel) {
                        Label(SummaryCopy.watermarkToggle, systemImage: "sparkles")
                    }
                } footer: {
                    Text(SummaryCopy.watermarkFooter(citation: summary.source.pageLabel))
                }

                if let error {
                    Section {
                        Label(error, systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(ColorTokens.error)
                    }
                }
            }
            .navigationTitle(SummaryCopy.editSheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel.string) {
                        if hasChanges {
                            isConfirmingDiscard = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.commonDone.string) {
                        viewModel.applyEdits(
                            title: title,
                            tldr: tldr,
                            keyPoints: points.map(\.text),
                            showsAIDraftLabel: showsAIDraftLabel
                        )
                        dismiss()
                    }
                    .disabled(error != nil || !hasChanges)
                }
            }
            .confirmationDialog(SummaryCopy.discardChangesTitle, isPresented: $isConfirmingDiscard, titleVisibility: .visible) {
                Button(SummaryCopy.discardConfirm, role: .destructive) { dismiss() }
                Button(SummaryCopy.keepEditing, role: .cancel) {}
            }
        }
        .interactiveDismissDisabled(hasChanges)
    }
}
