//
//  FileAIConfigurationStore.swift
//  StudyForge
//
//  The on-device store for the AI settings and the audit trail: two JSON files in Application Support.
//
//  WHY TWO FILES AND NOT ONE
//  ------------------------
//  The settings are rewritten every time an admin saves; the trail only ever grows. Keeping them
//  apart means appending an audit line never rewrites the settings document, so a crash mid-write
//  cannot lose the configuration — the same reasoning as the notification store's two files.
//

import Foundation

actor FileAIConfigurationStore: AIConfigurationStore {

    private let configurationURL: URL
    private let auditURL: URL

    /// Read once per launch, like the other file stores.
    private var configurationCache: AIConfiguration?
    private var auditCache: [AuditEntry]?

    /// - Parameter directory: where to keep the files. Injected so a test can point at a temporary
    ///   directory rather than the real Application Support folder.
    init(directory: URL? = nil) {
        let base = directory ?? Self.defaultDirectory
        self.configurationURL = base.appendingPathComponent("ai-config.json")
        self.auditURL = base.appendingPathComponent("audit-log.json")
    }

    // MARK: AIConfigurationStore

    func configuration() async throws -> AIConfiguration {
        if let configurationCache { return configurationCache }
        guard FileManager.default.fileExists(atPath: configurationURL.path) else {
            configurationCache = .default
            return .default
        }
        do {
            let data = try Data(contentsOf: configurationURL)
            let decoded = try JSONDecoder().decode(AIConfiguration.self, from: data)
            configurationCache = decoded
            return decoded
        } catch {
            throw AdminError.storageFailed
        }
    }

    func save(_ configuration: AIConfiguration) async throws {
        do {
            try FileManager.default.createDirectory(
                at: configurationURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(configuration)
            try data.write(to: configurationURL, options: .atomic)
            configurationCache = configuration
        } catch {
            throw AdminError.storageFailed
        }
    }

    func auditLog() async throws -> [AuditEntry] {
        try loadAudit().sorted { $0.createdAt > $1.createdAt }
    }

    func record(_ entry: AuditEntry) async throws {
        var entries = try loadAudit()
        entries.append(entry)
        do {
            try FileManager.default.createDirectory(
                at: auditURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(entries)
            try data.write(to: auditURL, options: .atomic)
            auditCache = entries
        } catch {
            throw AdminError.storageFailed
        }
    }

    // MARK: Storage

    private func loadAudit() throws -> [AuditEntry] {
        if let auditCache { return auditCache }
        guard FileManager.default.fileExists(atPath: auditURL.path) else {
            auditCache = []
            return []
        }
        do {
            let data = try Data(contentsOf: auditURL)
            let decoded = try JSONDecoder().decode([AuditEntry].self, from: data)
            auditCache = decoded
            return decoded
        } catch {
            throw AdminError.storageFailed
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