//
//  CoachPlanningService.swift
//  StudyForge
//
//  F15 — the adaptive study path: the frozen contract, its step, and the deterministic planner
//  (docs/03 §H H05; docs/02 §5, technique 3).
//
//  WHY THE PLANNER IS LOCAL AND DETERMINISTIC
//  ------------------------------------------
//  docs/02 §5 is explicit: the path is *"ordered by the planner, not the model's prose — so the
//  sequence is inspectable and testable."* That is the whole point of calling this an adaptive
//  feature rather than a chat wrapper. A model asked for "a study plan" returns a plausible
//  paragraph nobody can inspect; a planner reading mastery scores and emitting read → cards →
//  quiz with minute estimates can be unit-tested, explained in a VIVA, and trusted to put the
//  weakest topic first.
//
//  WHY `instruction` IS NOT STORED
//  -------------------------------
//  A step stores WHAT to do and to WHICH topic; the sentence shown to the student is composed by
//  the view through `L10n`. Storing prose would bake an output language into the record, so a
//  student switching to Arabic would keep an English plan.
//

import Foundation

/// What kind of activity a step is (H05's ordered cards).
enum StudyActivity: String, Sendable, Codable, CaseIterable, Identifiable {
    case read
    case flashcards
    case quiz
    case review

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .read: "book"
        case .flashcards: "rectangle.stack"
        case .quiz: "checklist"
        case .review: "arrow.clockwise"
        }
    }

    /// Where the activity sits in the read → cards → quiz → review order.
    ///
    /// A named rank rather than relying on `CaseIterable` order, so reordering the enum cannot
    /// silently reorder a student's plan.
    var rank: Int {
        switch self {
        case .read: 0
        case .flashcards: 1
        case .quiz: 2
        case .review: 3
        }
    }
}

/// One step of an adaptive study path (H05).
struct StudyStep: Identifiable, Equatable, Sendable, Codable {

    /// Stable per (topic, activity), so re-generating a path updates a step rather than
    /// duplicating it.
    let id: String

    let activity: StudyActivity

    /// The topic this step targets, matching a topic from the weakness radar.
    let topic: String

    /// Estimated minutes, scaled by how weak the topic is.
    let minutes: Int

    init(activity: StudyActivity, topic: String, minutes: Int) {
        self.id = "\(activity.rawValue):\(topic)"
        self.activity = activity
        self.topic = topic
        self.minutes = minutes
    }
}

/// Turns weak topics into an ordered path. **Frozen contract — see docs/02 §5.**
protocol CoachPlanningService: Sendable {

    /// A path for one student, weakest topic first.
    ///
    /// - Parameter weakTopics: mastery scores from F05/F07. Empty is a valid input and yields an
    ///   empty path, because "nothing is weak yet" is not a failure.
    func studyPath(for userID: String, weakTopics: [TopicScore]) async throws -> [StudyStep]
}

/// The deterministic planner: weakest topic first, read → cards → quiz, then a review.
struct LocalCoachPlanner: CoachPlanningService {

    /// The session budget the path must fit inside.
    let minutesAvailable: Int

    init(minutesAvailable: Int = 45) {
        self.minutesAvailable = max(0, minutesAvailable)
    }

    func studyPath(for userID: String, weakTopics: [TopicScore]) async throws -> [StudyStep] {
        let weakestFirst = weakTopics
            .filter { $0.mastery < 1 }
            .sorted { $0.mastery < $1.mastery }

        var steps: [StudyStep] = []
        var budget = minutesAvailable

        for topic in weakestFirst {
            for activity in Self.progression {
                let minutes = estimatedMinutes(for: activity, mastery: topic.mastery)

                // A step shorter than the floor is not worth scheduling — "study for 2 minutes" is
                // noise, and a plan padded with them is one a student stops reading.
                guard minutes <= budget, minutes >= Self.minimumStepMinutes else { break }

                steps.append(StudyStep(activity: activity, topic: topic.topic, minutes: minutes))
                budget -= minutes
            }

            if budget < Self.minimumStepMinutes { break }
        }

        // A close-out only when there is something to close out and the budget affords it.
        if budget >= Self.reviewMinutes, let first = weakestFirst.first {
            steps.append(StudyStep(
                activity: .review,
                topic: first.topic,
                minutes: Self.reviewMinutes
            ))
        }

        return steps
    }

    // MARK: Estimates

    /// The fixed order every topic is worked through (docs/02 §5 names it).
    static let progression: [StudyActivity] = [.read, .flashcards, .quiz]

    /// The shortest step worth scheduling.
    static let minimumStepMinutes = 5

    /// The closing review's fixed length.
    static let reviewMinutes = 8

    /// Base minutes per activity, before weighting by weakness.
    private static func baseMinutes(_ activity: StudyActivity) -> Int {
        switch activity {
        case .read: 15
        case .flashcards: 12
        case .quiz: 10
        case .review: 8
        }
    }

    /// How long an activity should take for a topic at this mastery.
    ///
    /// The weak get more time: a student at 20 % mastery needs longer on the same topic than one
    /// at 80 %, and a plan that schedules both identically is not adaptive. Rounded to 5 minutes so
    /// the numbers look like a plan a person would write.
    private func estimatedMinutes(for activity: StudyActivity, mastery: Double) -> Int {
        let clamped = min(1, max(0, mastery))
        let weight = 0.6 + 0.8 * (1 - clamped)          // 0.6× at mastery 1, 1.4× at mastery 0
        let raw = Double(Self.baseMinutes(activity)) * weight
        return max(Self.minimumStepMinutes, Int((raw / 5).rounded()) * 5)
    }
}
