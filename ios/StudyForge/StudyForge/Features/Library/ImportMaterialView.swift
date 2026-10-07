//
//  ImportMaterialView.swift
//  StudyForge
//
//  C03 + C05 + C06 + C07 in one sheet — choose a source, extract on the device, then done or
//  failed. The view model says why the four designed screens are one.
//

import SwiftUI
import UniformTypeIdentifiers

// Accessibility: the two source cards are `SFRadioCard`s (each announces its title, detail and chosen
// state), every field is labelled by `SFTextField`, and the pasted-text area is a labelled text view, so
// the sheet reads as a set of controls rather than a run of labels and boxes.

struct ImportMaterialView: View {

    @State private var viewModel: ImportMaterialViewModel
    @State private var isChoosingPDF = false

    /// Raised once something has been imported, so the library behind it can reload.
    let onImported: () -> Void

    @Environment(\.dismiss) private var dismiss

    init(store: any MaterialStore, onImported: @escaping () -> Void) {
        _viewModel = State(initialValue: ImportMaterialViewModel(store: store))
        self.onImported = onImported
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s6) {

                    sourceChoice

                    if viewModel.source == .text {
                        pastedTextFields
                    } else {
                        pdfChoice
                    }

                    if let error = viewModel.error {
                        SFErrorBanner(error: error, onRecover: nil)
                    }
                }
                .padding(Layout.screenMargin)
                .frame(maxWidth: Layout.maxContentWidth)
                .frame(maxWidth: .infinity)
            }
            .background(ColorTokens.surface)
            .navigationTitle(viewModel.sheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel.string) { dismiss() }
                        .disabled(viewModel.isImporting)
                }
            }
            .fileImporter(
                isPresented: $isChoosingPDF,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                guard case .success(let urls) = result, let url = urls.first else { return }
                Task { await importPDF(at: url) }
            }
        }
    }

    // MARK: Sections

    /// Two cards rather than the design's grid: with two sources a grid is two tiles wide, and the
    /// radio card is the control the design system already has for "pick one, and here is what it
    /// means".
    private var sourceChoice: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            SFRadioCard(
                title: viewModel.pasteTextTitle,
                detail: viewModel.pasteTextDetail,
                isSelected: viewModel.source == .text
            ) {
                viewModel.source = .text
            }

            SFRadioCard(
                title: viewModel.choosePdfTitle,
                detail: viewModel.choosePdfDetail,
                isSelected: viewModel.source == .pdf
            ) {
                viewModel.source = .pdf
            }
        }
    }

    private var pastedTextFields: some View {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            SFTextField(
                label: viewModel.nameLabel,
                text: $viewModel.title,
                placeholder: viewModel.namePlaceholder,
                error: viewModel.titleError,
                submitLabel: .next,
                autocapitalization: .sentences,
                autocorrectionDisabled: false,
                onSubmit: {}
            )

            pastedTextEditor

            SFTextField(
                label: viewModel.tagsLabel,
                text: $viewModel.tagsText,
                hint: viewModel.tagsHint,
                submitLabel: .done,
                autocorrectionDisabled: true,
                onSubmit: {}
            )

            SFPrimaryButton(
                title: viewModel.submitTitle,
                isLoading: viewModel.isImporting,
                isEnabled: viewModel.isSubmitEnabled,
                action: { Task { await importPastedText() } },
                loadingTitle: viewModel.submittingTitle
            )
        }
    }

    /// A `TextEditor`, because pasted material is many lines — wearing the same field chrome as
    /// `SFTextField`, so it reads as the same kind of control rather than a different one.
    ///
    /// The minimum height is derived from the spacing scale rather than invented: a text area has
    /// to look like one, and four CTA-heights is enough to say so.
    private var pastedTextEditor: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(viewModel.textLabel)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)

            TextEditor(text: $viewModel.pastedText)
                .font(.sfBody)
                .foregroundStyle(ColorTokens.textPrimary)
                .frame(minHeight: Spacing.s12 * 4)
                .scrollContentBackground(.hidden)
                .sfFieldBackground(hasError: viewModel.textError != nil)
                .accessibilityLabel(viewModel.textLabel)

            SFFieldFeedback(error: viewModel.textError, hint: viewModel.textHint)
        }
    }

    private var pdfChoice: some View {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            SFTextField(
                label: viewModel.nameLabel,
                text: $viewModel.title,
                placeholder: viewModel.namePlaceholder,
                submitLabel: .done,
                autocapitalization: .sentences,
                autocorrectionDisabled: false,
                onSubmit: {}
            )

            SFTextField(
                label: viewModel.tagsLabel,
                text: $viewModel.tagsText,
                hint: viewModel.tagsHint,
                submitLabel: .done,
                autocorrectionDisabled: true,
                onSubmit: {}
            )

            // The file's own name becomes the title if nothing is typed, so this may be left blank.
            SFPrimaryButton(
                title: viewModel.choosePdfTitle,
                isLoading: viewModel.isImporting,
                isEnabled: viewModel.isSubmitEnabled,
                action: { isChoosingPDF = true },
                loadingTitle: viewModel.submittingTitle
            )
        }
    }

    // MARK: Actions

    private func importPastedText() async {
        await viewModel.importPastedText()
        finishIfImported()
    }

    private func importPDF(at url: URL) async {
        await viewModel.importPDF(at: url)
        finishIfImported()
    }

    private func finishIfImported() {
        guard viewModel.didImport else { return }
        onImported()
        dismiss()
    }
}

// MARK: - Previews

#Preview("C03 Import material") {
    ImportMaterialView(store: InMemoryMaterialStore()) {}
}
