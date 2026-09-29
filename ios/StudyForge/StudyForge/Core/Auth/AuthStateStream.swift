//
//  AuthStateStream.swift
//  StudyForge
//
//  A tiny fan-out for authentication state, shared by every `AuthService`.
//
//  WHY THIS IS NOT OVER-ENGINEERING
//  --------------------------------
//  `AsyncStream` gives one consumer per stream. Auth state has many potential
//  observers (the root router, a profile screen, a sign-out button), so each
//  implementation would otherwise maintain its own continuation table — and each
//  would eventually get the termination case wrong, leaking a subscriber for the
//  lifetime of the app. One correct implementation is cheaper than two incorrect ones.
//
//  The subtle parts, written down so they are not re-litigated:
//   · `stream()` yields the CURRENT value immediately, so a late subscriber is never
//     stuck showing "loading" until the next change.
//   · `onTermination` removes the continuation, so a discarded view stops being fed.
//   · `send` ignores a no-op change, so SwiftUI does not re-render for nothing.
//

import Foundation
import Synchronization

final class AuthStateBroadcaster: @unchecked Sendable {

    private struct State {
        var current: AuthState
        var subscribers: [UUID: AsyncStream<AuthState>.Continuation] = [:]
    }

    private let state: Mutex<State>

    init(initial: AuthState = .unknown) {
        self.state = Mutex(State(current: initial))
    }

    /// The latest state, without subscribing.
    var current: AuthState {
        state.withLock { $0.current }
    }

    /// A new stream that emits the current state, then every change.
    func stream() -> AsyncStream<AuthState> {
        AsyncStream { continuation in
            let id = UUID()

            // Register BEFORE reading, so a change racing with subscription cannot be
            // missed between the two steps.
            let initial: AuthState = state.withLock { state in
                state.subscribers[id] = continuation
                return state.current
            }

            continuation.yield(initial)

            continuation.onTermination = { [weak self] _ in
                self?.remove(id)
            }
        }
    }

    /// Publishes a new state to every subscriber.
    func send(_ next: AuthState) {
        let subscribers: [AsyncStream<AuthState>.Continuation] = state.withLock { state in
            guard state.current != next else { return [] }
            state.current = next
            return Array(state.subscribers.values)
        }
        for continuation in subscribers {
            continuation.yield(next)
        }
    }

    /// Ends every subscriber's stream. Used when a service is torn down so subscribers
    /// do not await a value that will never arrive.
    func finish() {
        let subscribers: [AsyncStream<AuthState>.Continuation] = state.withLock { state in
            let all = Array(state.subscribers.values)
            state.subscribers.removeAll()
            return all
        }
        for continuation in subscribers {
            continuation.finish()
        }
    }

    private func remove(_ id: UUID) {
        state.withLock { $0.subscribers[id] = nil }
    }
}
