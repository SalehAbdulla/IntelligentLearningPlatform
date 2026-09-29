//
//  AIVocabularyTests.swift
//  StudyForgeTests
//
//  Tests for the AI layer's shared vocabulary: availability reasons, task routing
//  preferences, citations and the error surface.
//
//  These are the "exhaustive enum" guards. They are cheap to write and they catch a
//  specific, likely failure: someone adds a case in Sprint 3, the compiler is happy
//  because every switch has a `default`, and a student encounters a blank message.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("AI vocabulary — availability and copy")
struct AIVocabularyTests {

    // MARK: The user never sees a blank explanation

    @Test("Every unavailability reason has complete, user-facing copy",
          arguments: AIUnavailableReason.allCases)
    func everyReasonHasCopy(reason: AIUnavailableReason) {
        #expect(reason.title.count >= 10, "\(reason) needs a real title")
        #expect(reason.message.count >= 30,
                "\(reason) needs a message that actually explains the situation")
        #expect(reason.title.first?.isUppercase == true,
                "\(reason) title should read as a sentence")
        #expect(!reason.message.contains("Error"),
                "\(reason) must not expose the word 'Error' to a student")
        #expect(!reason.message.lowercased().contains("nil"),
                "\(reason) must not leak a placeholder into production copy")
    }

    @Test("No two unavailability reasons share a title")
    func titlesAreDistinct() {
        let titles = AIUnavailableReason.allCases.map(\.title)
        #expect(Set(titles).count == titles.count,
                "a duplicated title means one reason was copy-pasted and never reviewed")
    }

    @Test("Reasons the user can act on offer a recovery action")
    func actionableReasonsOfferRecovery() {
        // These are the reasons a user can genuinely do something about.
        let actionable: [AIUnavailableReason] = [
            .simulatorUnsupported, .appleIntelligenceNotEnabled, .deviceNotEligible,
            .quotaExhausted, .offline, .modelNotReady,
        ]
        for reason in actionable {
            #expect(reason.recoveryAction != nil, "\(reason) should suggest a next step")
        }
        // And the one that is genuinely a dead end must admit it rather than
        // offering a button that does nothing.
        #expect(AIUnavailableReason.notImplemented.recoveryAction == nil)
    }

    @Test("Every tier carries a privacy note")
    func everyTierIsHonestAboutPrivacy() {
        for tier in AITier.allCases {
            #expect(tier.privacyNote.count >= 20,
                    "\(tier) must tell the user where their material goes")
        }
    }
}

@Suite("AI vocabulary — task routing policy")
struct AITaskRoutingTests {

    @Test("Every task declares a preference order containing all three tiers")
    func everyTaskRanksAllTiers() {
        for task in AITask.allCases {
            let preference = task.tierPreference
            #expect(!preference.isEmpty, "\(task) must name at least one tier")
            #expect(Set(preference).count == preference.count,
                    "\(task) lists a tier twice, so ranking is ambiguous")
            #expect(Set(preference) == Set(AITier.allCases),
                    "\(task) should account for every tier so it can always fall through")
        }
    }

    @Test("Text-transformation tasks lead with the free on-device tier")
    func textTasksLeadOnDevice() {
        for task in [AITask.summarize, .makeFlashcards, .makeQuiz, .studyPath] {
            #expect(task.tierPreference.first == .onDevice,
                    "\(task) should lead on-device — that is what keeps the app free")
        }
    }

    @Test("Answering questions leads with the cloud tier, which has the larger context")
    func coachAnswerLeadsWithCloud() {
        #expect(AITask.coachAnswer.tierPreference.first == .firebaseAI)
        #expect(AITask.coachAnswer.tierPreference.contains(.onDevice),
                "on-device must remain the offline fallback even when it is not preferred")
    }

    @Test("Multimodal tasks are the ones that actually need an image")
    func multimodalFlagsMatchThePolicy() {
        #expect(AITask.summarize.mayRequireMultimodalInput)
        #expect(AITask.makeQuiz.mayRequireMultimodalInput)
        #expect(!AITask.makeFlashcards.mayRequireMultimodalInput)
        #expect(!AITask.studyPath.mayRequireMultimodalInput)
    }

    @Test("Every routing decision explains itself")
    func decisionsAreExplainable() {
        let decisions: [AIRoutingDecision] = [
            .preferred(.onDevice),
            .fellBack(from: .onDevice, to: .firebaseAI, because: .simulatorUnsupported),
            .noneAvailable([.onDevice: .notImplemented]),
        ]
        for decision in decisions {
            #expect(!decision.explanation.isEmpty, "\(decision) must be explainable in the UI")
        }
        #expect(AIRoutingDecision.preferred(.onDevice).chosenTier == .onDevice)
        #expect(AIRoutingDecision.noneAvailable([:]).chosenTier == nil)
    }
}

// MARK: - Error surface

@Suite("AI error surface")
struct AIErrorMappingTests {

    @Test("On-device failures become the actionable on-device error")
    func onDeviceFailuresMapTogether() {
        let onDeviceReasons: [AIUnavailableReason] = [
            .simulatorUnsupported, .deviceNotEligible,
            .appleIntelligenceNotEnabled, .modelNotReady,
        ]
        for reason in onDeviceReasons {
            #expect(AIError.unavailable(reason).asAppError == .onDeviceAIUnavailable,
                    "\(reason) is an on-device problem and must say so")
        }
    }

    @Test("A quota failure carries a reset time in the future")
    func quotaErrorCarriesAResetTime() {
        guard case .aiQuotaExceeded(let resetsAt) = AIError.unavailable(.quotaExhausted).asAppError
        else {
            Issue.record("quotaExhausted must map to .aiQuotaExceeded")
            return
        }
        #expect(resetsAt > Date(), "telling the user to come back in the past is nonsense")
    }

    @Test("Offline maps to offline, not to a generic failure")
    func offlineMapsToOffline() {
        #expect(AIError.unavailable(.offline).asAppError == .offline)
    }

    @Test("Empty and over-long sources map to the material error, with a reason")
    func sourceProblemsMapToMaterialError() {
        for error in [AIError.emptySource, .sourceTooLong(tokens: 9_000, limit: 4_000)] {
            guard case .materialUnreadable(let reason) = error.asAppError else {
                Issue.record("\(error) should map to .materialUnreadable")
                return
            }
            #expect(!reason.isEmpty, "the user needs to know what was wrong with the file")
        }
    }

    @Test("A raw AI error reaching AppError.from is translated, not degraded to unknown")
    func aiErrorSurvivesTheGenericMapping() {
        // Regression guard: `AIError.asAppError` existed, but `AppError.from` did not
        // consult it, so any AI error that escaped the router became `.unknown` —
        // discarding the reason the user needed.
        #expect(AppError.from(AIError.unavailable(.offline)) == .offline)
        #expect(AppError.from(AIError.unavailable(.deviceNotEligible)) == .onDeviceAIUnavailable)
        #expect(AppError.from(AIError.unavailable(.offline)) != .unknown)
    }

    @Test("An existing AppError passes through unchanged")
    func appErrorPassesThrough() {
        #expect(AppError.from(AppError.timedOut) == .timedOut)
    }
}

// MARK: - Citations

@Suite("AI provenance")
struct AIProvenanceTests {

    @Test("A single page is cited in the singular")
    func singlePageCitation() {
        let provenance = AIProvenance(materialId: "m", pageNumbers: [7], confidence: .high)
        #expect(provenance.citationLabel == "p.7")
    }

    @Test("Multiple pages are cited as a range, using the outermost pages")
    func pageRangeCitation() {
        let provenance = AIProvenance(materialId: "m", pageNumbers: [14, 12, 13], confidence: .high)
        #expect(provenance.citationLabel == "pp.12–14",
                "the range must be ordered and contiguous-looking, not an arbitrary list")
    }

    @Test("No page numbers degrades to a generic source label rather than a wrong citation")
    func missingPagesDoNotInventACitation() {
        let provenance = AIProvenance(materialId: "m", pageNumbers: [], confidence: .low)
        #expect(provenance.citationLabel == "source",
                "inventing a page number would be worse than admitting we have none")
    }

    @Test("Only high confidence avoids the review recommendation")
    func reviewRecommendationFollowsConfidence() {
        #expect(AIConfidence.high.isReviewRecommended == false)
        #expect(AIConfidence.medium.isReviewRecommended)
        #expect(AIConfidence.low.isReviewRecommended)
    }
}

