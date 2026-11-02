import SwiftUI

struct FlashcardEditorSheet: View {

    let title: String
    let onSave: (String, String) -> Void
    let onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var front: String
    @State private var back: String
    @State private var isConfirmingDelete = false
    @State private var isConfirmingDiscard = false

    private let originalFront: String
    private let originalBack: String

    init(
        title: String,
        front: String,
        back: String,
        onSave: @escaping (String, String) -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.title = title
        self.onSave = onSave
        self.onDelete = onDelete
        self.originalFront = front
        self.originalBack = back
        _front = State(initialValue: front)
        _back = State(initialValue: back)
    }

    private var isValid: Bool {
        !FlashcardText.isBlank(front) && !FlashcardText.isBlank(back)
    }

    private var hasChanges: Bool {
        front != originalFront || back != originalBack
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(FlashcardCopy.frontPlaceholder, text: $front, axis: .vertical)
                        .lineLimit(2...6)
                        .onChange(of: front) {
                            let limited = FlashcardText.clamp(front, to: FlashcardLimits.frontMaxCharacters)
                            if limited != front { front = limited }
                        }
                } header: {
                    Text(FlashcardCopy.front)
                } footer: {
                    Text(FlashcardCopy.characters(front.count, FlashcardLimits.frontMaxCharacters))
                        .monospacedDigit()
                }

                Section {
                    TextField(FlashcardCopy.backPlaceholder, text: $back, axis: .vertical)
                        .lineLimit(3...8)
                        .onChange(of: back) {
                            let limited = FlashcardText.clamp(back, to: FlashcardLimits.backMaxCharacters)
                            if limited != back { back = limited }
                        }
                } header: {
                    Text(FlashcardCopy.back)
                } footer: {
                    Text(FlashcardCopy.characters(back.count, FlashcardLimits.backMaxCharacters))
                        .monospacedDigit()
                }

                if hasChanges && !isValid {
                    Section {
                        Label(FlashcardCopy.cardBlank, systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(ColorTokens.error)
                    }
                }

                if onDelete != nil {
                    Section {
                        Button(FlashcardCopy.deleteCard, role: .destructive) {
                            isConfirmingDelete = true
                        }
                        .confirmationDialog(
                            FlashcardCopy.deleteCardTitle,
                            isPresented: $isConfirmingDelete,
                            titleVisibility: .visible
                        ) {
                            Button(FlashcardCopy.deleteCard, role: .destructive) {
                                onDelete?()
                                dismiss()
                            }
                            Button(L10n.commonCancel.string, role: .cancel) {}
                        } message: {
                            Text(FlashcardCopy.deleteCardMessage)
                        }
                    }
                }
            }
            .navigationTitle(title)
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
                    Button(FlashcardCopy.save) {
                        onSave(
                            FlashcardText.cleaned(front, limit: FlashcardLimits.frontMaxCharacters),
                            FlashcardText.cleaned(back, limit: FlashcardLimits.backMaxCharacters)
                        )
                        dismiss()
                    }
                    .disabled(!isValid || !hasChanges)
                }
            }
            .confirmationDialog(
                FlashcardCopy.discardChangesTitle,
                isPresented: $isConfirmingDiscard,
                titleVisibility: .visible
            ) {
                Button(FlashcardCopy.discard, role: .destructive) { dismiss() }
                Button(FlashcardCopy.keepEditing, role: .cancel) {}
            }
        }
        .interactiveDismissDisabled(hasChanges)
    }
}

#Preview("E08 Edit card") {
    FlashcardEditorSheet(
        title: FlashcardCopy.editCard,
        front: "What is a leaf node?",
        back: "A node with no children.",
        onSave: { _, _ in },
        onDelete: {}
    )
}
