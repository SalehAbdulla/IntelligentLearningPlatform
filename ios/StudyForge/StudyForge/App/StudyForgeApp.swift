//
//  StudyForgeApp.swift
//  StudyForge
//
//  App entry point.
//  Foundation scaffold for Sprint S0 — see docs/10-SPRINT-PLAN.md §4.
//

import SwiftUI

@main
struct StudyForgeApp: App {

    /// Dependency container. Every service is protocol-backed and injected, so any
    /// screen can run on mock data with no backend (docs/04-TECH-ARCHITECTURE-COST.md §8).
    private let container = AppContainer(environment: .dev)

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
        }
    }
}
