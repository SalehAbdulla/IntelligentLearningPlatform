//
//  StudyForgeApp.swift
//  StudyForge
//
//  App entry point.
//
//  Launch order matters here and is the reason this is not a one-liner:
//    1. Configure Firebase (a real project if the plist is present, otherwise the
//       local emulator in Development).
//    2. Build the dependency container with the services that configuration implies.
//    3. Start observing auth state.
//
//  Step 1 must happen before any other Firebase API is touched, so it is the first
//  thing this struct does.
//

import SwiftUI

@main
struct StudyForgeApp: App {

    /// Dependency container. Every service is protocol-backed and injected, so any
    /// screen can run on mock data with no backend (docs/04-TECH-ARCHITECTURE-COST.md §8).
    @State private var container = AppContainer.live(environment: .current)

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
                // Started here rather than in the initialiser so that a container built
                // for a preview or a test does not begin a background subscription.
                .task { container.start() }
        }
    }
}

