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

/// One course's exam date, carried on the plan rather than on the profile.
///
/// WHY IT LIVES HERE AND NOT ON THE PROFILE
/// ----------------------------------------
/// docs/03 §B draws exam-date pickers on B03 (profile setup) and they were deliberately not
/// built there: an exam date is per-course and per-term, so a date written into the profile
/// document goes stale the moment the term ends with nothing left to clear it. That is docs/09
/// Q11, and `Core/Profile/StudyGoals.swift` records the same reasoning. A plan is regenerated
/// for the term the student is actually in, so it is the one document where the date stays true.
///
/// WHY THE SUBJECT IS THE KEY
/// --------------------------
/// The wizard refuses a repeated subject (`addSubject` de-duplicates on the way in), so each
/// subject appears at most once. Its name is therefore both a unique key and exactly the join
/// the scheduler needs when it asks "has this subject an exam?" — no id to keep in step.
struct CourseExam: Equatable, Sendable, Codable {
    /// The subject's name: the identical string held in `StudyPlanInput.subjects`.
    var subject: String
    var date: Date
}

/// The geometry of the weekly availability grid (F06 Task 03, part two) — ONE place to change
/// when the design changes. The approved design fixes a one-hour slot and a 06:00–24:00 daily
/// window (docs/03 §G02's "days × time blocks"); every validity rule reads these three numbers,
/// so tightening or widening the grid cannot drift between call sites.
enum WeeklyAvailabilityGrid {
    /// One selectable slot, in minutes. Minutes everywhere — never hours, never a `Date`.
    static let slotMinutes = 60
    /// First selectable minute of the day, inclusive (06:00).
    static let dayStartMinute = 6 * 60
    /// End of the last slot, exclusive (24:00): the slot starting at 23:00 ends at 24:00.
    static let dayEndMinute = 24 * 60
    /// How many slots one day offers: (1440 − 360) ÷ 60 = 18.
    static var slotsPerDay: Int { (dayEndMinute - dayStartMinute) / slotMinutes }
}

/// What the student told the wizard. This is the reusable "recipe" a re-plan re-runs.
struct StudyPlanInput: Equatable, Sendable, Codable {
    var subjects: [String]
    var weeklyHours: Int

    /// The next exam or assignment date, when there is one. `nil` means "no deadline yet".
    var deadline: Date?

    /// Per-course exam dates. Empty means "none entered" — and also, deliberately, "this plan
    /// was written before the field existed". Those two readings have to be the same one, which
    /// is what `init(from:)` below exists to guarantee.
    var examDates: [CourseExam]

    var intensity: StudyIntensity

    /// Weekdays the student cannot study, in `Calendar` weekday numbering (1 = Sunday …
    /// 7 = Saturday). Empty means "every day is available" — and, deliberately, also "this
    /// plan was written before the field existed", exactly like `examDates` above, which is
    /// what `init(from:)` guarantees. Canonicalised on the way in (unique, sorted, in range)
    /// so the planner's iteration, a test's expectation and the stored JSON always agree.
    var blockedDays: [Int]

    init(
        subjects: [String],
        weeklyHours: Int,
        deadline: Date? = nil,
        examDates: [CourseExam] = [],
        intensity: StudyIntensity,
        blockedDays: [Int] = []
    ) {
        self.subjects = subjects
        self.weeklyHours = weeklyHours
        self.deadline = deadline
        self.examDates = examDates
        self.intensity = intensity
        self.blockedDays = Self.canonicalBlockedDays(blockedDays)
    }

    /// Sorted, unique and inside 1...7 — a `Set` would work for membership but its iteration
    /// order is not guaranteed, and an unordered field would make two equal plans encode
    /// differently. Canonicalising in ONE place (both inits) keeps every path honest.
    private static func canonicalBlockedDays(_ days: [Int]) -> [Int] {
        Array(Set(days.filter { (1...7).contains($0) })).sorted()
    }

    /// Decoded by hand, for one reason: a plan that is already on disk must still load.
    ///
    /// Swift's synthesised decoder treats a non-optional `Array` as a REQUIRED key. Every
    /// `study-plans.json` written before this feature has no `examDates` key, so a synthesised
    /// `init(from:)` would throw `keyNotFound`, `FileStudyPlanStore.load()` would translate that
    /// into `StudyPlanError.storageFailed`, and the student would lose the plan they already had
    /// in order to gain a field they never asked for. `decodeIfPresent ?? []` makes a missing key
    /// mean "none entered", which is exactly what every pre-existing plan means.
    ///
    /// `encode(to:)` stays synthesised from `CodingKeys`, so the key is always written from now on.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.subjects = try container.decode([String].self, forKey: .subjects)
        self.weeklyHours = try container.decode(Int.self, forKey: .weeklyHours)
        self.deadline = try container.decodeIfPresent(Date.self, forKey: .deadline)
        self.examDates = try container.decodeIfPresent([CourseExam].self, forKey: .examDates) ?? []
        self.intensity = try container.decode(StudyIntensity.self, forKey: .intensity)
        self.blockedDays = Self.canonicalBlockedDays(
            try container.decodeIfPresent([Int].self, forKey: .blockedDays) ?? []
        )
    }

    /// Declared rather than left to the compiler so the wire format is readable in one place
    /// here; a missing property would fail the build rather than fail silently at runtime.
    private enum CodingKeys: String, CodingKey {
        case subjects, weeklyHours, deadline, examDates, intensity, blockedDays
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

    /// When the student began the session, or `nil` while it has not been started.
    ///
    /// Separate from `status` on purpose: "started" and "finished" are different facts, and a
    /// session the student began but has not yet marked done is exactly what G08's "Start now"
    /// creates. A reschedule clears it, because a session moved to another day has not been started
    /// on the new one.
    var startedAt: Date?

    init(
        id: String = UUID().uuidString,
        subject: String,
        estimatedMinutes: Int,
        scheduledAt: Date,
        status: StudySessionStatus = .pending,
        startedAt: Date? = nil
    ) {
        self.id = id
        self.subject = subject
        self.estimatedMinutes = estimatedMinutes
        self.scheduledAt = scheduledAt
        self.status = status
        self.startedAt = startedAt
    }

    /// Started but not yet finished — what the week view marks and the detail sheet headlines.
    var isInProgress: Bool { status == .pending && startedAt != nil }
}

/// A generated plan.
///
/// F06's per-course exam dates travel on `input.examDates` — see `CourseExam` above for why
/// they live here rather than on the profile (docs/09 Q11).
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
