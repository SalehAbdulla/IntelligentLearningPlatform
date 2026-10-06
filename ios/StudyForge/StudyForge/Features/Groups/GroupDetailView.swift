//
//  GroupDetailView.swift
//  StudyForge
//
//  I10 — `90_GroupSpace_Detail_Board_{M4}` (docs/03 §I, P0). The shared board: pinned resources, the
//  member list with presence, and the way into the chat (I11) and the live quiz (I12–I14).
//

import SwiftUI

struct GroupDetailView: View {

    @State private var viewModel: GroupDetailViewModel
    @State private var isPinning = false
    @State private var availableMaterials: [Material] = []
    @State private var isStartingQuiz = false

    private let store: any GroupStore
    private let materials: any MaterialStore
    private let quizzes: any QuizStore
    private let me: String

    init(
        groupId: String,
        store: any GroupStore,
        materials: any MaterialStore,
        quizzes: any QuizStore,
        me: String
    ) {
        self.store = store
        self.materials = materials
        self.quizzes = quizzes
        self.me = me
        _viewModel = State(initialValue: GroupDetailViewModel(
            groupId: groupId, store: store, materials: materials
        ))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
                    .padding(Layout.screenMargin)
            } else if let group = viewModel.group {
                content(group)
            }
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.group?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .sheet(isPresented: $isPinning) { pinSheet }
        .sheet(isPresented: $isStartingQuiz) {
            LiveQuizView(
                group: viewModel.group,
                me: me,
                quizStore: quizzes
            )
        }
    }

    private func content(_ group: StudyGroup) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                Text("\(viewModel.memberCountTitle(group.members.count)) · \(viewModel.onlineTitle(group.members.filter(\.isOnline).count))")
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)

                if let session = group.nextSessionAt {
                    nextSessionCard(session)
                }

                // The two primaries I10 names. Chat is a push; the quiz is a sheet, because it runs
                // to its own completion and then hands back.
                HStack(spacing: Spacing.s3) {
                    NavigationLink {
                        GroupChatView(groupId: group.id, store: store, me: me)
                    } label: {
                        Label(viewModel.chatTitle, systemImage: "bubble.left.and.bubble.right")
                            .font(.sfBodyEmph)
                            .foregroundStyle(ColorTokens.primary)
                            .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget)
                    }

                    Button {
                        isStartingQuiz = true
                    } label: {
                        Label(viewModel.startQuizTitle, systemImage: "bolt.fill")
                            .font(.sfBodyEmph)
                            .foregroundStyle(ColorTokens.primary)
                            .frame(maxWidth: .infinity, minHeight: Layout.minTouchTarget)
                    }
                    .buttonStyle(.plain)
                }

                resourcesSection
                membersSection(group)
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private func nextSessionCard(_ date: Date) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text(L10n.groupNextSession.string)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)
            Text(date.formatted(date: .abbreviated, time: .shortened))
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s4)
        .background(ColorTokens.primaryContainer, in: .rect(cornerRadius: Radius.l))
    }

    // MARK: Resources

    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            HStack {
                Text(viewModel.boardHeading)
                    .font(.sfTitleS)
                    .foregroundStyle(ColorTokens.textPrimary)
                Spacer(minLength: Spacing.s2)
                Button {
                    isPinning = true
                    Task { availableMaterials = await viewModel.availableMaterials() }
                } label: {
                    Image(systemName: "plus")
                        .font(.sfBody)
                        .foregroundStyle(ColorTokens.primary)
                        .frame(minWidth: Layout.minTouchTarget, minHeight: Layout.minTouchTarget)
                }
                .accessibilityLabel(viewModel.addResourceTitle)
            }

            if viewModel.resources.isEmpty {
                Text(viewModel.noResourcesTitle)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
            } else {
                ForEach(viewModel.resources) { resource in
                    resourceRow(resource)
                }
            }
        }
    }

    private func resourceRow(_ resource: GroupResource) -> some View {
        HStack(spacing: Spacing.s3) {
            Image(systemName: resource.kind.symbolName)
                .font(.sfBody)
                .foregroundStyle(ColorTokens.primary)
                .frame(minWidth: Spacing.s6, alignment: .leading)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(resource.title)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .lineLimit(2)
                Text(resource.pinnedBy)
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textSecondary)
            }

            Spacer(minLength: Spacing.s2)
        }
        .padding(Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task { await viewModel.unpin(resource) }
            } label: {
                Label(L10n.commonDelete.string, systemImage: "pin.slash")
            }
        }
    }

    // MARK: Members

    private func membersSection(_ group: StudyGroup) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(viewModel.membersHeading)
                .font(.sfTitleS)
                .foregroundStyle(ColorTokens.textPrimary)

            ForEach(group.members) { member in
                memberRow(member)
            }
        }
    }

    private func memberRow(_ member: GroupMember) -> some View {
        HStack(spacing: Spacing.s3) {
            // A presence dot, which is the only thing the row needs beyond the name.
            Circle()
                .fill(member.isOnline ? ColorTokens.success : ColorTokens.textTertiary)
                .frame(width: Spacing.s2, height: Spacing.s2)
                .accessibilityHidden(true)

            Image(systemName: "person.circle.fill")
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.primary)
                .accessibilityHidden(true)

            Text(member.name)
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.textPrimary)

            Spacer(minLength: Spacing.s2)
        }
        .padding(Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
        .accessibilityElement(children: .combine)
    }

    // MARK: Pin sheet

    private var pinSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s3) {
                    if availableMaterials.isEmpty {
                        Text(viewModel.noResourcesTitle)
                            .font(.sfCallout)
                            .foregroundStyle(ColorTokens.textSecondary)
                    } else {
                        ForEach(availableMaterials) { material in
                            Button {
                                Task {
                                    await viewModel.pin(material, by: me)
                                    isPinning = false
                                }
                            } label: {
                                HStack(spacing: Spacing.s3) {
                                    Image(systemName: material.source.symbolName)
                                        .font(.sfBody)
                                        .foregroundStyle(ColorTokens.primary)
                                    Text(material.title)
                                        .font(.sfBodyEmph)
                                        .foregroundStyle(ColorTokens.textPrimary)
                                        .lineLimit(2)
                                    Spacer(minLength: 0)
                                }
                                .padding(Spacing.s3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(Layout.screenMargin)
                .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(ColorTokens.surface)
            .navigationTitle(viewModel.addResourceTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel.string) { isPinning = false }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("I10 Group board") {
    NavigationStack {
        GroupDetailView(
            groupId: "g1",
            store: InMemoryGroupStore(seededWith: [
                StudyGroup(
                    id: "g1",
                    name: "Database revision",
                    members: [
                        GroupMember(name: "Sara Ali", isOwner: true, isOnline: true),
                        GroupMember(name: "Omar", isOnline: true),
                    ],
                    resources: [
                        GroupResource(kind: .material, referenceId: "m1", title: "Lecture 4 — Normalisation", pinnedBy: "Omar"),
                    ],
                    nextSessionAt: .now.addingTimeInterval(3600)
                ),
            ]),
            materials: InMemoryMaterialStore(seededWith: Material.samples),
            quizzes: InMemoryQuizStore(),
            me: "Sara Ali"
        )
    }
}