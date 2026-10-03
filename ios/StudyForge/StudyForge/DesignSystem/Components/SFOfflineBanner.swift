//
//  SFOfflineBanner.swift
//  StudyForge
//
//  M06 — the offline banner (docs/03 §M, P0). The rubric names "error and feedback states" directly,
//  and this is the one that applies to the whole app rather than to a screen.
//
//  WHY IT IS A BANNER AND NOT AN ERROR SCREEN
//  ------------------------------------------
//  StudyForge is local-first: with no connection, everything the student already has still works —
//  their library, their decks, their plan. Blocking them with an error screen would be a lie about
//  what the app can do. A slim banner that says "changes will sync when you're back" is the honest
//  reading of the situation, and it is why `AppError.offline`'s own copy says the same thing.
//
//  WHY THE MONITOR IS A SEPARATE TYPE
//  ----------------------------------
//  `NWPathMonitor` owns a background queue and a callback, which is not something a view should be
//  asked to reason about. The view asks `OfflineMonitor.isOffline`; the monitor owns the plumbing.
//

import Network
import SwiftUI

/// A slim banner for the top of the app while there is no connection.
struct SFOfflineBanner: View {

    let message: String

    var body: some View {
        HStack(spacing: Spacing.s3) {
            Image(systemName: "wifi.slash")
                .font(.sfCaption)
                .accessibilityHidden(true)

            Text(message)
                .font(.sfCaption)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Layout.screenMargin)
        .padding(.vertical, Spacing.s2)
        .foregroundStyle(ColorTokens.textPrimary)
        .background(ColorTokens.warning.opacity(0.18))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(ColorTokens.warning.opacity(0.4))
                .frame(height: 1)
        }
        // One statement: the icon and the sentence are read together.
        .accessibilityElement(children: .combine)
    }
}

/// Watches connectivity so the banner can appear and disappear.
@MainActor
@Observable
final class OfflineMonitor {

    /// True while the device reports no usable path to the network.
    private(set) var isOffline = false

    @ObservationIgnored private var monitor: NWPathMonitor?
    @ObservationIgnored private let queue = DispatchQueue(label: "com.studyforge.connectivity")

    /// Starts watching. Idempotent — calling it twice does not install two monitors.
    func start() {
        guard monitor == nil else { return }

        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            let offline = path.status != .satisfied
            // The handler runs on the monitor's own queue, so the state change is hopped to the main
            // actor rather than written across threads.
            Task { @MainActor [weak self] in
                self?.isOffline = offline
            }
        }
        monitor.start(queue: queue)
        self.monitor = monitor
    }

    /// Stops watching and releases the monitor.
    func stop() {
        monitor?.cancel()
        monitor = nil
    }
}

// MARK: - Previews

#Preview("M06 Offline banner") {
    VStack(spacing: 0) {
        SFOfflineBanner(message: L10n.notificationOfflineBanner.string)
        Spacer()
    }
    .background(ColorTokens.surface)
}