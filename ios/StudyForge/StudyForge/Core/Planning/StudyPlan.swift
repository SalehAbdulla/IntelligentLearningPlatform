//
//  StudyPlan.swift
//  StudyForge
//
//  A generated study plan: the input the student gave the wizard, and the sessions the scheduler
//  laid out for the coming week.
//
//  WHY SESSIONS LIVE ON THE PLAN
//  -----------------------------
//  The week view needs the whole plan at once, and marking a session done is one write. Firestore
//  splits them (`studyPlans/{id}`, `sessions/{id}`, `deadlines/{id}`) for scale, but the local,
//  on-device store has no such limit — and the store seam hides a future split.
//

import Foundation

/// How hard the plan is packed. Maps to a session length.
enum StudyIntensity: String, Sendable, CaseIterable, Codable {
    case light
    case balanced
    case intensive

    /// The length of one study session in minutes.
    var sessionMinutes: Int {
        switch self {
        case .light: 30
        case .balanced: 45
        case .intensive: 60
        }
    }
}

/// What the student told the wizard. This is the reusable "recipe" a re-plan re-runs.
struct StudyPlanInput: Equatable, Sendable, Codable {
    var subjects: [String]
    var weeklyHours: Int

    /// The next exam or assignment date, when there is one. `nil` means "no deadline yet".
    var deadline: Date?

    var intensity: StudyIntensity

    init(
        subjects: [String],
        weeklyHours: Int,
        deadline: Date? = nil,
        intensity: StudyIntensity
    ) {
        self.subjects = subjects
        self.weeklyHours = weeklyHours
        self.deadline = deadline
        self.intensity = intensity
    }
}

/// The lifecycle of one session.
enum StudySessionStatus: String, Sendable, Codable {
    case pending
    case completed
    case skipped
}

/// One scheduled study block.
struct StudySession: Identifiable, Equatable, Sendable, Codable {
    let id: String
    var subject: String
    var estimatedMinutes: Int
    var scheduledAt: Date
    var status: StudySessionStatus

    init(
        id: String = UUID().uuidString,
        subject: String,
        estimatedMinutes: Int,
        scheduledAt: Date,
        status: StudySessionStatus = .pending
    ) {
        self.id = id
        self.subject = subject
        self.estimatedMinutes = estimatedMinutes
        self.scheduledAt = scheduledAt
        self.status = status
    }
}

/// A generated plan.
struct StudyPlan: Identifiable, Equatable, Sendable, Codable {
    let id: String
    var input: StudyPlanInput
    var sessions: [StudySession]
    let createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        input: StudyPlanInput,
        sessions: [StudySession],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.input = input
        self.sessions = sessions
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Sessions still awaiting attention.
    var pendingSessions: [StudySession] { sessions.filter { $0.status == .pending } }
}
