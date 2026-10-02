//
//  StudyPlanView.swift
//  StudyForge
//
//  G06 — `65_StudyPlan_Calendar_Week_{M3}` (docs/03 §G, P0). The plan's sessions grouped by day,
//  with mark-done / skip / re-plan.
//

import SwiftUI

struct StudyPlanView: View {

    @State private var viewModel: StudyPlanViewModel
    @State private var isCreating = false

    /// The session whose detail sheet is open (G08).
    @State private var selectedSession: StudySession?

    private let store: any StudyPlanStore

    init(store: any StudyPlanStore) {
        self.store = store
        _viewModel = State(initialValue: StudyPlanViewModel(store: store))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
                    .padding(Layout.screenMargin)
            } else if let plan = viewModel.plan {
                weekView(plan)
            } else {
                emptyState
            }
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isCreating = true
                } label: {
                    Label(viewModel.newPlanTitle, systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isCreating) {
            StudyPlanWizardView(store: store) {
                Task { await viewModel.load() }
            }
        }
        .sheet(item: $selectedSession) { session in
            StudySessionDetailView(viewModel: viewModel, sessionId: session.id)
        }
        .task { await viewModel.load() }
    }

    // MARK: Week

    private func weekView(_ plan: StudyPlan) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                HStack {
                    Text(viewModel.weekHeading)
                        .font(.sfTitleM)
                        .foregroundStyle(ColorTokens.textPrimary)
                    Spacer(minLength: Spacing.s2)
                    Button(viewModel.replanTitle) { Task { await viewModel.replan() } }
                        .font(.sfBodyEmph)
                        .foregroundStyle(ColorTokens.primary)
                        .frame(minHeight: Layout.minTouchTarget)
                }

                if plan.sessions.isEmpty {
                    Text(viewModel.noSessionsTitle)
                        .font(.sfCallout)
                        .foregroundStyle(ColorTokens.textSecondary)
                } else {
                    ForEach(viewModel.sessionsByDay, id: \.day) { group in
                        daySection(day: group.day, sessions: group.sessions)
                    }
                }
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private func daySection(day: Date, sessions: [StudySession]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(day.formatted(.dateTime.weekday(.wide).day().month(.abbreviated)))
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)

            VStack(spacing: Spacing.s2) {
                ForEach(sessions) { session in
                    sessionRow(session)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sessionRow(_ session: StudySession) -> some View {
        HStack(alignment: .top, spacing: Spacing.s3) {
            // A per-subject colour block, deterministic so the same subject always looks the same.
            RoundedRectangle(cornerRadius: Radius.s)
                .fill(ColorTokens.Subject.color(for: session.subject))
                .frame(width: Spacing.s1, height: Spacing.s10)

            // The text area opens the detail sheet (G08). It is a Button rather than a tap gesture
            // on the whole row so the quick-action Menu beside it stays independently tappable, and
            // so VoiceOver announces it as the control it is.
            Button { selectedSession = session } label: {
                VStack(alignment: .leading, spacing: Spacing.s1) {
                    Text(session.subject)
                        .font(.sfBodyEmph)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .strikethrough(session.status == .completed)

                    Text("\(L10n.planMinutes.string(session.estimatedMinutes)) · \(session.scheduledAt.formatted(date: .omitted, time: .shortened))")
                        .font(.sfFootnote)
                        .foregroundStyle(ColorTokens.textSecondary)

                    if session.isInProgress {
                        Text(viewModel.inProgressTitle)
                            .font(.sfCaption)
                            .foregroundStyle(ColorTokens.primary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint(viewModel.sessionDetailTitle)

            sessionAction(session)
        }
        .padding(Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
        .opacity(session.status == .skipped ? 0.6 : 1)
    }

    @ViewBuilder
    private func sessionAction(_ session: StudySession) -> some View {
        if session.status == .pending {
            Menu {
                Button(viewModel.markDoneTitle) { Task { await viewModel.markDone(session) } }
                Button(viewModel.skipTitle, role: .destructive) { Task { await viewModel.skip(session) } }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.sfBody)
                    .foregroundStyle(ColorTokens.primary)
                    .frame(minWidth: Layout.minTouchTarget, minHeight: Layout.minTouchTarget)
            }
            .accessibilityLabel(session.subject)
        } else {
            Text(session.status == .completed ? viewModel.markDoneTitle : viewModel.skipTitle)
                .font(.sfCaption)
                .foregroundStyle(ColorTokens.textTertiary)
                .frame(minHeight: Layout.minTouchTarget)
        }
    }

    // MARK: Empty

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(viewModel.emptyTitle)
                .font(.sfTitleM)
                .foregroundStyle(ColorTokens.textPrimary)
            Text(viewModel.emptyBody)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            SFPrimaryButton(title: viewModel.newPlanTitle) { isCreating = true }
                .padding(.top, Spacing.s2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Layout.screenMargin)
    }
}

// MARK: - Previews

#Preview("G06 Study plan — empty") {
    NavigationStack {
        StudyPlanView(store: InMemoryStudyPlanStore())
    }
}