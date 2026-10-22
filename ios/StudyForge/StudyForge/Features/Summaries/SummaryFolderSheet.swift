import SwiftUI

struct SummaryFolderSheet: View {

    @State private var viewModel: SummaryFolderPickerViewModel

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFieldFocused: Bool

    init(summaryID: String, summaryTitle: String, store: any FolderStore, userName: String) {
        _viewModel = State(initialValue: SummaryFolderPickerViewModel(
            summaryID: summaryID,
            summaryTitle: summaryTitle,
            store: store,
            userName: userName
        ))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: Spacing.s3) {
                        TextField(SummaryCopy.folderNewPlaceholder, text: $viewModel.newFolderName)
                            .focused($isNameFieldFocused)
                            .submitLabel(.done)
                            .onSubmit { Task { await viewModel.createAndAdd() } }
                        Button(SummaryCopy.folderCreate) {
                            isNameFieldFocused = false
                            Task { await viewModel.createAndAdd() }
                        }
                        .font(.sfCallout.weight(.semibold))
                        .disabled(!viewModel.canCreate)
                    }
                    .frame(minHeight: Layout.minTouchTarget)

                    if let message = viewModel.validationMessage {
                        Label(message, systemImage: "exclamationmark.circle.fill")
                            .font(.sfFootnote)
                            .foregroundStyle(ColorTokens.error)
                    }
                }

                if let added = viewModel.addedFolderName {
                    Section {
                        Label(SummaryCopy.folderAdded(added), systemImage: "checkmark.circle.fill")
                            .font(.sfCallout.weight(.semibold))
                            .foregroundStyle(ColorTokens.successText)
                    }
                }

                if let error = viewModel.error {
                    Section {
                        SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
                    }
                }

                Section {
                    if viewModel.isLoading && viewModel.folders.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if viewModel.isEmpty {
                        Text(SummaryCopy.folderEmpty)
                            .font(.sfCallout)
                            .foregroundStyle(ColorTokens.textSecondary)
                    } else if viewModel.hasNoMatches {
                        Text(SummaryCopy.folderNoMatches(viewModel.query))
                            .font(.sfCallout)
                            .foregroundStyle(ColorTokens.textSecondary)
                    } else {
                        ForEach(viewModel.rows) { row in
                            folderRow(row)
                        }
                    }
                }
            }
            .searchable(text: $viewModel.query, prompt: Text(SummaryCopy.folderSearch))
            .navigationTitle(SummaryCopy.folderTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.commonDone.string) { dismiss() }
                }
            }
            .task { await viewModel.load() }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func folderRow(_ row: SummaryFolderPickerViewModel.Row) -> some View {
        Button {
            Task { await viewModel.add(to: row) }
        } label: {
            HStack(spacing: Spacing.s3) {
                Image(systemName: row.isShared ? "person.2.fill" : "folder.fill")
                    .foregroundStyle(ColorTokens.primary)
                    .frame(minWidth: Spacing.s6)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Text(row.folder.name)
                        .font(.sfBodyEmph)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .lineLimit(1)
                    Text(subtitle(for: row))
                        .font(.sfFootnote)
                        .foregroundStyle(row.canAdd ? ColorTokens.textSecondary : ColorTokens.warningText)
                }

                Spacer(minLength: 0)

                if row.alreadyContains {
                    Image(systemName: "checkmark")
                        .foregroundStyle(ColorTokens.successText)
                        .accessibilityHidden(true)
                } else if !row.canAdd {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(ColorTokens.textTertiary)
                        .accessibilityHidden(true)
                }
            }
            .frame(minHeight: Layout.minTouchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!row.canAdd || row.alreadyContains || viewModel.isWorking)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.folder.name), \(subtitle(for: row))")
    }

    private func subtitle(for row: SummaryFolderPickerViewModel.Row) -> String {
        if row.alreadyContains {
            return SummaryCopy.folderAlready
        }
        if !row.canAdd {
            return SummaryCopy.folderViewOnly
        }
        return row.isShared ? SummaryCopy.folderShared(members: row.memberCount) : SummaryCopy.folderPrivate
    }
}
