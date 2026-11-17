import SwiftUI

struct FlashcardEditorSheet: View {

    let title: String
    let onSubmit: (FlashcardEdit) -> Void
    let onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var front: String
    @State private var back: String
    @State private var tags: [String]
    @State private var deckId: String?
    @State private var newTag = ""
    @State private var isConfirmingDelete = false
    @State private var isConfirmingDiscard = false

    private let originalFront: String
    private let originalBack: String
    private let originalTags: [String]
    private let showsTags: Bool
    private let decks: [Deck]
    private let originalDeckId: String?

    init(
        title: String,
        front: String,
        back: String,
        tags: [String]? = nil,
        decks: [Deck] = [],
        deckId: String? = nil,
        onSubmit: @escaping (FlashcardEdit) -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.title = title
        self.onSubmit = onSubmit
        self.onDelete = onDelete
        self.originalFront = front
        self.originalBack = back
        let visibleTags = FlashcardTags.visible(tags ?? [])
        self.originalTags = visibleTags
        self.showsTags = tags != nil
        self.decks = decks
        self.originalDeckId = deckId
        _deckId = State(initialValue: deckId)
        _front = State(initialValue: front)
        _back = State(initialValue: back)
        _tags = State(initialValue: visibleTags)
    }

    init(
        title: String,
        front: String,
        back: String,
        onSave: @escaping (String, String) -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.init(
            title: title,
            front: front,
            back: back,
            tags: nil,
            onSubmit: { edit in onSave(edit.front, edit.back) },
            onDelete: onDelete
        )
    }

    private var isValid: Bool {
        !FlashcardText.isBlank(front) && !FlashcardText.isBlank(back)
    }

    private var hasChanges: Bool {
        front != originalFront || back != originalBack || tags != originalTags || deckId != originalDeckId
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

                if showsTags {
                    tagsSection
                }

                if decks.count > 1, deckId != nil {
                    Section {
                        Picker(FlashcardCopy.deck, selection: $deckId) {
                            ForEach(decks) { deck in
                                Text(deck.title).tag(Optional(deck.id))
                            }
                        }
                    } header: {
                        Text(FlashcardCopy.deck)
                    }
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
                        submit()
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

    private var tagsSection: some View {
        Section {
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.s2) {
                        ForEach(tags, id: \.self) { tag in
                            tagChip(tag)
                        }
                    }
                    .padding(.vertical, Spacing.s1)
                }
            }
            HStack(spacing: Spacing.s2) {
                TextField(FlashcardCopy.tagPlaceholder, text: $newTag)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit(addTag)
                Button(FlashcardCopy.addTag, systemImage: "plus.circle.fill", action: addTag)
                    .labelStyle(.iconOnly)
                    .font(.sfTitleS)
                    .frame(minWidth: Layout.minTouchTarget, minHeight: Layout.minTouchTarget)
                    .disabled(FlashcardTags.normalized(newTag) == nil || tags.count >= FlashcardTags.maxCount)
            }
        } header: {
            Text(FlashcardCopy.tags)
        } footer: {
            Text(FlashcardCopy.tagsFooter(FlashcardTags.maxCount))
        }
    }

    private func tagChip(_ tag: String) -> some View {
        Button {
            tags.removeAll { $0 == tag }
        } label: {
            HStack(spacing: Spacing.s1) {
                Text(verbatim: "#\(tag)")
                Image(systemName: "xmark")
                    .font(.sfCaption.weight(.bold))
            }
            .font(.sfFootnote.weight(.semibold))
            .foregroundStyle(ColorTokens.onAccent)
            .padding(.horizontal, Spacing.s3)
            .frame(minHeight: 32)
            .background(ColorTokens.success, in: .capsule)
            .frame(minHeight: Layout.minTouchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(FlashcardCopy.removeTag(tag))
    }

    private func addTag() {
        let updated = FlashcardTags.adding(newTag, to: tags)
        if updated != tags {
            tags = updated
        }
        newTag = ""
    }

    private func submit() {
        let finalTags = FlashcardText.isBlank(newTag) ? tags : FlashcardTags.adding(newTag, to: tags)
        onSubmit(
            FlashcardEdit(
                front: FlashcardText.cleaned(front, limit: FlashcardLimits.frontMaxCharacters),
                back: FlashcardText.cleaned(back, limit: FlashcardLimits.backMaxCharacters),
                tags: finalTags,
                deckId: deckId
            )
        )
        dismiss()
    }
}

#Preview("E08 Edit card") {
    FlashcardEditorSheet(
        title: FlashcardCopy.editCard,
        front: "What is a leaf node?",
        back: "A node with no children.",
        tags: ["trees", "basics"],
        decks: [Deck(id: "a", title: "Trees & Graphs"), Deck(id: "b", title: "Algorithms")],
        deckId: "a",
        onSubmit: { _ in },
        onDelete: {}
    )
}
