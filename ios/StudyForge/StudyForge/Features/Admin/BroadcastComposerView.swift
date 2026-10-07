//
//  BroadcastComposerView.swift
//  StudyForge
//
//  K09: `117_Admin_Broadcast_Notification_{M4}` (docs/03 section K, P1). Compose a platform
//  announcement, preview it as a push, schedule it, and send it to a segment.
//
//  WHY THE PREVIEW IS INLINE AND LIVE
//  ----------------------------------
//  K09 asks for a preview "as push notification". Rendering the title and body in a notification-shaped
//  card that updates as the admin types is the honest version: it shows the truncation and the tone the
//  student will actually see, rather than a static mockup of one.
//

import SwiftUI

struct BroadcastComposerView: View {

    @State private var viewModel: BroadcastComposerViewModel

    /// Drives the send confirmation.
    @State private var isConfirmingSend = false

    init(
        store: any BroadcastStore,
        audit: any AIConfigurationStore,
        directory: any AdminDirectoryStore,
        actorName: String
    ) {
        _viewModel = State(initialValue: BroadcastComposerViewModel(
            store: store,
            audit: audit,
            directory: directory,
            actorName: actorName
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                if let error = viewModel.error {
                    SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
                }

                audienceSection
                composeSection
                previewSection
                scheduleSection

                SFPrimaryButton(
                    title: viewModel.sendButton,
                    isEnabled: viewModel.canSend,
                    action: { isConfirmingSend = true }
                )

                if let sent = viewModel.sentConfirmation {
                    sentBanner(sent)
                }

                recentSection
            }
            .padding(Layout.screenMargin)
            .frame(maxWidth: Layout.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(ColorTokens.surface)
        .navigationTitle(viewModel.navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .alert(viewModel.confirmTitle, isPresented: $isConfirmingSend) {
            Button(L10n.commonCancel.string, role: .cancel) {}
            Button(viewModel.sendButton) { Task { await viewModel.send() } }
        } message: {
            Text(viewModel.confirmBody())
        }
    }

    // MARK: Audience

    private var audienceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(viewModel.audienceLabel)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)

            Menu {
                ForEach(AudienceSegment.allCases, id: \.self) { segment in
                    Button(viewModel.segmentTitle(segment)) { viewModel.segment = segment }
                }
            } label: {
                HStack(spacing: Spacing.s3) {
                    Text(viewModel.segmentTitle(viewModel.segment))
                        .font(.sfBodyEmph)
                        .foregroundStyle(ColorTokens.textPrimary)
                    Spacer(minLength: Spacing.s2)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.textTertiary)
                }
                .frame(minHeight: Layout.minTouchTarget)
                .padding(.horizontal, Spacing.s3)
                .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
            }
            .accessibilityLabel("\(viewModel.audienceLabel): \(viewModel.segmentTitle(viewModel.segment))")

            Text(viewModel.segmentDetail(viewModel.segment))
                .font(.sfCaption)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(viewModel.audienceSizeTitle())
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Compose

    private var composeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            SFTextField(
                label: viewModel.titleLabel,
                text: $viewModel.title,
                placeholder: viewModel.titlePlaceholder,
                error: viewModel.formError,
                autocapitalization: .sentences,
                autocorrectionDisabled: false
            )

            VStack(alignment: .leading, spacing: Spacing.s2) {
                Text(viewModel.bodyLabel)
                    .font(.sfSubhead)
                    .foregroundStyle(ColorTokens.textSecondary)
                TextField(viewModel.bodyPlaceholder, text: $viewModel.message, axis: .vertical)
                    .font(.sfBody)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .lineLimit(3...6)
                    .padding(Spacing.s3)
                    .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
                    .accessibilityLabel(viewModel.bodyLabel)
            }
        }
    }

    // MARK: Preview

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(viewModel.previewHeading)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)

            VStack(alignment: .leading, spacing: Spacing.s2) {
                HStack(spacing: Spacing.s2) {
                    Image(systemName: "bell.badge.fill")
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.primary)
                        .accessibilityHidden(true)
                    Text(L10n.appName.string)
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.textSecondary)
                    Spacer(minLength: Spacing.s2)
                    Text(viewModel.previewNow)
                        .font(.sfCaption)
                        .foregroundStyle(ColorTokens.textTertiary)
                }

                Text(viewModel.title.isEmpty ? viewModel.titlePlaceholder : viewModel.title)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textPrimary)

                if !viewModel.message.isEmpty {
                    Text(viewModel.message)
                        .font(.sfCallout)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(Spacing.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.l))
            .accessibilityElement(children: .combine)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Schedule

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Toggle(viewModel.scheduleToggle, isOn: $viewModel.isScheduling)
                .tint(ColorTokens.primary)
                .font(.sfBodyEmph)

            if viewModel.isScheduling {
                DatePicker(
                    viewModel.scheduleLabel,
                    selection: $viewModel.scheduledAt,
                    in: Date.now...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .font(.sfCallout)

                Text(viewModel.scheduleHint)
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sentBanner(_ sent: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Label(viewModel.sentTitle, systemImage: "checkmark.circle.fill")
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.successText)
            Text(sent)
                .font(.sfCaption)
                .foregroundStyle(ColorTokens.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: Recent

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(viewModel.recentHeading)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)

            if viewModel.broadcasts.isEmpty {
                Text(viewModel.emptyRecent)
                    .font(.sfCallout)
                    .foregroundStyle(ColorTokens.textSecondary)
            } else {
                ForEach(viewModel.broadcasts) { broadcast in
                    recentRow(broadcast)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func recentRow(_ broadcast: Broadcast) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            HStack(spacing: Spacing.s2) {
                Text(broadcast.title)
                    .font(.sfBodyEmph)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: Spacing.s2)
                Text(viewModel.statusTitle(broadcast))
                    .font(.sfCaption)
                    .foregroundStyle(broadcast.isSent ? ColorTokens.successText : ColorTokens.accentText)
            }
            Text(viewModel.recipientsTitle(broadcast))
                .font(.sfCaption)
                .foregroundStyle(ColorTokens.textSecondary)
            Text(viewModel.sentDateTitle(broadcast))
                .font(.sfCaption)
                .foregroundStyle(ColorTokens.textTertiary)
        }
        .padding(Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTokens.surfaceVariant, in: .rect(cornerRadius: Radius.m))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Previews

#Preview("K09 Broadcast") {
    NavigationStack {
        BroadcastComposerView(
            store: InMemoryBroadcastStore(seededWith: Broadcast.samples),
            audit: InMemoryAIConfigurationStore(auditLog: AuditEntry.samples),
            directory: InMemoryAdminDirectoryStore(seededWith: PlatformUser.samples),
            actorName: "Shahad Ashoor"
        )
    }
}

