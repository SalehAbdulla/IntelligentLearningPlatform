//
//  GroupListView.swift
//  StudyForge
//
//  I08 + I09 — `88_GroupSpace_List_{M4}` and `89_GroupSpace_JoinByCode_{M4}` (docs/03 §I, P0). The
//  student's group revision spaces, with a create sheet and a join-by-code sheet.
//

import SwiftUI

struct GroupListView: View {

    @State private var viewModel: GroupListViewModel
    @State private var isCreating = false
    @State private var isJoining = false
    @FocusState private var isCodeFocused: Bool

    private let store: any GroupStore
    private let materials: any MaterialStore
    private let quizzes: any QuizStore
    private let me: String

    init(store: any GroupStore, materials: any MaterialStore, quizzes: any QuizStore, me: String) {
        self.store = store
        self.materials = materials
        self.quizzes = quizzes
        self.me = me
        _viewModel = State(initialValue: GroupListViewModel(store: store))
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
                groupList
            }
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(viewModel.joinButtonTitle) { isJoining = true }
            }
            ToolbarItem(placement: .primaryAction) {
                Button { isCreating = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel(viewModel.newGroupTitle)
            }
        }
        .sheet(isPresented: $isCreating) { createSheet }
        .sheet(isPresented: $isJoining) { joinSheet }
        .task { await viewModel.load() }
    }

    private var groupList: some View {
        List {
            ForEach(viewModel.groups) { group in
                NavigationLink {
                    GroupDetailView(
                        groupId: group.id,
                        store: store,
                        materials: materials,
                        quizzes: quizzes,
                        me: me
                    )
                } label: {
                    row(group)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func row(_ group: StudyGroup) -> some View {
        HStack(spacing: Spacing.s4) {
            // I08's cover gradient, seeded from the name so a group never changes colour between
            // launches.
            RoundedRectangle(cornerRadius: Radius.m)
                .fill(LinearGradient(
                    colors: coverColors(group),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: Spacing.s10, height: Spacing.s10)
                .overlay(
                    Text(String(group.name.prefix(1)).uppercased())
                        .font(.sfTitleS)
                        .foregroundStyle(ColorTokens.onError)
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(group.name)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .lineLimit(2)

                Text("\(viewModel.memberCount(group)) · \(viewModel.onlineCount(group))")
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)

                if let session = viewModel.nextSessionText(group) {
                    Text(session)
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: Spacing.s2)

            if viewModel.isLive(group) {
                Text(viewModel.liveNowTitle)
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.onError)
                    .padding(.horizontal, Spacing.s2)
                    .padding(.vertical, Spacing.s1)
                    .background(ColorTokens.error, in: .capsule)
            }
        }
        .padding(.vertical, Spacing.s2)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task { await viewModel.delete(group) }
            } label: {
                Label(L10n.commonDelete.string, systemImage: "trash")
            }
        }
    }

    private func coverColors(_ group: StudyGroup) -> [Color] {
        let palette = ColorTokens.Subject.all
        guard !palette.isEmpty else { return [ColorTokens.primary, ColorTokens.secondary] }
        let seed = abs(group.coverSeed)
        let first = palette[seed % palette.count]
        let second = palette[(seed / palette.count + 1) % palette.count]
        return [first, second]
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(viewModel.emptyTitle)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)
            Text(viewModel.emptyBody)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            SFPrimaryButton(title: viewModel.newGroupTitle) { isCreating = true }
                .padding(.top, Spacing.s2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Layout.screenMargin)
    }

    // MARK: Create

    private var createSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s6) {
                    SFTextField(
                        label: viewModel.nameLabel,
                        text: $viewModel.name,
                        placeholder: viewModel.namePlaceholder,
                        submitLabel: .done,
                        autocorrectionDisabled: false,
                        onSubmit: { Task { await create() } }
                    )

                    SFPrimaryButton(
                        title: viewModel.createTitle,
                        isLoading: viewModel.isCreating,
                        isEnabled: !viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                        action: { Task { await create() } },
                        loadingTitle: viewModel.creatingTitle
                    )
                }
                .padding(Layout.screenMargin)
                .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(ColorTokens.surface)
            .navigationTitle(viewModel.newGroupTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel.string) { isCreating = false }
                }
            }
        }
    }

    private func create() async {
        await viewModel.create(ownerName: me)
        if viewModel.error == nil { isCreating = false }
    }

    // MARK: Join (I09)

    private var joinSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s6) {
                    Text(viewModel.joinTitle)
                        .font(.sfTitleM)
                        .foregroundStyle(ColorTokens.textPrimary)

                    codeEntry

                    if let joinError = viewModel.joinError {
                        Text(joinError)
                            .font(.sfCallout)
                            .foregroundStyle(ColorTokens.error)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    SFPrimaryButton(
                        title: viewModel.joinButtonTitle,
                        isLoading: viewModel.isJoining,
                        isEnabled: viewModel.code.count == 6,
                        action: { join() },
                        loadingTitle: viewModel.joiningTitle
                    )
                }
                .padding(Layout.screenMargin)
                .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(ColorTokens.surface)
            .navigationTitle(viewModel.joinTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel.string) {
                        viewModel.clearJoinError()
                        isJoining = false
                    }
                }
            }
        }
    }

    /// I09's six boxes.
    ///
    /// One hidden `TextField` holds the real input and six boxes draw it — the standard way to get
    /// the six-box look without six focusable fields fighting over the keyboard. The keyboard is
    /// raised by tapping anywhere on the row, which is why the boxes own the tap gesture.
    private var codeEntry: some View {
        ZStack {
            TextField("", text: $viewModel.code)
                .keyboardType(.asciiCapable)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .textContentType(.oneTimeCode)
                .focused($isCodeFocused)
                .opacity(0.01)
                .frame(height: 1)
                .onChange(of: viewModel.code) { _, newValue in
                    let cleaned = newValue.uppercased().filter { $0.isLetter || $0.isNumber }
                    viewModel.code = String(cleaned.prefix(6))
                }

            HStack(spacing: Spacing.s2) {
                ForEach(0..<6, id: \.self) { index in
                    codeBox(at: index)
                }
            }
            .contentShape(.rect)
            .onTapGesture { isCodeFocused = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(viewModel.codeLabel)
        .accessibilityValue(viewModel.code.isEmpty ? viewModel.codePlaceholder : viewModel.code)
    }

    private func codeBox(at index: Int) -> some View {
        let characters = Array(viewModel.code)
        return Text(index < characters.count ? String(characters[index]) : "")
            .font(.sfMono)
            .foregroundStyle(ColorTokens.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: Spacing.s12)
            .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.m)
                    .stroke(ColorTokens.outline, lineWidth: 1)
            )
    }

    private func join() {
        Task {
            await viewModel.join(as: me)
            if viewModel.joinError == nil && viewModel.code.isEmpty { isJoining = false }
        }
    }
}

// MARK: - Previews

#Preview("I08 Groups — with groups") {
    NavigationStack {
        GroupListView(
            store: InMemoryGroupStore(seededWith: [
                StudyGroup(
                    name: "Database revision",
                    members: [
                        GroupMember(name: "Sara Ali", isOwner: true, isOnline: true),
                        GroupMember(name: "Omar", isOnline: true),
                    ],
                    messages: [GroupMessage(senderName: "Omar", text: "Anyone free at 6?")],
                    nextSessionAt: .now.addingTimeInterval(1800)
                ),
            ]),
            materials: InMemoryMaterialStore(),
            quizzes: InMemoryQuizStore(),
            me: "Sara Ali"
        )
    }
}

#Preview("I08 Groups — empty") {
    NavigationStack {
        GroupListView(
            store: InMemoryGroupStore(),
            materials: InMemoryMaterialStore(),
            quizzes: InMemoryQuizStore(),
            me: "Sara Ali"
        )
    }
}