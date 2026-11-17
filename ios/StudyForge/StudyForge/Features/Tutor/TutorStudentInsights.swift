import Foundation

enum TutorRosterFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case atRisk
    case inactive
    case pending

    var id: String { rawValue }

    func includes(_ enrollment: Enrollment, now: Date = .now) -> Bool {
        switch self {
        case .all: enrollment.status != .removed
        case .atRisk: TutorStudentInsights.isAtRisk(enrollment, now: now)
        case .inactive: enrollment.status == .active && !enrollment.isActive(since: TutorStudentInsights.inactiveCutoff(now))
        case .pending: enrollment.status == .pending
        }
    }
}

enum TutorRosterSort: String, CaseIterable, Identifiable, Sendable {
    case name
    case mastery
    case active

    var id: String { rawValue }
}

enum TutorRiskFlag: String, CaseIterable, Identifiable, Sendable {
    case lowMastery
    case inactive
    case neverActive
    case pendingApproval

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .lowMastery: "chart.line.downtrend.xyaxis"
        case .inactive: "moon.zzz"
        case .neverActive: "person.crop.circle.badge.questionmark"
        case .pendingApproval: "person.badge.clock"
        }
    }
}

enum TutorStudentInsights {

    static let inactiveDays = 7
    static let activityWindowDays = 14
    static let atRiskMastery = 60

    static func inactiveCutoff(_ now: Date) -> Date {
        now.addingTimeInterval(-Double(inactiveDays) * 86_400)
    }

    static func riskFlags(for enrollment: Enrollment, now: Date = .now) -> [TutorRiskFlag] {
        switch enrollment.status {
        case .pending: return [.pendingApproval]
        case .removed: return []
        case .active: break
        }
        var flags: [TutorRiskFlag] = []
        if enrollment.masteryPercent < atRiskMastery { flags.append(.lowMastery) }
        if let lastActive = enrollment.lastActiveAt {
            if lastActive < inactiveCutoff(now) { flags.append(.inactive) }
        } else {
            flags.append(.neverActive)
        }
        return flags
    }

    static func isAtRisk(_ enrollment: Enrollment, now: Date = .now) -> Bool {
        riskFlags(for: enrollment, now: now).contains { $0 != .pendingApproval }
    }

    static func activityScore(_ enrollment: Enrollment, now: Date = .now) -> Double {
        guard let lastActive = enrollment.lastActiveAt else { return 0 }
        let days = max(0, now.timeIntervalSince(lastActive) / 86_400)
        return max(0, 1 - days / Double(activityWindowDays))
    }

    static func cohortAverage(_ enrollments: [Enrollment]) -> Int {
        let active = enrollments.filter { $0.status == .active }
        guard !active.isEmpty else { return 0 }
        let total = active.reduce(0) { $0 + $1.masteryPercent }
        return Int((Double(total) / Double(active.count)).rounded())
    }

    static func cohortActivity(_ enrollments: [Enrollment], now: Date = .now) -> Double {
        let active = enrollments.filter { $0.status == .active }
        guard !active.isEmpty else { return 0 }
        return active.reduce(0) { $0 + activityScore($1, now: now) } / Double(active.count)
    }

    static func roster(
        _ enrollments: [Enrollment],
        query: String,
        filter: TutorRosterFilter,
        sort: TutorRosterSort,
        now: Date = .now
    ) -> [Enrollment] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let matched = enrollments.filter { enrollment in
            guard filter.includes(enrollment, now: now) else { return false }
            guard !needle.isEmpty else { return true }
            return enrollment.studentName.lowercased().contains(needle)
                || enrollment.studentNumber.lowercased().contains(needle)
        }
        switch sort {
        case .name:
            return matched.sorted { $0.studentName.localizedCaseInsensitiveCompare($1.studentName) == .orderedAscending }
        case .mastery:
            return matched.sorted { $0.masteryPercent < $1.masteryPercent }
        case .active:
            return matched.sorted { ($0.lastActiveAt ?? .distantPast) > ($1.lastActiveAt ?? .distantPast) }
        }
    }

    static func lastActiveText(_ enrollment: Enrollment, now: Date = .now) -> String {
        guard let lastActive = enrollment.lastActiveAt else { return TutorStudioCopy.neverActive }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastActive, relativeTo: now)
    }

    static func firstName(_ name: String) -> String {
        name.split(separator: " ").first.map(String.init) ?? name
    }
}
