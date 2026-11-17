import SwiftUI

struct TutorReviewQueueView: View {

    let container: AppContainer

    @State private var viewModel: TutorReviewQueueViewModel
    @State private var rejecting: ReviewItem?
    @State private var isConfirmingBulk = false

    init(container: AppContainer, courseIds: [String]) {
        self.container = container
        _viewModel = State(initialValue: TutorReviewQueueViewModel(courseIds: courseIds, store: container.courses))
    }

    var body: some View {
        ZStack {
            SummaryBackdrop()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.s3) {
                        header
                        TutorFilterChips(options: TutorQueueFilter.allCases, selection: $viewModel.filter) { filter in
                            TutorStudioCopy.queueFilterTitle(filter)
                        }
                        content
                    }
                    .padding(.horizontal, TutorStudioLayout.margin)
                    .padding(.vertical, Spacing.s4)
                    .frame(maxWidth: Layout.maxContentWidth)
                    .frame(maxWidth: .infinity)
                }
                .refreshable { await viewModel.load() }

                if viewModel.canBulkApprove {
                    Button {
                        isConfirmingBulk = true
                    } label: {
                        Label(TutorStudioCopy.bulkApprove(viewModel.bulkCandidates.count), systemImage: "checkmark.seal")
                    }
                    .buttonStyle(SummaryActionButtonStyle(isPrimary: true))
                    .padding(.horizontal, TutorStudioLayout.margin)
                    .padding(.vertical, Spacing.s3)
                }
            }
        }
        .navigationTitle(TutorStudioCopy.reviewQueueTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .sheet(item: $rejecting) { item in
            TutorRejectSheet(item: item) { reason, note in
                await viewModel.reject(item, reason: reason, note: note)
            }
        }
        .confirmationDialog(
            TutorStudioCopy.bulkApprove(viewModel.bulkCandidates.count),
            isPresented: $isConfirmingBulk,
            titleVisibility: .visible
        ) {
            Button(TutorStudioCopy.approve) {
                Task { await viewModel.approveAll() }
            }
            Button(L10n.commonCancel.string, role: .cancel) {}
        } message: {
            Text(TutorStudioCopy.bulkApproveMessage)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s2) {
            Text(viewModel.pendingCount.formatted())
                .font(.sfDisplayL)
                .foregroundStyle(ColorTokens.textPrimary)
                .monospacedDigit()
            Text(TutorStudioCopy.pendingLabel)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textSecondary)
            Spacer()
            if viewModel.lowConfidenceCount > 0 {
                Text(TutorStudioCopy.lowConfidenceCount(viewModel.lowConfidenceCount))
                    .font(.sfFootnote.weight(.semibold))
                    .foregroundStyle(ColorTokens.warningText)
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.hasLoaded {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.s8)
        } else if let error = viewModel.error, viewModel.items.isEmpty {
            SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
        } else if viewModel.isEmpty {
            VStack(spacing: Spacing.s2) {
                Image(systemName: "checkmark.seal")
                    .font(.system(size: 40))
                    .foregroundStyle(ColorTokens.success)
                    .accessibilityHidden(true)
                Text(TutorStudioCopy.queueEmptyTitle)
                    .font(.sfSubhead)
                    .foregroundStyle(ColorTokens.textPrimary)
                Text(TutorStudioCopy.queueEmptyBody)
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(Spacing.s6)
            .frame(maxWidth: .infinity)
            .summaryGlass(cornerRadius: 14, strong: true)
        } else {
            if let error = viewModel.error {
                SFErrorBanner(error: error, onRecover: nil)
            }
            ForEach(viewModel.visibleItems) { item in
                NavigationLink {
                    ReviewDetailView(container: container, item: item)
                        .onDisappear { Task { await viewModel.load() } }
                } label: {
                    row(item)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    if item.status.isPending {
                        Button {
                            Task { await viewModel.approve(item) }
                        } label: {
                            Label(TutorStudioCopy.approve, systemImage: "checkmark.circle")
                        }
                        Button(role: .destructive) {
                            rejecting = item
                        } label: {
                            Label(TutorStudioCopy.rejectItem, systemImage: "xmark.octagon")
                        }
                    }
                }
            }
        }
    }

    private func row(_ item: ReviewItem) -> some View {
        HStack(alignment: .top, spacing: Spacing.s3) {
            Image(systemName: item.kind.symbolName)
                .font(.sfBody)
                .foregroundStyle(ColorTokens.primary)
                .frame(width: Spacing.s6)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(TutorStudioCopy.reviewItemTitle(TutorStudioCopy.kindTitle(item.kind), item.materialTitle))
                    .font(.sfSubhead)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(item.draft)
                    .font(.sfFootnote)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if !item.status.isPending {
                    Text(TutorStudioCopy.statusTitle(item.status))
                        .font(.sfCaption.weight(.semibold))
                        .foregroundStyle(item.status == .rejected ? ColorTokens.error : ColorTokens.successText)
                }
            }
            Spacer(minLength: 0)
            TutorConfidenceBadge(confidence: item.confidence)
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .summaryGlass(cornerRadius: 14, strong: true)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

struct TutorRejectSheet: View {

    let item: ReviewItem
    let onReject: (TutorRejectReason, String) async -> Bool

    @State private var reason: TutorRejectReason = .inaccurate
    @State private var note = ""
    @State private var isSubmitting = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(TutorStudioCopy.rejectIntro)
                        .font(.sfFootnote)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
                Section {
                    Picker(TutorStudioCopy.rejectReasonLabel, selection: $reason) {
                        ForEach(TutorRejectReason.allCases) { reason in
                            Text(reason.title).tag(reason)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section(TutorStudioCopy.rejectNoteLabel) {
                    TextField(TutorStudioCopy.rejectNotePlaceholder, text: $note, axis: .vertical)
                        .lineLimit(2...4)
                        .onChange(of: note) {
                            if note.count > TutorRejectReason.noteMaxCharacters {
                                note = String(note.prefix(TutorRejectReason.noteMaxCharacters))
                            }
                        }
                }
            }
            .navigationTitle(TutorStudioCopy.rejectItem)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel.string) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(TutorStudioCopy.rejectItem, role: .destructive) {
                        isSubmitting = true
                        Task {
                            let rejected = await onReject(reason, note)
                            isSubmitting = false
                            if rejected { dismiss() }
                        }
                    }
                    .disabled(!reason.canSubmit(note: note) || isSubmitting)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
