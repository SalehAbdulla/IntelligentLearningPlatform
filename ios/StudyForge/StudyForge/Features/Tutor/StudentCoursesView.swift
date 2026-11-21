import SwiftUI

struct StudentCoursesView: View {

    let container: AppContainer

    @State private var viewModel: StudentCoursesViewModel
    @FocusState private var isCodeFocused: Bool

    init(container: AppContainer) {
        self.container = container
        let session = container.session
        _viewModel = State(initialValue: StudentCoursesViewModel(
            uid: session?.id ?? "",
            studentName: session?.displayName ?? "",
            studentNumber: session.map { StudentCoursesView.studentNumber(from: $0.email) } ?? "",
            store: container.courses,
            directory: FileCourseDirectory.shared
        ))
    }

    static func studentNumber(from email: String) -> String {
        email.split(separator: "@").first.map(String.init) ?? email
    }

    var body: some View {
        ZStack {
            SummaryBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s4) {
                    Text(TutorStudioCopy.myCoursesTitle)
                        .font(.sfTitleL)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .padding(.top, Spacing.s4)
                        .accessibilityAddTraits(.isHeader)
                    joinCard
                    content
                }
                .padding(.horizontal, TutorStudioLayout.margin)
                .padding(.bottom, Spacing.s6)
                .frame(maxWidth: Layout.maxContentWidth)
                .frame(maxWidth: .infinity)
            }
            .refreshable { await viewModel.load() }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .sensoryFeedback(.success, trigger: viewModel.joinSucceeded) { _, joined in joined }
    }

    private var joinCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(TutorStudioCopy.joinTitle)
                .font(.sfSubhead)
                .foregroundStyle(ColorTokens.textPrimary)
            HStack(spacing: Spacing.s2) {
                TextField(TutorStudioCopy.joinPlaceholder, text: $viewModel.joinCode)
                    .font(.sfCallout)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .submitLabel(.join)
                    .focused($isCodeFocused)
                    .onSubmit(join)
                    .onChange(of: viewModel.joinCode) { viewModel.limitCode() }
                    .padding(.horizontal, Spacing.s3)
                    .frame(minHeight: Layout.minTouchTarget)
                    .background(SummaryGlass.fill.opacity(0.66), in: .rect(cornerRadius: Radius.m))
                Button(TutorStudioCopy.joinButton, action: join)
                    .font(.sfCallout.weight(.semibold))
                    .foregroundStyle(ColorTokens.onError)
                    .padding(.horizontal, Spacing.s4)
                    .frame(minHeight: Layout.minTouchTarget)
                    .background(viewModel.canJoin ? ColorTokens.primary : ColorTokens.outline, in: .rect(cornerRadius: Radius.m))
                    .buttonStyle(.plain)
                    .disabled(!viewModel.canJoin)
            }
            if let message = viewModel.joinMessage {
                Label(message, systemImage: viewModel.joinSucceeded ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .font(.sfFootnote)
                    .foregroundStyle(viewModel.joinSucceeded ? ColorTokens.successText : ColorTokens.warningText)
            } else {
                Text(TutorStudioCopy.joinFooter)
                    .font(.sfCaption)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
        }
        .padding(Spacing.s4)
        .summaryGlass(cornerRadius: 14, strong: true)
    }

    private func join() {
        isCodeFocused = false
        Task { _ = await viewModel.join() }
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.hasLoaded {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.s8)
        } else if let error = viewModel.error {
            SFErrorBanner(error: error, onRecover: { Task { await viewModel.load() } })
        } else if viewModel.isEmpty {
            Text(TutorStudioCopy.myCoursesEmpty)
                .font(.sfCallout)
                .foregroundStyle(ColorTokens.textSecondary)
                .padding(Spacing.s4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .summaryGlass()
        } else {
            ForEach(viewModel.courses) { joined in
                NavigationLink {
                    StudentCourseView(container: container, joined: joined)
                } label: {
                    TutorCourseCard(
                        course: joined.course,
                        detail: joined.isPending
                            ? TutorStudioCopy.awaitingApproval
                            : TutorStudioCopy.liveMaterials(joined.course.liveMaterialCount())
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview("My courses") {
    NavigationStack {
        StudentCoursesView(container: .previewing())
    }
}
