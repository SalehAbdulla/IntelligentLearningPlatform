// Standalone FoundationModels probe, run on macOS to answer the spike's core
// question from real hardware instead of inference.
//
// Build & run:
//   swiftc /tmp/fm-probe.swift -o /tmp/fm-probe -target arm64-apple-macos27.0 && /tmp/fm-probe

import Foundation
import FoundationModels

@Generable
struct ProbeCard {
    @Guide(description: "The question side")
    var front: String
    @Guide(description: "The answer side")
    var back: String
    @Guide(description: "Recall difficulty 1-3")
    var difficulty: Int
}

@main
struct Probe {
    static func main() async {
        print("=== FoundationModels on-device probe ===")

        let availability = SystemLanguageModel.default.availability
        print("availability      : \(availability)")

        switch availability {
        case .available:
            print("VERDICT           : on-device model IS available on this machine")
        case .unavailable(let reason):
            print("VERDICT           : unavailable, reason = \(reason)")
            print("(This is the path the app must degrade gracefully from.)")
            return
        }

        let source = """
        Third normal form (3NF) is a database normalisation level. A relation is in
        3NF when it is in second normal form and has no transitive dependencies: no
        non-key attribute depends on another non-key attribute. Achieving 3NF
        reduces data redundancy and update anomalies.
        """

        // 1. Plain text generation
        let clock = ContinuousClock()
        var started = clock.now
        do {
            let session = LanguageModelSession(instructions: "Answer in one short sentence.")
            let response = try await session.respond(to: "What is 3NF?")
            let elapsed = clock.now - started
            print("plain generation  : OK in \(elapsed)")
            print("  -> \(response.content.prefix(120))")
        } catch {
            print("plain generation  : FAILED, \(error)")
        }

        // 2. Guided generation (the assumption flashcards and quizzes depend on)
        started = clock.now
        do {
            let session = LanguageModelSession(
                instructions: "Use only the material provided. Do not invent facts."
            )
            let response = try await session.respond(
                to: "Create 3 flashcards from: \(source)",
                generating: [ProbeCard].self
            )
            let elapsed = clock.now - started
            let cards = response.content
            print("guided generation : OK in \(elapsed)")
            print("  cards produced  : \(cards.count)")
            for (index, card) in cards.enumerated() {
                print("  [\(index)] front=\(card.front.prefix(60))")
                print("        back=\(card.back.prefix(60))")
                print("        difficulty=\(card.difficulty)")
            }
            // Structural guarantee check: did the framework actually fill the type?
            let wellFormed = cards.allSatisfy { !$0.front.isEmpty && !$0.back.isEmpty }
            print("  structurally valid: \(wellFormed)")
        } catch {
            print("guided generation : FAILED, \(error)")
        }
    }
}
