//
//  DiscardGuard.swift
//  StudyForge
//
//  Rule D — ONE discard guard, one `isDirty` convention.
//
//  WHY THE CALLER OWNS THE BINDING AND THE FLAG
//  --------------------------------------------
//  "Would leaving lose work?" is a property of the screen's own model, not of a generic
//  container: the quiz knows it has answered questions, the editor knows its fields changed.
//  The guard therefore takes `isDirty` as an input and a `Binding<Bool>` for the dialog, so the
//  SAME dialog can be raised from the toolbar's Cancel button AND from a back control, and the
//  screen keeps a single source of truth. (This mirrors what `SummaryEditSheet` already did by
//  hand; the point of this file is that no screen has to do it by hand again.)
//
//  TWO PRESENTATION SHAPES, BECAUSE THEY LOSE WORK DIFFERENTLY
//  ----------------------------------------------------------
//  1. SHEET / FULL-SCREEN COVER — the risk is the interactive drag. `.interactiveDismissDisabled`
//     blocks it while dirty; the caller's Cancel button raises the dialog.
//  2. PUSHED SCREEN — the risk is the system back button and the interactive pop gesture.
//     `discardGuardBackButton` hides the system control while dirty and supplies its own, which
//     raises the dialog.
//     ⚠️ Whether hiding the back button also suppresses NavigationStack's interactive pop
//     gesture is the one mechanism this audit refuses to assume: it is confirmed on
//     `QuizTakeView` in the batch-3 pilot before the guard is rolled out anywhere else. If the
//     pilot shows the swipe still firing, the fix is a UIKit gesture-recogniser bridge, and it
//     will be reported as one rather than hidden.
//
//  COPY COMES FROM THE CALLER
//  --------------------------
//  Defaults use the shared `discard.*` strings; a screen with a better sentence ("Leave this
//  quiz?", "Your answers will be lost") overrides them. The safe action is always `.cancel`, so
//  a stray tap keeps the student where they are.
//

import SwiftUI

struct DiscardGuard: ViewModifier {

    /// True when leaving now would destroy work. When false, no dialog and no interception —
    /// a dialog on a screen with nothing to lose trains people to tap through dialogs.
    let isDirty: Bool

    /// Owned by the caller so a Cancel/back control can raise the same dialog.
    @Binding var isConfirming: Bool

    let title: String
    let message: String?
    let discardTitle: String
    let keepEditingTitle: String
    let onDiscard: () -> Void

    func body(content: Content) -> some View {
        content
            // Sheet + fullScreenCover: intercepts the interactive drag only while dirty.
            .interactiveDismissDisabled(isDirty)
            .confirmationDialog(title, isPresented: $isConfirming, titleVisibility: .visible) {
                Button(discardTitle, role: .destructive, action: onDiscard)
                Button(keepEditingTitle, role: .cancel) {}
            } message: {
                if let message {
                    Text(message)
                }
            }
    }
}

extension View {

    /// Rule D — guards a sheet or a pushed screen against losing work.
    ///
    /// - Parameters:
    ///   - isDirty: true when leaving would lose work.
    ///   - isConfirming: caller-owned dialog state, so a Cancel button can raise it too.
    ///   - onDiscard: what to do when the student confirms — usually `dismiss()`.
    func discardGuard(
        isDirty: Bool,
        isConfirming: Binding<Bool>,
        title: String = L10n.discardTitle.string,
        message: String? = L10n.discardMessage.string,
        discardTitle: String = L10n.discardConfirm.string,
        keepEditingTitle: String = L10n.discardKeepEditing.string,
        onDiscard: @escaping () -> Void
    ) -> some View {
        modifier(
            DiscardGuard(
                isDirty: isDirty,
                isConfirming: isConfirming,
                title: title,
                message: message,
                discardTitle: discardTitle,
                keepEditingTitle: keepEditingTitle,
                onDiscard: onDiscard
            )
        )
    }

    /// Rule D — the pushed-screen half: a consistent back control that guards, instead of the
    /// system one that leaves.
    ///
    /// The system back button is hidden **only while dirty**, so a clean screen keeps the normal
    /// affordances (label, swipe) and nothing changes for the common case.
    func discardGuardBackButton(
        isDirty: Bool,
        isConfirming: Binding<Bool>,
        accessibilityLabel: String = L10n.commonBack.string
    ) -> some View {
        self
            .navigationBarBackButtonHidden(isDirty)
            .toolbar {
                if isDirty {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            isConfirming.wrappedValue = true
                        } label: {
                            Label(accessibilityLabel, systemImage: "chevron.backward")
                        }
                        .accessibilityLabel(accessibilityLabel)
                        // 44 pt target, per Rule D — a toolbar item is smaller than that by
                        // default and the system will not enlarge it for us.
                        .frame(
                            minWidth: Layout.minTouchTarget,
                            minHeight: Layout.minTouchTarget,
                            alignment: .leading
                        )
                    }
                }
            }
    }
}

// MARK: - Previews

private struct DiscardGuardPreviewHost: View {

    @State private var isConfirming = false
    @State private var isDirty = true

    var body: some View {
        Form {
            Section("Your answer") {
                TextField("Answer", text: .constant("Atomic values"))
            }
            Section {
                Toggle("Unsaved changes", isOn: $isDirty)
                Button("Cancel") { isConfirming = true }
                    .buttonStyle(SFSecondaryButtonStyle(outlined: false))
            }
        }
        .discardGuard(
            isDirty: isDirty,
            isConfirming: $isConfirming,
            onDiscard: { isConfirming = false }
        )
    }
}

#Preview("Discard guard — light") {
    DiscardGuardPreviewHost()
}

#Preview("Discard guard — dark (default)") {
    DiscardGuardPreviewHost().preferredColorScheme(.dark)
}

#Preview("Discard guard — AX5") {
    DiscardGuardPreviewHost().environment(\.dynamicTypeSize, .accessibility5)
}
