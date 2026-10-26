//
//  InMemoryChatModerationStore.swift
//  StudyForge
//
//  A `ChatModerationStore` that keeps every group's log in memory — previews and tests.
//
//  A REAL conformance rather than a stub, mirroring `InMemoryGroupStore` and
//  `InMemoryRecallSettingsStore`: a chat driven by it enforces the same append-only rule as the file
//  store (so a preview cannot show a state the app cannot reach), and `forceFailure` reaches the
//  failed path without inventing an unwritable file.
//

import Foundation

actor InMemoryChatModerationStore: ChatModerationStore {

    /// Group id to its log, in arrival order. Read out oldest first.
    private var log: [String: [ModerationAction]]

    /// When set, every call fails with it until cleared.
    private var failure: ChatModerationStoreError?

    init(seededWith log: [String: [ModerationAction]] = [:]) {
        self.log = log
    }

    // MARK: ChatModerationStore

    func actions(for groupId: String) async throws -> [ModerationAction] {
        try failIfForced()
        return (log[groupId] ?? []).sorted(by: ChatModerationState.isOlder)
    }

    func append(_ action: ModerationAction, to groupId: String) async throws {
        try failIfForced()

        var actions = log[groupId] ?? []
        guard !actions.contains(where: { $0.id == action.id }) else {
            throw ChatModerationStoreError.duplicateAction
        }

        actions.append(action)
        log[groupId] = actions
    }

    // MARK: Test and preview controls

    /// Forces every call to fail with `error`. Pass `nil` to restore success.
    func forceFailure(_ error: ChatModerationStoreError?) {
        failure = error
    }

    private func failIfForced() throws {
        if let failure { throw failure }
    }
}
