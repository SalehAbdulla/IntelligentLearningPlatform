//
//  MaterialLibraryView.swift
//  StudyForge
//
//  C08 — `31_Library_Materials_List_{M1}` (docs/03 §C, P0). Everything the student has brought
//  in, searchable, with the four states designed rather than improvised.
//
//  WHY IT TAKES A STORE RATHER THAN THE CONTAINER
//  ---------------------------------------------
//  It needs materials and nothing else, so it asks for materials and nothing else. That also lets
//  a preview hand it a seeded `InMemoryMaterialStore` and show a populated library without
//  fabricating a whole signed-in app.
//
//  WHERE THE FILES ARE
//  ------------------
//  Nowhere this screen can see. The store owns that (see `MaterialStore`), which is the point of
//  D24 in code: the screen is written as if the materials were simply there, because on-device is
//  where they are.
//

import SwiftUI

struct MaterialLibraryView: View {

    @State private var viewModel: MaterialLibraryViewModel
    @State private var isImporting = false

    /// The material the student chose to summarise (F03), presented as a sheet.
    @State private var summaryMaterial: Material?

    /// The material the student chose to turn into flashcards (F04), presented as a sheet.
    @State private var cardsMaterial: Material?

    /// Kept because the import sheet needs it. The screen itself only ever asks the view model.
    private let store: any MaterialStore
    private let summaryStore: any SummaryStore
    private let deckStore: any DeckStore
    private let router: AIRouter
    private let learningStyle: LearningStyle

    init(
        store: any MaterialStore,
        summaryStore: any SummaryStore,
        deckStore: any DeckStore,
        router: AIRouter,
        learningStyle: LearningStyle = .visual
    ) {
        self.store = store
        self.summaryStore = summaryStore
        self.deckStore = deckStore
        self.router = router
        self.learningStyle = learningStyle
        _viewModel = State(initialValue: MaterialLibraryViewModel(store: store))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
                    .padding(Layout.screenMargin)
            } else if viewModel.isEmpty {
                emptyState
            } else {
                library
            }
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.query, prompt: Text(viewModel.searchPrompt))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isImporting = true
                } label: {
                    Label(L10n.importTitle.string, systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isImporting) {
            ImportMaterialView(store: store) {
                // Reloaded rather than appended: one path back from the store, so the new material
                // is where it would be on the next launch too.
                Task { await viewModel.load() }
            }
        }
        .sheet(item: $summaryMaterial) { material in
            SummaryFlowView(
                material: material,
                router: router,
                store: summaryStore,
                learningStyle: learningStyle
            )
        }
        .sheet(item: $cardsMaterial) { material in
            FlashcardGenerateView(
                initialMaterial: material,
                materialStore: store,
                deckStore: deckStore,
                router: router,
                learningStyle: learningStyle
            )
        }
        .task { await viewModel.load() }
    }

    // MARK: Sections

    private var library: some View {
        Group {
            if viewModel.hasNoMatches {
                notice(title: viewModel.noMatchesTitle, body: viewModel.noMatchesBody)
            } else {
                List {
                    ForEach(viewModel.visibleMaterials) { material in
                        row(material)
                    }
                }
                .listStyle(.plain)
                // The list draws on our surface, not the system one, so the screen does not
                // change colour halfway down inside a form.
                .scrollContentBackground(.hidden)
            }
        }
    }

    /// The empty library — a state worth designing, because it is what every student sees first.
    private var emptyState: some View {
        notice(title: viewModel.emptyTitle, body: viewModel.emptyBody)
    }

    private func notice(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(title)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)

            Text(body)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Layout.screenMargin)
        // One statement, so VoiceOver reads it as an explanation rather than two loose lines.
        .accessibilityElement(children: .combine)
    }

    private func row(_ material: Material) -> some View {
        HStack(spacing: Spacing.s3) {

            // The icon + title + tags read as one statement, so VoiceOver does not announce them
            // as three fragments. The Summarise button stays a separate element beside them.
            HStack(spacing: Spacing.s3) {
                Image(systemName: material.source.symbolName)
                    .font(.sfBody)
                    .foregroundStyle(ColorTokens.primary)
                    .frame(minWidth: Spacing.s6, alignment: .leading)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Text(material.title)
                        .font(.sfBodyEmph)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .lineLimit(2)

                    if !material.tags.isEmpty {
                        Text(material.tags.map { "#\($0)" }.joined(separator: "  "))
                            .font(.sfCaption)
                            .foregroundStyle(ColorTokens.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(material.title), \(material.source.title)")

            Spacer(minLength: 0)

            // F03's entry point. The source is the one thing the icon conveys and a screen reader
            // cannot see, so the action is named rather than drawn.
            Button {
                summaryMaterial = material
            } label: {
                Image(systemName: "sparkles")
                    .font(.sfBody)
                    .foregroundStyle(ColorTokens.primary)
                    .frame(minWidth: Layout.minTouchTarget, minHeight: Layout.minTouchTarget)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.librarySummarise.string)

            Button {
                cardsMaterial = material
            } label: {
                Image(systemName: "rectangle.stack")
                    .font(.sfBody)
                    .foregroundStyle(ColorTokens.primary)
                    .frame(minWidth: Layout.minTouchTarget, minHeight: Layout.minTouchTarget)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.libraryMakeCards.string)
        }
        .padding(.vertical, Spacing.s2)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task { await viewModel.delete(material) }
            } label: {
                Label(L10n.commonDelete.string, systemImage: "trash")
            }
        }
    }
}

// MARK: - Previews

#Preview("C08 Library — with materials") {
    NavigationStack {
        MaterialLibraryView(
            store: InMemoryMaterialStore(seededWith: Material.samples),
            summaryStore: InMemorySummaryStore(),
            deckStore: InMemoryDeckStore(),
            router: AIRouter.standard(governor: AICostGovernor())
        )
    }
}

#Preview("C08 Library — empty") {
    NavigationStack {
        MaterialLibraryView(
            store: InMemoryMaterialStore(),
            summaryStore: InMemorySummaryStore(),
            deckStore: InMemoryDeckStore(),
            router: AIRouter.standard(governor: AICostGovernor())
        )
    }
}
