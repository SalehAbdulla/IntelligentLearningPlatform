//
//  PromptTemplates.swift
//  StudyForge
//
//  Every prompt the app sends, in ONE place.
//
//  Two deliberate design choices:
//
//  1. **Prompts are shared by all tiers.** Tier 0, tier 1 and tier 2 must produce
//     comparable output, otherwise the app's quality would visibly change depending
//     on which engine happened to be available.
//
//  2. **The grounding instruction is non-negotiable and stated first.** The brief
//     asks "how can uploaded materials become ACCURATE study resources?", and the
//     honest answer is that the model must be forbidden from adding anything the
//     source does not contain. A model that invents a plausible quiz answer is
//     worse than no quiz at all.
//
//  In S3 these strings move to Firestore so prompt quality can improve without an
//  app release (docs/04 §4). They are constants for now, and the seam is this file.
//

import Foundation

enum PromptTemplates {

    /// The rule that applies to every single generation. Stated before anything
    /// else so it is never buried under formatting instructions.
    private static let groundingRule = """
    Use ONLY the material provided below. Do not add facts, examples or \
    terminology that are not in it. If the material does not contain enough \
    information to answer something, say so plainly instead of guessing. \
    Never invent a citation.
    """

    /// Instructions every session starts with.
    static func instructions(for context: AIGenerationContext) -> String {
        """
        You are StudyForge, a study assistant for university students.

        \(groundingRule)

        \(context.learningStyle.promptDirective)

        \(languageDirective(context.language))
        """
    }

    private static func languageDirective(_ language: OutputLanguage) -> String {
        switch language {
        case .english:
            "Write in clear academic English at roughly a second-year undergraduate level."
        case .arabic:
            "Write in Modern Standard Arabic. Keep established technical terms in English where a direct translation would confuse the reader."
        }
    }

    /// Wraps source text so the model cannot mistake it for instructions.
    private static func source(_ context: AIGenerationContext) -> String {
        """
        --- BEGIN MATERIAL: \(context.materialId) ---
        \(context.text)
        --- END MATERIAL ---
        """
    }

    // MARK: - Per task

    static func summarize(_ request: SummaryRequest) -> String {
        let lengthGuidance = switch request.length {
        case .short: "a single takeaway sentence, then three key points"
        case .standard: "a takeaway sentence, then five to seven key points"
        case .examReady: "a takeaway sentence, then seven to ten key points, and a glossary of every technical term"
        }

        let styleGuidance = switch request.style {
        case .bullets: "Use concise bullet points."
        case .narrative: "Write flowing prose in short paragraphs, not bullets."
        case .cornell: "Separate the output into cue questions and their answers, as Cornell notes do."
        }

        return """
        Summarise the material below.

        Produce \(lengthGuidance). \(styleGuidance)

        \(source(request.context))
        """
    }

    static func flashcards(_ request: FlashcardRequest) -> String {
        let difficultyGuidance = switch request.difficulty {
        case .recall: "Test direct recall of facts and definitions."
        case .understanding: "Test understanding — why something is true, or how two ideas relate."
        case .mixed: "Mix direct recall with understanding and application."
        }

        let typeGuidance = switch request.cardType {
        case .qa: "Write each card as a question or a term to define on the front, with the answer on the back."
        case .cloze: "Write each card as a cloze deletion: the front is a sentence with ONE key term replaced by a blank, and the back is the missing term."
        case .imageOcclusion: "The source has no images, so write each front as a fully described prompt to label or identify a named part of the concept, with the answer on the back."
        case .reversible: "Write each card so it reads correctly in BOTH directions: front to back and back to front."
        }

        return """
        Create exactly \(request.count) flashcards from the material below.

        \(difficultyGuidance)
        \(typeGuidance)
        Each card must be answerable from the material alone. Keep the back to one or two sentences.

        \(source(request.context))
        """
    }

    static func quiz(_ request: QuizRequest) -> String {
        let typeGuidance = switch request.questionType {
        case .multipleChoice: "All questions are multiple choice with exactly four options."
        case .trueFalse: "All questions are true/false, expressed as two options: \"True\" and \"False\"."
        case .shortAnswer: "All questions are short answer with four plausible options."
        case .mixed: "Mix multiple choice and application questions."
        }

        return """
        Create exactly \(request.questionCount) quiz questions from the material below.

        \(typeGuidance)
        Exactly one option must be correct. The explanation must justify the answer using the material.
        Set the topic to a short label such as "third normal form" — it is used to build a revision weakness map.

        \(source(request.context))
        """
    }

    static func studyPath(_ request: StudyPathRequest) -> String {
        let weakest = request.weakTopics
            .sorted { $0.mastery < $1.mastery }
            .prefix(5)
            .map { "\($0.topic) (\(Int($0.mastery * 100))%)" }
            .joined(separator: ", ")

        return """
        A student has \(request.minutesAvailable) minutes and is weakest at: \(weakest.isEmpty ? "nothing recorded yet" : weakest).

        Build an ordered study path for that time. Put the weakest topic first. \
        Each step must name one topic and estimate its minutes so the total fits the time available. \
        Use only these activities: read, flashcards, quiz, review.
        """
    }
}
