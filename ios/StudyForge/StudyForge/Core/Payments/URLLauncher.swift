//
//  URLLauncher.swift
//  StudyForge
//
//  F13: opens the Tap hosted payment page, behind a seam.
//
//  WHY A PROTOCOL AND NOT A UIApplication CALL
//  -------------------------------------------
//  The real Tap flow is a redirect: the student pays on Tap's own page, then Tap returns them
//  to the app. `TapPaymentsGateway` opens that page, but it is an actor, not a view, so it must
//  not reach for `UIApplication` directly. Injecting the launcher keeps the gateway testable (a
//  test records the URL instead of opening it) and keeps UIKit out of the payment core.
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Opens a URL outside the app.
protocol URLLauncher: Sendable {
    /// Opens `url` however the platform does (Safari, in the real app).
    func open(_ url: URL) async
}

/// The real launcher: hands the URL to the system.
struct SystemURLLauncher: URLLauncher {
    func open(_ url: URL) async {
        #if canImport(UIKit)
        await MainActor.run {
            UIApplication.shared.open(url)
        }
        #endif
    }
}
