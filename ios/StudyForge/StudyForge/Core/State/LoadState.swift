//
//  LoadState.swift
//  StudyForge
//
//  Every screen renders from a LoadState, so loading / empty / failed are
//  first-class states rather than afterthoughts.
//  Required by docs/04-TECH-ARCHITECTURE-COST.md §8 and docs/11-APP-IMPLEMENTATION-VIVA.md §2.1.
//

import Foundation

/// The lifecycle of any asynchronously-loaded screen content.
enum LoadState<Value> {

    /// Nothing requested yet.
    case idle

    /// A request is in flight.
    case loading

    /// Content is available.
    case loaded(Value)

    /// The request succeeded but there is genuinely nothing to show.
    /// Kept distinct from `loaded` so empty states are designed, not improvised.
    case empty

    /// The request failed with a user-presentable error.
    case failed(AppError)

    // MARK: - Convenience

    var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var error: AppError? {
        if case .failed(let error) = self { return error }
        return nil
    }

    /// Transforms the loaded value while preserving the state.
    func map<NewValue>(_ transform: (Value) -> NewValue) -> LoadState<NewValue> {
        switch self {
        case .idle: .idle
        case .loading: .loading
        case .empty: .empty
        case .failed(let error): .failed(error)
        case .loaded(let value): .loaded(transform(value))
        }
    }

    /// Builds a state from a collection, collapsing an empty collection into `.empty`.
    static func from<Element>(_ elements: [Element]) -> LoadState<[Element]> {
        elements.isEmpty ? .empty : .loaded(elements)
    }
}

extension LoadState: Equatable where Value: Equatable {
    static func == (lhs: LoadState<Value>, rhs: LoadState<Value>) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.empty, .empty):
            true
        case (.loaded(let a), .loaded(let b)):
            a == b
        case (.failed(let a), .failed(let b)):
            a == b
        default:
            false
        }
    }
}
