//
//  ProfileSetupLearningStyleViewModel.swift
//  StudyForge
//
//  Presentation logic for B02 (`12_ProfileSetup_LearningStyle_{M1}`, docs/03 §B, P0).
//
//  WHY THE OPTIONS ARE BUILT HERE AND NOT IN THE VIEW
//  -------------------------------------------------
//  Each card needs a localised title AND a sample output preview, and `LearningStyle`
//  carries neither — its `displayName` is English and unlocalised, and its
//  `promptDirective` is written for a model, not a student. Pairing the enum with its copy
//  in one place keeps the view a layout, and the switch below is exhaustive, so adding a
//  learning style is a compile error here rather than a card that silently never appears.
//
//  WHY NOTHING IS PRESELECTED
//  -------------------------
//  Same reasoning as B01's university picker: a default that looks chosen would be saved as
//  if the student had chosen it. `nil` is the honest empty state, and Continue explains
//  itself rather than being inexplicably disabled.
//

import Foundation

@MainActor
@Observable
final class ProfileSetupLearningStyleViewModel {

    /// One selectable card: the style, plus the copy it shows.
    struct Option: Identifiable, Sendable, Equatable {

        let style: LearningStyle

        /// Localised name, e.g. "Visual".
        let title: String

        /// The sample output preview docs/03 §B requires. This is what makes "kinesthetic"
        /// mean something to a student who has never met the word.
        let preview: String

        var id: LearningStyle { style }
    }

    // MARK: Bound state

    /// `nil` until the student chooses. See the note above.
    var selection: LearningStyle?

    // MARK: Derived state

    private(set) var isSubmitting = false
    private(set) var error: AppError?
    private(set) var selectionError: String?

    /// The cards, in `LearningStyle.allCases` order — which is the design's order.
    let options: [Option]

    private let profile: any ProfileService
    private let onSaved: (LearningStyle) -> Void

    init(profile: any ProfileService, onSaved: @escaping (LearningStyle) -> Void) {
        self.profile = profile
        self.onSaved = onSaved
        self.options = LearningStyle.allCases.map(Self.option(for:))
    }

    // MARK: Derived

    var stepLabel: String { ProfileSetupStep.learningStyle.label }

    var isSubmitEnabled: Bool { !isSubmitting }

    func isSelected(_ style: LearningStyle) -> Bool { selection == style }

    // MARK: Actions

    func select(_ style: LearningStyle) {
        selection = style
        // The message does not outlive the mistake, exactly as on B01.
        selectionError = nil
    }

    func submit() async {
        guard !isSubmitting else { return }

        error = nil
        selectionError = nil

        guard let style = selection else {
            selectionError = L10n.profileLearningStyleError.string
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await profile.saveLearningStyle(style)
            onSaved(style)
        } catch {
            // The choice stays selected: the student's answer is not the problem.
            self.error = AppError.from(error)
        }
    }

    // MARK: Card copy

    /// The exhaustive switch is deliberate: a fifth learning style must be given copy
    /// before it can ship, so it cannot reach a student as a blank card.
    private static func option(for style: LearningStyle) -> Option {
        switch style {
        case .visual:
            Option(
                style: style,
                title: L10n.profileStyleVisualTitle.string,
                preview: L10n.profileStyleVisualPreview.string
            )
        case .verbal:
            Option(
                style: style,
                title: L10n.profileStyleVerbalTitle.string,
                preview: L10n.profileStyleVerbalPreview.string
            )
        case .readWrite:
            Option(
                style: style,
                title: L10n.profileStyleReadWriteTitle.string,
                preview: L10n.profileStyleReadWritePreview.string
            )
        case .kinesthetic:
            Option(
                style: style,
                title: L10n.profileStyleKinestheticTitle.string,
                preview: L10n.profileStyleKinestheticPreview.string
            )
        }
    }
}
