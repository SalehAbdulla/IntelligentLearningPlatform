import SwiftUI

struct SummaryEditablePoint: Identifiable, Equatable {
    let id = UUID()
    var text: String
}

struct SummaryEditSheet: View {

    let viewModel: SummaryScreensViewModel
    let summary: GeneratedSummary

    @Environment(\.dismiss) private var dismiss

    @State private var tldr: String
    @State private var points: [SummaryEditablePoint]
    @State private var isConfirmingDiscard = false

    init(viewModel: SummaryScreensViewModel, summary: GeneratedSummary) {
        self.viewModel = viewModel
        self.summary = summary
        _tldr = State(initialValue: summary.tldr)
        _points = State(initialValue: summary.keyPoints.map { SummaryEditablePoint(text: $0) })
    }

    private var error: String? {
        viewModel.editError(tldr: tldr, keyPoints: points.map(\.text))
    }

    private var hasChanges: Bool {
        tldr != summary.tldr || points.map(\.text) != summary.keyPoints
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("TL;DR", text: $tldr, axis: .vertical)
                        .lineLimit(3...6)
                        .onChange(of: tldr) {
                            if tldr.count > SummaryLimits.tldrMaxCharacters {
                                tldr = String(tldr.prefix(SummaryLimits.tldrMaxCharacters))
                            }
                        }
                } header: {
                    Text("TL;DR")
                } footer: {
                    Text("\(tldr.count)/\(SummaryLimits.tldrMaxCharacters)")
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
                            Label("Add key point", systemImage: "plus.circle.fill")
                        }
                    }
                } header: {
                    Text(L10n.summaryKeyPointsHeading.string)
                } footer: {
                    Text("Up to \(SummaryLimits.keyPointMaxCount) points, \(SummaryLimits.keyPointMaxCharacters) characters each.")
                }

                if let error {
                    Section {
                        Label(error, systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(ColorTokens.error)
                    }
                }
            }
            .navigationTitle("Edit summary")
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
                        viewModel.applyEdits(tldr: tldr, keyPoints: points.map(\.text))
                        dismiss()
                    }
                    .disabled(error != nil || !hasChanges)
                }
            }
            .confirmationDialog("Discard your changes?", isPresented: $isConfirmingDiscard, titleVisibility: .visible) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Keep editing", role: .cancel) {}
            }
        }
        .interactiveDismissDisabled(hasChanges)
    }
}
