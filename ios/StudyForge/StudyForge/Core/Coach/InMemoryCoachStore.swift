//
//  InMemoryCoachStore.swift
//  StudyForge
//
//  A `CoachStore` that keeps everything in memory — previews and tests.
//
//  A REAL conformance rather than a stub, mirroring `InMemoryCourseStore`, so a screen driven by
//  it behaves exactly as it does against the file store. The forced-failure switch is what lets a
//  screen's error state be photographed without corrupting a file.
//

import Foundation

actor InMemoryCoachStore: CoachStore {

    private var conversations: [String: CoachThread]
    private var ratings: [AnswerFeedback]

    /// When set, every call fails with it until cleared.
    private var failure: CoachStoreError?

    init(threads: [CoachThread] = [], feedback: [AnswerFeedback] = []) {
        self.conversations = Dictionary(uniqueKeysWithValues: threads.map { ($0.id, $0) })
        self.ratings = feedback
    }

    // MARK: CoachStore

    func threads() async throws -> [CoachThread] {
        try failIfForced()
        return conversations.values.sorted { $0.updatedAt > $1.updatedAt }
    }

    func thread(id: String) async throws -> CoachThread? {
        try failIfForced()
        return conversations[id]
    }

    func upsert(_ thread: CoachThread) async throws {
        try failIfForced()
        conversations[thread.id] = thread
    }

    func deleteThread(id: String) async throws {
        try failIfForced()
        conversations[id] = nil
        // Cascade, so a deleted conversation cannot leave ratings pointing at messages that no
        // longer exist.
        ratings.removeAll { $0.threadId == id }
    }

    func feedback() async throws -> [AnswerFeedback] {
        try failIfForced()
        return ratings.sorted { $0.createdAt > $1.createdAt }
    }

    func record(_ feedback: AnswerFeedback) async throws {
        try failIfForced()
        // Re-rating the same message replaces the earlier rating, so a student who changes their
        // mind is not counted twice.
        ratings.removeAll { $0.messageId == feedback.messageId }
        ratings.append(feedback)
    }

    // MARK: Test and preview controls

    /// Forces every call to fail with `error`. Pass `nil` to restore success.
    func forceFailure(_ error: CoachStoreError?) {
        failure = error
    }

    private func failIfForced() throws {
        if let failure { throw failure }
    }
}
