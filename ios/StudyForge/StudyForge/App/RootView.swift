//
//  RootView.swift
//  StudyForge
//
//  The app's routing entry point. Authentication state decides the first branch;
//  role decides the tab bar within it (docs/03-SCREEN-INVENTORY.md §5).
//
//  Sprint S0 scope: route to the design-system gallery so the build is
//  demonstrable and the tokens are verifiable. S1 adds the auth flow and
//  `RoleRouter` with the role-specific tab bars.
//

import SwiftUI

struct RootView: View {

    let container: AppContainer

    var body: some View {
        Group {
            if container.session != nil {
                // S1: RoleRouter(session:) — 5-tab student spine,
                //     4-tab tutor, 4-tab admin. See docs/03 §5.
                developmentTabs
            } else {
                developmentTabs
            }
        }
        .environment(container)
        .tint(ColorTokens.primary)
    }

    /// S0 scaffolding surfaces. Both are development tools rather than product
    /// screens, but neither is dead code: the gallery verifies a token change at a
    /// glance, and the AI spike answers "which engine ran this?" when output looks
    /// wrong. S1 replaces this with `RoleRouter`.
    private var developmentTabs: some View {
        TabView {
            Tab("Design", systemImage: "paintpalette") {
                DesignSystemGallery()
            }
            Tab("AI", systemImage: "sparkles") {
                AISpikeView()
            }
        }
    }
}

#Preview("Root") {
    RootView(container: AppContainer(environment: .dev, session: .preview))
}
