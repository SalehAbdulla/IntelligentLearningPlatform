//
//  CoachHomeView.swift
//  StudyForge
//
//  H01 — `73_Coach_Home_{M2}` (docs/03 §H, P0). Suggestions, the library-scope chip, the ask bar
//  and the student's conversations.
//

import SwiftUI

struct CoachHomeView: View {

    let container: AppContainer

    @State private var viewModel: CoachHomeViewModel
    @State private var askedQuestion: String?
    @State private var showingChat = false

    init(container: AppContainer) {
        self.container = container
        _viewModel = State(initialValue: CoachHomeViewModel(
            store: container.coach,
            materials: container.materials,
            service: container.coachService
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                if let error = viewModel.error {
                    SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
                }

                header
                askBar
                suggestionList
                pathLink
                threadList
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .navigationDestination(isPresented: $showingChat) {
            CoachChatView(container: container, thread: nil, initialQuestion: askedQuestion)
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(viewModel.subtitle)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            // The scope chip: which materials are searchable. Shown rather than implied, because
            // "why didn't it find my PDF?" is answered by this one line.
            Label(viewModel.scopeLabel, systemImage: "books.vertical")
                .font(.sfFootnote)
                .foregroundStyle(ColorTokens.primary)
                .padding(.horizontal, Spacing.s3)
                .padding(.vertical, Spacing.s2)
                .background(ColorTokens.primaryContainer, in: Capsule())
        }
    }

    // MARK: Ask bar

    private var askBar: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            SFTextField(
                label: viewModel.title,
                text: $viewModel.askText,
                placeholder: viewModel.askPlaceholder,
                submitLabel: .send,
                autocorrectionDisabled: false,
                onSubmit: { ask() }
            )

            SFPrimaryButton(
                title: viewModel.askTitle,
                isEnabled: viewModel.canAsk,
                action: { ask() }
            )
        }
    }

    // MARK: Suggestions (H01)

    private var suggestionList: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            ForEach(viewModel.suggestions, id: \.self) { suggestion in
                Button {
                    ask(suggestion)
                } label: {
                    Label(suggestion, systemImage: "sparkles")
                        .font(.sfCallout)
                        .foregroundStyle(ColorTokens.primary)
                        .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)
                }
            }
        }
    }

    // MARK: Study path (H05)

    private var pathLink: some View {
        NavigationLink {
            StudyPathView(container: container)
        } label: {
            Label(viewModel.pathTitle, systemImage: "list.number")
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.primary)
                .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)
        }
    }

    // MARK: Conversations

    @ViewBuilder
    private var threadList: some View {
        if viewModel.isLoading {
            ProgressView().frame(maxWidth: .infinity)
        } else if viewModel.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                Text(viewModel.emptyTitle)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textPrimary)

                Text(viewModel.emptyBody)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.s4)
            .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
        } else {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                ForEach(viewModel.threads) { thread in
                    NavigationLink {
                        CoachChatView(container: container, thread: thread, initialQuestion: nil)
                    } label: {
                        Label(thread.title, systemImage: "bubble.left")
                            .font(.sfBody)
                            .foregroundStyle(ColorTokens.textPrimary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget, alignment: .leading)
                    }
                }
            }
        }
    }

    // MARK: Actions

    private func ask() {
        let question = viewModel.askText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }
        askedQuestion = question
        viewModel.askText = ""
        showingChat = true
    }

    private func ask(_ question: String) {
        askedQuestion = question
        showingChat = true
    }
}

// MARK: - Previews

#Preview("H01 Coach home") {
    NavigationStack {
        CoachHomeView(container: .previewing())
    }
}
