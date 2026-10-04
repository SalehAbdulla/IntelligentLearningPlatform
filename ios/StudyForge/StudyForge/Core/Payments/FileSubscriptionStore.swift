//
//  FileSubscriptionStore.swift
//  StudyForge
//
//  The on-device store for entitlements and receipts: one JSON file in Application Support.
//
//  WHY A FILE AND NOT FIRESTORE — YET
//  ----------------------------------
//  `backend/firestore.rules` already makes `subscriptions` and `payments`
//  Cloud-Function-write-only, which is correct and stays. What it does not provide is a
//  paywall that works with no project configured — the same gap the other stores close the
//  same way. This file is the local half; the rules are the server half, behind one
//  protocol.
//

import Foundation

actor FileSubscriptionStore: SubscriptionStore {

    /// The persisted shape: every account's entitlement plus every receipt, in one file.
    ///
    /// One file rather than two because both are written by the same webhook and read by
    /// the same screens; separate files would be two chances for them to disagree.
    private struct Database: Codable {
        var subscriptions: [String: Subscription] = [:]
        var receipts: [PaymentRecord] = []
    }

    private let fileURL: URL

    /// The database once read. `nil` until then, so the file is touched at most once per launch.
    private var cache: Database?

    /// - Parameter directory: where to keep the file. Injected so a test can point at a
    ///   temporary directory rather than the real Application Support folder.
    init(directory: URL? = nil) {
        let base = directory ?? Self.defaultDirectory
        self.fileURL = base.appendingPathComponent("subscriptions.json")
    }

    // MARK: SubscriptionStore

    func subscription(for uid: String) async throws -> Subscription? {
        try load().subscriptions[uid]
    }

    func upsert(_ subscription: Subscription) async throws {
        var database = try load()
        database.subscriptions[subscription.id] = subscription
        try persist(database)
    }

    func payments(for uid: String) async throws -> [PaymentRecord] {
        try load().receipts
            .filter { $0.uid == uid }
            .sorted { $0.paidAt > $1.paidAt }
    }

    func record(_ payment: PaymentRecord) async throws {
        var database = try load()
        database.receipts.append(payment)
        try persist(database)
    }

    func succeededPayment(idempotencyKey: String) async throws -> PaymentRecord? {
        try load().receipts.first {
            $0.idempotencyKey == idempotencyKey && $0.status == .succeeded
        }
    }

    // MARK: Storage

    private func load() throws -> Database {
        if let cache { return cache }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            let empty = Database()
            cache = empty
            return empty
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode(Database.self, from: data)
            cache = decoded
            return decoded
        } catch {
            throw SubscriptionError.storageFailed
        }
    }

    private func persist(_ database: Database) throws {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(database)
            try data.write(to: fileURL, options: .atomic)
            cache = database
        } catch {
            throw SubscriptionError.storageFailed
        }
    }

    /// Application Support, with a fallback.
    private static var defaultDirectory: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first
            .map { $0.appendingPathComponent("StudyForge", isDirectory: true) }
            ?? FileManager.default.temporaryDirectory
    }
}
