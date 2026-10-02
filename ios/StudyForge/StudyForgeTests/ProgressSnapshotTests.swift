//
//  ProgressSnapshotTests.swift
//  StudyForgeTests
//
//  Tests for how the snapshot is assembled from the student's artefacts.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Progress snapshot")
struct ProgressSnapshotTests {

    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func card(interval: Int, reps: Int = 3) -> Flashcard {
        Flashcard(
            front: "f", back: "b",
            provenance: AIProvenance(materialId: "m", pageNumbers: [], confidence: .high),
            sr: SpacedRepetitionState(interval: interval, dueAt: now, reps: reps)
        )
    }

    private func question(id: String, topic: String) -> QuizQuestion {
        QuizQuestion(id: id, stem: "s", options: ["a", "b", "c", "d"], correctOptionIndex: 0,
                     explanation: "e", topic: topic,
                     provenance: AIProvenance(materialId: "m", pageNumbers: [], confidence: .high))
    }

    @Test("An empty input produces an empty snapshot")
    func emptyInput() {
        let snapshot = ProgressCalculator.snapshot(ProgressInput(now: now))
        #expect(snapshot.hasData == false)
        #expect(snapshot.masteryPercent == 0)
        #expect(snapshot.streakDays == 0)
    }

    @Test("Cards past the mastered interval count as mastered")
    func cardCounts() {
        let deck = Deck(title: "D", cards: [
            card(interval: 60),
            card(interval: 45),
            card(interval: 6),
        ])
        let snapshot = ProgressCalculator.snapshot(
            ProgressInput(materials: [Material(title: "m", source: .text, text: "x")], decks: [deck], now: now)
        )
        #expect(snapshot.cardsTotal == 3)
        #expect(snapshot.cardsMastered == 2)
        #expect(snapshot.hasData)
    }

    @Test("Topic mastery groups answered questions and sorts weakest first")
    func topicMastery() {
        let quiz = Quiz(
            title: "Q",
            questionType: .mixed,
            questions: [question(id: "a", topic: "keys"), question(id: "b", topic: "keys"),
                        question(id: "c", topic: "joins")],
            attempts: [
                QuizAttempt(responses: [
                    QuizResponse(questionId: "a", selectedOptionIndex: 0, isCorrect: true),
                    QuizResponse(questionId: "b", selectedOptionIndex: 1, isCorrect: false),
                    QuizResponse(questionId: "c", selectedOptionIndex: 2, isCorrect: false),
                ])
            ]
        )
        let snapshot = ProgressCalculator.snapshot(ProgressInput(quizzes: [quiz], now: now))

        #expect(snapshot.topics.first?.topic == "joins", "weakest first")
        #expect(snapshot.topics.first { $0.topic == "keys" }?.correct == 1)
        #expect(snapshot.topics.first { $0.topic == "keys" }?.total == 2)
        #expect(snapshot.weakTopics.map(\.topic) == ["joins", "keys"])
    }

    @Test("A topic answered correctly every time is not flagged as weak")
    func strongTopicIsNotWeak() {
        let quiz = Quiz(
            title: "Q",
            questionType: .mixed,
            questions: [question(id: "a", topic: "keys")],
            attempts: [QuizAttempt(responses: [QuizResponse(questionId: "a", selectedOptionIndex: 0, isCorrect: true)])]
        )
        let snapshot = ProgressCalculator.snapshot(ProgressInput(quizzes: [quiz], now: now))
        #expect(snapshot.weakTopics.isEmpty)
    }

    @Test("Subject progress comes from the plan and counts completed sessions")
    func subjectProgress() {
        let plan = StudyPlan(
            input: StudyPlanInput(subjects: ["Maths"], weeklyHours: 4, intensity: .balanced),
            sessions: [
                StudySession(subject: "Maths", estimatedMinutes: 45, scheduledAt: now, status: .completed),
                StudySession(subject: "Maths", estimatedMinutes: 45, scheduledAt: now, status: .pending),
            ]
        )
        let snapshot = ProgressCalculator.snapshot(ProgressInput(plan: plan, now: now))

        #expect(snapshot.subjects.count == 1)
        #expect(snapshot.subjects.first?.completedSessions == 1)
        #expect(snapshot.subjects.first?.totalSessions == 2)
        #expect(snapshot.subjects.first?.percent == 50)
    }

    @Test("A goal is only reported when one was set")
    func goalFraction() {
        let withoutGoal = ProgressCalculator.snapshot(ProgressInput(now: now))
        #expect(withoutGoal.goalFraction == nil)

        let withGoal = ProgressCalculator.snapshot(
            ProgressInput(
                plan: StudyPlan(
                    input: StudyPlanInput(subjects: ["M"], weeklyHours: 2, intensity: .balanced),
                    sessions: [StudySession(subject: "M", estimatedMinutes: 60,
                                            scheduledAt: now, status: .completed)]
                ),
                weeklyGoalHours: 2,
                now: now
            )
        )
        #expect(withGoal.goalFraction != nil)
    }
}