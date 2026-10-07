//
//  StudySessionDetailView.swift
//  StudyForge
//
//  G08 — `67_StudyPlan_Session_Detail_{M3}` (docs/03 §G, P0). The session detail sheet: subject,
//  duration, schedule and status, with Start now / Mark done / Reschedule / Skip.
//
//  WHY IT READS THE SESSION BY ID
//  ------------------------------
//  An action on the sheet rewrites the plan, and the sheet must show what was stored rather than a
//  stale copy taken when it opened. So it is handed an id and asks the view model for the session,
//  exactly as the collection detail does for its collection.
//
//  WHY "TOPIC" AND "LINKED MATERIAL" ARE NOT SHOWN
//  -----------------------------------------------
//  The design's sheet lists them, but the deterministic scheduler works at SUBJECT level and
//  assigns neither — inventing a topic here would put the sheet ahead of the plan it describes.
//  They arrive with a material-aware planner; the rows below are everything the plan actually
//  knows.
//

import SwiftUI

// Accessibility: the header reads as one element naming the subject, the day and the time, and the
// in-progress chip joins that announcement rather than trailing it as a separate fragment.

struct StudySessionDetailView: View {

    private let viewModel: StudyPlanViewModel
    private let sessionId: String
    @Environment(\.dismiss) private var dismiss

    init(viewModel: StudyPlanViewModel, sessionId: String) {
        self.viewModel = viewModel
        self.sessionId = sessionId
    }

    private var session: StudySession? { viewModel.session(id: sessionId) }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let session {
                    content(session)
                        .padding(Layout.screenMargin)
                        .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
                        .frame(maxWidth: .infinity)
                }
            }
            .background(ColorTokens.surface)
            .navigationTitle(viewModel.sessionDetailTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonClose.string) { dismiss() }
                }
            }
        }
    }

    private func content(_ session: StudySession) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                Text(session.subject)
                    .font(.sfTitleL)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if session.isInProgress {
                    Text(viewModel.inProgressTitle)
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.primary)
                        .padding(.horizontal, Spacing.s2)
                        .padding(.vertical, Spacing.s1)
                        .background(ColorTokens.primaryContainer, in: .capsule)
                }
            }
            // Subject, day and time in one announcement, so the sheet opens with the session itself
            // rather than three disconnected fragments. The rows below carry the finer detail.
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                session.isInProgress
                    ? "\(session.subject), \(viewModel.inProgressTitle), \(scheduleText(session))"
                    : "\(session.subject), \(scheduleText(session))"
            )

            VStack(alignment: .leading, spacing: Spacing.s3) {
                ForEach(viewModel.detailRows(for: session)) { row in
                    SFDetailRow(row: row)
                }
            }

            actions(session)
        }
    }

    private func actions(_ session: StudySession) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            if session.status == .pending {
                SFPrimaryButton(title: viewModel.startNowTitle) {
                    Task { await viewModel.start(session) }
                }
            }

            // Mark done and Skip are finish-line actions, so they close the sheet; Reschedule moves
            // the session out from under the student, so it closes too. Start now deliberately does
            // NOT close: the sheet stays open so the started time is visible and the student can
            // then finish or skip it.
            HStack(spacing: Spacing.s5) {
                actionButton(viewModel.markDoneTitle) {
                    Task { await viewModel.markDone(session) }
                    dismiss()
                }
                actionButton(viewModel.rescheduleTitle) {
                    Task { await viewModel.reschedule(session) }
                    dismiss()
                }
                actionButton(viewModel.skipTitle, isDestructive: true) {
                    Task { await viewModel.skip(session) }
                    dismiss()
                }
            }
        }
    }

    private func actionButton(
        _ title: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.sfBodyEmph)
                .foregroundStyle(isDestructive ? ColorTokens.error : ColorTokens.primary)
                .frame(minHeight: Layout.minTouchTarget)
        }
    }

    /// The session's day and time as one string, for the header's accessibility label.
    private func scheduleText(_ session: StudySession) -> String {
        session.scheduledAt.formatted(date: .abbreviated, time: .shortened)
    }
}

// MARK: - Previews

#Preview("G08 Session detail") {
    let viewModel = StudyPlanViewModel(store: InMemoryStudyPlanStore(seededWith: [
        StudyPlan(
            id: "p1",
            input: StudyPlanInput(subjects: ["Databases"], weeklyHours: 8, intensity: .balanced),
            sessions: [
                StudySession(
                    id: "s1",
                    subject: "Databases — normalisation",
                    estimatedMinutes: 45,
                    scheduledAt: .now
                ),
            ]
        ),
    ]))
    return StudySessionDetailView(viewModel: viewModel, sessionId: "s1")
        .task { await viewModel.load() }
}