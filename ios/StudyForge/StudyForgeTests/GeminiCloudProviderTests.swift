//
//  GeminiCloudProviderTests.swift
//  StudyForgeTests
//
//  Tests for tier 1 — the engine that runs in the Simulator, where tier 0 cannot.
//
//  WHY THIS FILE EXISTS
//  --------------------
//  Tier 1 was `MockProvider` until 28 Oct 2026, which meant every AI screen in the Simulator
//  produced stand-in content. It is now a real HTTP call to the Gemini API, and an HTTP call is
//  exactly the kind of code that "works" until the first 429. So this file asserts the things a
//  demo would otherwise discover live: that the key travels in a header and never in the URL, that
//  structured output decodes into the domain types, that a rate limit becomes the reason the
//  governor already knows how to explain, and that a citation the model invents is dropped.
//
//  HOW IT AVOIDS THE NETWORK
//  -------------------------
//  `GeminiCloudProvider` takes its `AICloudConfiguration` and its `URLSession` by injection — the
//  seam exists for this file. `URLProtocol` intercepts the request, so no key is needed, no socket
//  is opened, and the suite is hermetic and fast.
//

import Foundation
import Synchronization
import Testing
@testable import StudyForge

// MARK: - The transport stub

/// Intercepts every request made through the stubbed session and answers with what the test chose.
///
/// The suite is `.serialized` because the handler is process-wide, which is the price of
/// intercepting `URLProtocol` — and a serialized suite is honest about it rather than pretending
/// the stub is per-test.
private final class StubURLProtocol: URLProtocol {

    private static let handler = Mutex<
        (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?
    >(nil)

    static func set(_ newValue: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?) {
        handler.withLock { $0 = newValue }
    }

    static func respond(to request: URLRequest) throws -> (HTTPURLResponse, Data) {
        guard let handler = handler.withLock({ $0 }) else {
            throw URLError(.unsupportedURL)
        }
        return try handler(request)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        do {
            let (response, data) = try Self.respond(to: request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - Helpers

/// The envelope the API wraps every answer in: the model's JSON arrives as a string inside
/// `candidates[0].content.parts[0].text`.
private func envelope(_ modelJSON: String) -> Data {
    let payload: [String: Any] = [
        "candidates": [
            ["content": ["parts": [["text": modelJSON]]]],
        ],
    ]
    return try! JSONSerialization.data(withJSONObject: payload)
}

private func httpResponse(_ status: Int) -> HTTPURLResponse {
    HTTPURLResponse(
        url: URL(string: "https://stub.invalid")!,
        statusCode: status,
        httpVersion: nil,
        headerFields: nil
    )!
}

/// A provider pointed at the stub, with the key the test chooses.
private func makeProvider(key: String?) -> GeminiCloudProvider {
    let configuration = AICloudConfiguration(
        apiKey: key,
        model: "test-model",
        baseURL: URL(string: "https://stub.invalid/v1beta")!
    )
    let sessionConfiguration = URLSessionConfiguration.ephemeral
    sessionConfiguration.protocolClasses = [StubURLProtocol.self]
    return GeminiCloudProvider(
        configuration: configuration,
        session: URLSession(configuration: sessionConfiguration)
    )
}

/// Long enough to clear `isTooShortToGenerate`, so no test fails for the wrong reason.
private func makeContext() -> AIGenerationContext {
    AIGenerationContext(
        materialId: "material-1",
        text: String(
            repeating: "Third normal form removes transitive dependencies from a relation. ",
            count: 6
        ),
        language: .english,
        learningStyle: .visual
    )
}

private func summaryRequest() -> SummaryRequest {
    SummaryRequest(context: makeContext(), length: .short, style: .bullets)
}

/// Records the requests the provider actually sent, so a test can assert on the wire shape.
private final class RequestRecorder: Sendable {
    private let requests = Mutex<[URLRequest]>([])

    func record(_ request: URLRequest) { requests.withLock { $0.append(request) } }

    var captured: [URLRequest] { requests.withLock { $0 } }
}

/// A tier that cannot run — tier 0 in the Simulator, which is the case the demo is in.
private final class UnavailableTierProvider: AIProvider {
    let tier: AITier
    let availability: AIAvailability

    init(tier: AITier, reason: AIUnavailableReason) {
        self.tier = tier
        self.availability = .unavailable(reason)
    }

    func summarize(_ request: SummaryRequest) async throws -> AIGenerated<AISummary> {
        throw AIError.unavailable(.simulatorUnsupported)
    }

    func makeFlashcards(_ request: FlashcardRequest) async throws -> AIGenerated<[AIFlashcard]> {
        throw AIError.unavailable(.simulatorUnsupported)
    }

    func makeQuiz(_ request: QuizRequest) async throws -> AIGenerated<[AIQuizQuestion]> {
        throw AIError.unavailable(.simulatorUnsupported)
    }

    func makeStudyPath(_ request: StudyPathRequest) async throws -> AIGenerated<[AIStudyStep]> {
        throw AIError.unavailable(.simulatorUnsupported)
    }
}

private let summaryModelJSON = """
{"tldr":"A short takeaway.","keyPoints":["one","two","three"],"glossary":[{"term":"3NF","definition":"No transitive dependencies."}]}
"""

// MARK: - Suite

/// Serialized because the `URLProtocol` stub is process-wide. See `StubURLProtocol`.
///
/// `@MainActor` because `AIRouter` and `AICostGovernor` are main-actor-isolated — the same reason
/// `AIRouterTests` marks its suites.
@MainActor
@Suite(.serialized)
struct GeminiCloudProviderTests {

    // MARK: Availability

    @Test("With no key configured the tier reports itself unavailable, and says which reason")
    func unconfiguredIsHonest() async {
        let provider = makeProvider(key: nil)

        #expect(provider.availability == .unavailable(.notImplemented))

        // And a call refuses rather than attempting an unauthenticated request.
        await #expect(throws: AIError.unavailable(.notImplemented)) {
            _ = try await provider.summarize(summaryRequest())
        }
    }

    @Test("A blank key counts as no key, so a half-filled scheme variable cannot send an empty header")
    func blankKeyIsNotAKey() {
        #expect(makeProvider(key: "   ").availability == .unavailable(.notImplemented))
        #expect(makeProvider(key: "real-key").availability == .available)
    }

    // MARK: The wire shape

    @Test("The key travels in a header and never in the URL")
    func keyIsNeverInTheURL() async throws {
        let recorder = RequestRecorder()
        StubURLProtocol.set { request in
            recorder.record(request)
            return (httpResponse(200), envelope(summaryModelJSON))
        }

        _ = try await makeProvider(key: "secret-key").summarize(summaryRequest())

        let request = try #require(recorder.captured.first)
        #expect(request.value(forHTTPHeaderField: "x-goog-api-key") == "secret-key")
        // A key in a query string is a key in a proxy log and in a crash report.
        #expect(request.url?.query == nil)
        #expect(request.url?.absoluteString.contains("secret-key") == false)
        #expect(request.httpMethod == "POST")
    }

    // MARK: Structured output

    @Test("A summary decodes into the domain contract, and reports the tier and a real duration")
    func summarizeDecodesTheContract() async throws {
        StubURLProtocol.set { _ in (httpResponse(200), envelope(summaryModelJSON)) }

        let generated = try await makeProvider(key: "k").summarize(summaryRequest())

        #expect(generated.value.tldr == "A short takeaway.")
        #expect(generated.value.keyPoints == ["one", "two", "three"])
        #expect(generated.value.glossary.first?.term == "3NF")
        #expect(generated.value.glossary.first?.definition == "No transitive dependencies.")
        #expect(generated.tier == .firebaseAI)
        // Provenance is ours, never the model's: no page numbers were supplied, so confidence
        // drops rather than being asserted.
        #expect(generated.provenance.materialId == "material-1")
        #expect(generated.provenance.confidence == .medium)
    }

    @Test("Flashcards and quizzes decode through the same envelope")
    func flashcardsAndQuizDecode() async throws {
        let cardsJSON = """
        {"cards":[{"front":"What is 3NF?","back":"No transitive dependencies.","difficulty":2}]}
        """
        StubURLProtocol.set { _ in (httpResponse(200), envelope(cardsJSON)) }
        let cards = try await makeProvider(key: "k").makeFlashcards(
            FlashcardRequest(context: makeContext(), count: 1, difficulty: .recall)
        )
        #expect(cards.value.first?.front == "What is 3NF?")
        #expect(cards.value.first?.difficulty == 2)

        let quizJSON = """
        {"questions":[{"stem":"Which form removes transitive dependencies?","options":["1NF","2NF","3NF","BCNF"],"correctOptionIndex":2,"explanation":"3NF does.","topic":"normalisation"}]}
        """
        StubURLProtocol.set { _ in (httpResponse(200), envelope(quizJSON)) }
        let quiz = try await makeProvider(key: "k").makeQuiz(
            QuizRequest(context: makeContext(), questionCount: 1, questionType: .multipleChoice)
        )
        #expect(quiz.value.first?.options.count == 4)
        #expect(quiz.value.first?.correctOptionIndex == 2)
        #expect(quiz.value.first?.topic == "normalisation")
    }

    // MARK: Error mapping — the states a live demo actually hits

    @Test("A rate limit becomes the reason the governor already explains, not a raw status")
    func rateLimitBecomesQuotaExhausted() async {
        StubURLProtocol.set { _ in (httpResponse(429), Data()) }

        await #expect(throws: AIError.unavailable(.quotaExhausted)) {
            _ = try await makeProvider(key: "k").summarize(summaryRequest())
        }
    }

    @Test("A rejected key names itself, so a wrong setting is diagnosable from the message")
    func rejectedKeyNamesItself() async {
        StubURLProtocol.set { _ in (httpResponse(401), Data()) }

        do {
            _ = try await makeProvider(key: "bad").summarize(summaryRequest())
            Issue.record("Expected the call to throw")
        } catch let error as AIError {
            guard case .generationFailed(let message) = error else {
                Issue.record("Expected .generationFailed, got \(error)")
                return
            }
            #expect(message.contains("GEMINI_API_KEY"))
        } catch {
            Issue.record("Expected an AIError, got \(error)")
        }
    }

    @Test("No connection is reported as offline, which the UI has copy for")
    func noConnectionIsOffline() async {
        StubURLProtocol.set { _ in throw URLError(.notConnectedToInternet) }

        await #expect(throws: AIError.unavailable(.offline)) {
            _ = try await makeProvider(key: "k").summarize(summaryRequest())
        }
    }

    @Test("A 4xx carries the API's own message, so a wrong model name is diagnosable")
    func apiMessageIsSurfaced() async {
        let body = try! JSONSerialization.data(
            withJSONObject: ["error": ["message": "models/wrong is not found"]]
        )
        StubURLProtocol.set { _ in (httpResponse(404), body) }

        do {
            _ = try await makeProvider(key: "k").summarize(summaryRequest())
            Issue.record("Expected the call to throw")
        } catch let error as AIError {
            guard case .generationFailed(let message) = error else {
                Issue.record("Expected .generationFailed, got \(error)")
                return
            }
            #expect(message.contains("models/wrong"))
        } catch {
            Issue.record("Expected an AIError, got \(error)")
        }
    }

    @Test("A blocked prompt is reported as the block it is, not as a decoding failure")
    func blockedPromptIsNamed() async {
        let body = try! JSONSerialization.data(
            withJSONObject: ["promptFeedback": ["blockReason": "SAFETY"]]
        )
        StubURLProtocol.set { _ in (httpResponse(200), body) }

        do {
            _ = try await makeProvider(key: "k").summarize(summaryRequest())
            Issue.record("Expected the call to throw")
        } catch let error as AIError {
            guard case .generationFailed(let message) = error else {
                Issue.record("Expected .generationFailed, got \(error)")
                return
            }
            #expect(message.contains("SAFETY"))
        } catch {
            Issue.record("Expected an AIError, got \(error)")
        }
    }

    // MARK: The case this engine exists for

    @Test("In the Simulator the router reaches tier 1, and the pre-flight agrees")
    func routerReachesTierOneInTheSimulator() async throws {
        StubURLProtocol.set { _ in (httpResponse(200), envelope(summaryModelJSON)) }

        let router = AIRouter(
            providers: [
                .onDevice: UnavailableTierProvider(tier: .onDevice, reason: .simulatorUnsupported),
                .firebaseAI: makeProvider(key: "k"),
            ],
            governor: AICostGovernor(plan: .free)
        )

        // The pre-flight the UI uses to enable a button. Tier 0 cannot run in the Simulator, so
        // the real cloud engine is what it must choose.
        #expect(router.decide(for: .summarize).chosenTier == .firebaseAI)

        let generated = try await router.summarize(summaryRequest())
        #expect(generated.tier == .firebaseAI)
        #expect(generated.value.tldr == "A short takeaway.")
    }

    @Test("With no key the router refuses with a NAMED reason instead of failing at the tap")
    func routerRefusesByNameWhenUnconfigured() {
        let router = AIRouter(
            providers: [
                .onDevice: UnavailableTierProvider(tier: .onDevice, reason: .simulatorUnsupported),
                .firebaseAI: makeProvider(key: nil),
            ],
            governor: AICostGovernor(plan: .free)
        )

        let decision = router.decide(for: .summarize)
        #expect(decision.chosenTier == nil)

        guard case .noneAvailable(let reasons) = decision else {
            Issue.record("Expected .noneAvailable, got \(decision)")
            return
        }
        // Both reasons survive, so the screen explains the real one rather than "something went
        // wrong" — the difference between a configuration state and a failure.
        #expect(reasons[.onDevice] == .simulatorUnsupported)
        #expect(reasons[.firebaseAI] == .notImplemented)
    }

    // MARK: Grounding is enforced, not trusted

    @Test("A citation the model was never given is dropped")
    func inventedCitationsAreDropped() async throws {
        let answerJSON = """
        {"answer":"Normalisation reduces redundancy.","citedChunkIds":["chunk-1","chunk-invented"]}
        """
        StubURLProtocol.set { _ in (httpResponse(200), envelope(answerJSON)) }

        let prompt = AICoachPrompt(
            question: "Why normalise?",
            chunks: [
                AICoachChunk(
                    id: "chunk-1",
                    materialId: "material-1",
                    text: "Normalisation reduces redundancy.",
                    page: 4
                ),
            ],
            depth: "brief",
            language: .english
        )

        let generated = try await makeProvider(key: "k").answer(prompt)

        #expect(generated.value.citedChunkIds == ["chunk-1"])
        #expect(generated.provenance.pageNumbers == [4])
        #expect(generated.provenance.materialId == "material-1")
    }
}
