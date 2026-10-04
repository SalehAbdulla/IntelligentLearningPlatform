//
//  ProfileView.swift
//  StudyForge
//
//  B06 — `16_Profile_View_{M1}` (docs/03 §B, P1). Who the app thinks you are, what you are
//  studying and how much you plan to study, read back from what is already stored.
//
//  THE DESIGN'S STAT ROW AND BADGE STRIP ARE ABSENT, AND THE SCREEN SAYS WHY
//  -----------------------------------------------------------------------
//  Both need a source this project does not have yet: mastery, streaks and earned badges are
//  gamification values a Cloud Function owns, and there are no Cloud Functions (D22). The
//  weekly study time IS real, so it appears in the plan section, and the rest is stated rather
//  than faked — a row of invented zeros would be worse than an honest note.
//
//  THIS IS WHERE B07 LIVES
//  -----------------------
//  The design reaches the editor from this screen's shortcut list, so the temporary link on the
//  signed-in home now leads here instead: home → profile → edit is the designed route.
//

import SwiftUI

struct ProfileView: View {

    let container: AppContainer

    @State private var viewModel: ProfileViewModel

    init(container: AppContainer) {
        self.container = container
        _viewModel = State(
            initialValue: ProfileViewModel(
                session: container.session,
                stored: container.storedProfile
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {

                header

                if viewModel.hasStudyRows {
                    section(viewModel.studiesHeading, rows: viewModel.studyRows)
                }

                if viewModel.hasPlanRows {
                    section(viewModel.planHeading, rows: viewModel.planRows)
                }

                progressNote

                shortcutList
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Sections

    private var header: some View {
        HStack(spacing: Spacing.s4) {
            SFMonogram(name: viewModel.name)

            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(viewModel.name)
                    .font(.sfTitleM)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if !viewModel.email.isEmpty {
                    Text(viewModel.email)
                        .font(.sfCallout)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .combine)

            Spacer(minLength: 0)
        }
        // One statement: the monogram is the name's initials, so reading them out as well would
        // say the person's name twice.
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private func section(_ heading: String, rows: [DetailRow]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {

            Text(heading)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)
                .textCase(.uppercase)
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: Spacing.s3) {
                ForEach(rows) { row in
                    SFDetailRow(row: row)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.s4)
            .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
        }
    }

    /// Where the design's stat row and badge strip would go.
    ///
    /// A card rather than a silence: someone opening the profile and finding no trace of the
    /// feature would reasonably conclude it had been forgotten, and the reason it is absent is a
    /// decision worth stating.
    private var progressNote: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(viewModel.progressTitle)
                .font(.sfBodyEmph)
                .foregroundStyle(ColorTokens.textPrimary)

            Text(viewModel.progressBody)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s4)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
        .accessibilityElement(children: .combine)
    }

    private var shortcutList: some View {
        NavigationLink {
            ProfileEditView(container: container)
        } label: {
            HStack(spacing: Spacing.s3) {
                Label(viewModel.editTitle, systemImage: "pencil")
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.primary)

                Spacer(minLength: 0)

                Image(systemName: "chevron.forward")
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textTertiary)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: Layout.minTouchTarget)
        }
    }
}

// MARK: - Previews

#Preview("B06 Profile view") {
    NavigationStack {
        ProfileView(
            container: .previewing(
                session: UserSession(
                    id: "uid_preview",
                    displayName: "Sara Ali",
                    role: .student,
                    plan: .free,
                    groupIds: [],
                    email: "sara@studyforge.test",
                    isEmailVerified: true
                )
            )
        )
    }
}
