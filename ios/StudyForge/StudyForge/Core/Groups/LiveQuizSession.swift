//
//  LiveQuizSession.swift
//  StudyForge
//
//  F09's live group quiz (docs/03 §I, I12–I14; docs/05 §2.4 `liveSessions`).
//
//  WHAT IS REAL HERE AND WHAT IS SIMULATED
//  ---------------------------------------
//  The student's OWN answering, scoring and the leaderboard arithmetic are real. The other players'
//  answering is SIMULATED, because `liveSessions/{id}/answers/{uid_qIndex}` needs a realtime backend
//  that does not exist yet — see the note at the top of `StudyGroup`. The simulation is deliberately
//  DETERMINISTIC (each player has a fixed skill and answers by a rule) so the screens behave the
//  same every run and the tests can assert on them; a random simulation would look livelier and be
//  untestable.
//
//  WHY THE SESSION IS NOT PERSISTED
//  --------------------------------
//  A live quiz is a moment, not a record. Its questions come from a `Quiz` the student already saved
//  (which is where the attempt belongs), and the session itself is discarded when the screen closes.
//  Persisting it would create a second source of truth for the same questions.
//

import Foundation

/// Where a live session is in its life.
enum LiveQuizPhase: String, Sendable, Equatable {
    /// I12 — participants filling in and readying up.
    case lobby

    /// I13 — the current question is open.
    case question

    /// I13 — the answer has been shown; the room is between questions.
    case revealed

    /// I14 — the final leaderboard.
    case results
}

/// One participant in a live session.
struct LiveQuizPlayer: Identifiable, Equatable, Sendable {

    let id: String
    var name: String
    var isHost: Bool
    var isReady: Bool

    /// How many questions this player has answered correctly. The leaderboard's number.
    var score: Int

    /// Whether the player has answered the CURRENT question. Drives I13's progress strip.
    var hasAnswered: Bool

    /// The simulated accuracy this player answers with. The student's own answers are real, so their
    /// skill is never consulted.
    var skill: Double

    init(
        id: String = UUID().uuidString,
        name: String,
        isHost: Bool = false,
        isReady: Bool = false,
        score: Int = 0,
        hasAnswered: Bool = false,
        skill: Double = 0.6
    ) {
        self.id = id
        self.name = name
        self.isHost = isHost
        self.isReady = isReady
        self.score = score
        self.hasAnswered = hasAnswered
        self.skill = skill
    }
}

/// One recorded answer, used for the per-topic accuracy bars on I14.
struct LiveQuizAnswer: Equatable, Sendable {
    let playerId: String
    let questionId: String
    let isCorrect: Bool
}

/// A live group quiz in progress.
struct LiveQuizSession: Equatable, Sendable {

    /// The group this is running in, for the header.
    let groupName: String

    /// The student's own player id — how "me" is told apart in a list of participants.
    let myPlayerId: String

    /// The quiz the questions come from. Already saved by the student, so the attempt has a home.
    let quiz: Quiz

    /// How many of the quiz's questions this session runs. The host's I12 setting.
    var questionLimit: Int

    /// The questions actually in play, capped at `questionLimit`.
    var questions: [QuizQuestion]

    var players: [LiveQuizPlayer]
    var phase: LiveQuizPhase
    var currentIndex: Int

    /// Seconds left on the current question. Drives I13's timer ring.
    var secondsRemaining: Int
    var selectedOption: Int?

    /// Every answer given in this session, for the results screen's topic bars.
    var answers: [LiveQuizAnswer]

    /// How long each question stays open. One value, so the ring and the countdown cannot disagree.
    static let questionSeconds = 20

    init(
        groupName: String,
        myPlayerId: String,
        quiz: Quiz,
        questionLimit: Int,
        players: [LiveQuizPlayer]
    ) {
        self.groupName = groupName
        self.myPlayerId = myPlayerId
        self.quiz = quiz
        self.questionLimit = max(1, min(questionLimit, quiz.questions.count))
        self.questions = Array(quiz.questions.prefix(self.questionLimit))
        self.players = players
        self.phase = .lobby
        self.currentIndex = 0
        self.secondsRemaining = Self.questionSeconds
        self.selectedOption = nil
        self.answers = []
    }

    // MARK: Derived

    var currentQuestion: QuizQuestion? {
        questions.indices.contains(currentIndex) ? questions[currentIndex] : nil
    }

    var isLastQuestion: Bool { currentIndex + 1 >= questions.count }

    var myPlayer: LiveQuizPlayer? { players.first { $0.id == myPlayerId } }

    var iHaveAnswered: Bool { myPlayer?.hasAnswered ?? false }

    /// How many players have answered the current question — I13's progress strip.
    var answeredCount: Int { players.filter(\.hasAnswered).count }

    var allAnswered: Bool { players.allSatisfy(\.hasAnswered) }

    var everyoneReady: Bool { players.allSatisfy(\.isReady) }

    /// Participants ordered for the leaderboard rail: score first, then the student themselves, then
    /// name, so ties are stable rather than shuffling between renders.
    var leaderboard: [LiveQuizPlayer] {
        players.sorted {
            if $0.score != $1.score { return $0.score > $1.score }
            if $0.id == myPlayerId { return true }
            if $1.id == myPlayerId { return false }
            return $0.name < $1.name
        }
    }

    /// Per-topic accuracy across every answer given, for I14's bars.
    var topicScores: [QuizTopicScore] {
        let topicsByQuestion = Dictionary(uniqueKeysWithValues: quiz.questions.map { ($0.id, $0.topic) })
        let grouped = Dictionary(grouping: answers) { topicsByQuestion[$0.questionId] ?? "—" }
        return grouped.map { topic, answers in
            QuizTopicScore(
                topic: topic,
                correct: answers.filter(\.isCorrect).count,
                total: answers.count
            )
        }
        .sorted { $0.topic < $1.topic }
    }
}