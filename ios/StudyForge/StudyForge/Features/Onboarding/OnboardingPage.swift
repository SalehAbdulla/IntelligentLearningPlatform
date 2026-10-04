//
//  OnboardingPage.swift
//  StudyForge
//
//  The three onboarding slides — A02, A03, A04 in docs/03 §A.
//
//  WHY THE PAGES ARE A MODEL AND NOT JUST THREE VIEWS
//  -------------------------------------------------
//  The pager needs to know how many pages exist, where it is, and which page is last —
//  and `L10nTests` proves every string resolves. Making the pages a `CaseIterable` enum
//  keeps the count and the order in one place, so adding a fourth slide cannot leave the
//  page dots or the "is this the last page?" check behind. Three literal views would
//  require the count to be repeated in the pager, which is where that bug lives.
//

import Foundation

/// One onboarding slide.
enum OnboardingPage: Int, CaseIterable, Identifiable, Sendable {

    /// A02 — `02_Onboarding_ValueProp_{M1}`. What the app is for.
    case valueProp = 0

    /// A03 — `03_Onboarding_HowItWorks_{M1}`. The four-step pipeline.
    case howItWorks = 1

    /// A04 — `04_Onboarding_AIPrivacy_{M1}`. Where the AI runs. Trust-building.
    case privacy = 2

    var id: Int { rawValue }

    /// 1-based position, for the "Page 2 of 3" announcement.
    var position: Int { rawValue + 1 }

    /// Total slides. Read from `allCases` so it cannot drift.
    static var count: Int { allCases.count }

    /// True for the final slide, which changes the primary action to "Get started".
    var isLast: Bool { self == Self.allCases.last }

    // MARK: Copy

    var title: String {
        switch self {
        case .valueProp: L10n.onboardingValuePropTitle.string
        case .howItWorks: L10n.onboardingHowItWorksTitle.string
        case .privacy: L10n.onboardingPrivacyTitle.string
        }
    }

    var body: String {
        switch self {
        case .valueProp: L10n.onboardingValuePropBody.string
        case .howItWorks: L10n.onboardingHowItWorksBody.string
        case .privacy: L10n.onboardingPrivacyBody.string
        }
    }

    /// SF Symbol for the slide's illustration.
    ///
    /// Symbols rather than bundled art: they scale with Dynamic Type, adapt to dark mode,
    /// and add nothing to the download — and unlike a placeholder illustration, a symbol
    /// never looks unfinished. The Figma frame specifies real illustrations; swapping them
    /// in later means replacing this one property.
    var symbolName: String {
        switch self {
        case .valueProp: "tray.and.arrow.down.fill"
        case .howItWorks: "square.stack.3d.up.fill"
        case .privacy: "lock.shield.fill"
        }
    }
}

/// One step of the four-step pipeline shown on A03.
struct PipelineStep: Identifiable, Sendable {

    enum Stage: Int, CaseIterable, Sendable {
        case upload = 0
        case generate = 1
        case plan = 2
        case practise = 3
    }

    let stage: Stage

    var id: Int { stage.rawValue }

    /// 1-based number shown in the diagram.
    var number: Int { stage.rawValue + 1 }

    var title: String {
        switch stage {
        case .upload: L10n.onboardingStepUploadTitle.string
        case .generate: L10n.onboardingStepGenerateTitle.string
        case .plan: L10n.onboardingStepPlanTitle.string
        case .practise: L10n.onboardingStepPractiseTitle.string
        }
    }

    var body: String {
        switch stage {
        case .upload: L10n.onboardingStepUploadBody.string
        case .generate: L10n.onboardingStepGenerateBody.string
        case .plan: L10n.onboardingStepPlanBody.string
        case .practise: L10n.onboardingStepPractiseBody.string
        }
    }

    var symbolName: String {
        switch stage {
        case .upload: "arrow.up.doc.fill"
        case .generate: "wand.and.stars"
        case .plan: "calendar.badge.clock"
        case .practise: "checkmark.circle.fill"
        }
    }

    /// All four steps, in order.
    static var all: [PipelineStep] { Stage.allCases.map(PipelineStep.init) }
}
