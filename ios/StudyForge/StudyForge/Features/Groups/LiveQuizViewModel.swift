//
//  LiveQuizViewModel.swift
//  StudyForge
//
//  Presentation logic for I12–I14 — the lobby, the live question and the final leaderboard, drawn as
//  three states of one sheet (the same pattern the summary flow and the flashcard generator use).
//
//  WHAT IS REAL AND WHAT IS SIMULATED
//  ----------------------------------
//  The student's own answers and score are real; the other players' answers are simulated, and the
//  rules are stated in `LiveQuizSession`. The timer, the progress strip and the leaderboard are all
//  computed from the session, so when a realtime backend lands the only thing that changes is who
//  fills in `players` — nothing on the screen moves.
//
//  WHY THE QUESTIONS COME FROM A SAVED QUIZ
//  ----------------------------------------
//  A group has no material of its own, so the honest source of questions is a quiz the student has
//  already generated — which also means the attempt has a home. The host's I12 settings are the quiz
//  and how many of its questions to run.
//

import Foundation

@MainActor
@Observable
final class LiveQuizViewModel {

    // MARK: Lobby settings

    private(set) var quizzes: [Quiz] = []
    var selectedQuizId: String?
    var questionLimit: Int = 5

    // MARK: Session

    private(set) var session: LiveQuizSession?
    private(set) var error: AppError?

    /// Whether the results screen is showing the answer review rather than the leaderboard.
    private(set) var isReviewing = false

    let groupName: String
    let me: String
    let isHost: Bool

    private let group: StudyGroup?
    private let quizStore: any QuizStore
    private let myPlayerId: String

    init(group: StudyGroup?, me: String, quizStore: any QuizStore) {
        self.group = group
        self.me = me
        self.quizStore = quizStore
        self.groupName = group?.name ?? ""
        self.isHost = group?.members.contains { $0.name == me && $0.isOwner } ?? true
        self.myPlayerId = group?.members.first { $0.name == me }?.id ?? "me"
    }

    // MARK: Derived

    var phase: LiveQuizPhase { session?.phase ?? .lobby }
    var players: [LiveQuizPlayer] { session?.players ?? [] }
    var currentQuestion: QuizQuestion? { session?.currentQuestion }
    var leaderboard: [LiveQuizPlayer] { session?.leaderboard ?? [] }
    var topicScores: [QuizTopicScore] { session?.topicScores ?? [] }
    var selectedOption: Int? { session?.selectedOption }
    var hasQuizzes: Bool { !quizzes.isEmpty }

    /// The questions in play, for the review list on I14.
    var questions: [QuizQuestion] { session?.questions ?? [] }

    /// Whether the clock is nearly out.
    var isTimeCritical: Bool { (session?.secondsRemaining ?? 99) <= 5 }

    /// The countdown, for the timer ring.
    var secondsRemaining: Int { session?.secondsRemaining ?? 0 }

    // MARK: Copy

    var lobbyTitle: String { L10n.groupQuizLobbyTitle.string }
    var readyTitle: String { L10n.groupQuizReady.string }
    var waitingTitle: String { L10n.groupQuizWaitingHost.string }
    var startTitle: String { L10n.groupQuizStart.string }
    var leaderboardTitle: String { L10n.groupQuizLeaderboard.string }
    var rematchTitle: String { L10n.groupQuizChallengeRematch.string }
    var reviewTitle: String { L10n.groupQuizReviewAnswers.string }
    var resultsTitle: String { L10n.groupQuizResultsTitle.string }
    var noQuizzesTitle: String { L10n.groupQuizNoQuizzes.string }

    func questionProgressTitle(_ index: Int, of count: Int) -> String {
        L10n.groupQuizQuestionProgress.string(index, count)
    }

    func progressStripTitle(_ answered: Int, of count: Int) -> String {
        L10n.groupQuizProgressStrip.string(answered, count)
    }

    func scoreTitle(_ score: Int) -> String { L10n.groupQuizScorePoints.string(score) }
    func timeLeftTitle(_ seconds: Int) -> String { L10n.groupQuizTimeLeft.string(seconds) }

    // MARK: Loading

    func load() async {
        do {
            quizzes = try await quizStore.all()
            if selectedQuizId == nil { selectedQuizId = quizzes.first?.id }
        } catch {
            self.error = AppError.from(error)
        }
    }

    // MARK: Lobby

    /// Marks the student ready. The others ready themselves as the lobby's clock ticks.
    func readyUp() {
        guard var session else { return }
        guard let index = session.players.firstIndex(where: { $0.id == myPlayerId }) else { return }
        session.players[index].isReady = true
        self.session = session
    }

    /// Builds the session and opens the first question. Host only.
    func start() {
        guard isHost, let quiz = quizzes.first(where: { $0.id == selectedQuizId }) else { return }
        var session = LiveQuizSession(
            groupName: groupName,
            myPlayerId: myPlayerId,
            quiz: quiz,
            questionLimit: questionLimit,
            players: makePlayers()
        )
        session.phase = .question
        session.secondsRemaining = LiveQuizSession.questionSeconds
        self.session = session
    }

    // MARK: Answering

    func answer(_ option: Int) {
        guard var session, session.phase == .question, !session.iHaveAnswered,
              let question = session.currentQuestion else { return }

        let correct = option == question.correctOptionIndex
        if let index = session.players.firstIndex(where: { $0.id == myPlayerId }) {
            session.players[index].hasAnswered = true
            if correct { session.players[index].score += 1 }
        }
        session.answers.append(LiveQuizAnswer(playerId: myPlayerId, questionId: question.id, isCorrect: correct))
        session.selectedOption = option
        simulateOthers(&session)
        session.phase = .revealed
        self.session = session
    }

    /// One tick of the lobby's or the question's clock.
    func tick() async {
        guard var session else { return }
        switch session.phase {
        case .lobby:
            // One more participant fills in per tick, so I12's "filling in" is visible.
            if let index = session.players.firstIndex(where: { $0.id != myPlayerId && !$0.isReady }) {
                session.players[index].isReady = true
                self.session = session
            }
        case .question:
            if session.secondsRemaining <= 1 {
                session.secondsRemaining = 0
                simulateOthers(&session)
                session.phase = .revealed
            } else {
                session.secondsRemaining -= 1
            }
            self.session = session
        case .revealed, .results:
            break
        }
    }

    /// Moves on from a revealed answer: the next question, or the leaderboard.
    func advance() {
        guard var session, session.phase == .revealed else { return }
        if session.isLastQuestion {
            session.phase = .results
        } else {
            session.currentIndex += 1
            session.selectedOption = nil
            session.secondsRemaining = LiveQuizSession.questionSeconds
            session.players = session.players.map {
                var player = $0
                player.hasAnswered = false
                return player
            }
            session.phase = .question
        }
        self.session = session
    }

    /// I14's rematch: scores cleared, back to question one.
    func rematch() {
        guard var session else { return }
        session.players = session.players.map {
            var player = $0
            player.score = 0
            player.hasAnswered = false
            return player
        }
        session.answers = []
        session.currentIndex = 0
        session.selectedOption = nil
        session.secondsRemaining = LiveQuizSession.questionSeconds
        session.phase = .question
        isReviewing = false
        self.session = session
    }

    func toggleReview() { isReviewing.toggle() }

    // MARK: Simulation

    private func makePlayers() -> [LiveQuizPlayer] {
        let members = group?.members ?? []
        guard !members.isEmpty else {
            return [LiveQuizPlayer(id: myPlayerId, name: me, isHost: true, isReady: true, skill: 1.0)]
        }
        return members.map { member in
            LiveQuizPlayer(
                id: member.name == me ? myPlayerId : member.id,
                name: member.name,
                isHost: member.isOwner,
                isReady: member.name == me,
                skill: member.name == me ? 1.0 : 0.7
            )
        }
    }

    /// Every other player answers, deterministically.
    ///
    /// The threshold rises with the question index, so a player with a given skill gets some right
    /// and some wrong across a session — a fixed skill against a fixed threshold would make every
    /// simulated player perfect or hopeless, and the leaderboard would never move.
    private func simulateOthers(_ session: inout LiveQuizSession) {
        guard let question = session.currentQuestion else { return }
        let threshold = Double((session.currentIndex % 4) + 1) / 5.0

        for index in session.players.indices
        where session.players[index].id != myPlayerId && !session.players[index].hasAnswered {
            let correct = session.players[index].skill >= threshold
            session.players[index].hasAnswered = true
            if correct { session.players[index].score += 1 }
            session.answers.append(
                LiveQuizAnswer(playerId: session.players[index].id, questionId: question.id, isCorrect: correct)
            )
        }
    }
}
