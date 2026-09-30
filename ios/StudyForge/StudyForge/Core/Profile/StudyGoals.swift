//
//  StudyGoals.swift
//  StudyForge
//
//  What a student is aiming for (B03): how much time they have, and what they want out of
//  it.
//
//  The two travel together because they are answers to one question and are saved in one
//  update — a study-time figure with no target says nothing about how hard to push, and a
//  target with no time says nothing about what is achievable. F06's planner needs both or
//  neither.
//
//  EXAM DATES ARE NOT HERE, DELIBERATELY
//  ------------------------------------
//  docs/03 §B also draws exam-date pickers on B03. They are absent because an exam date is
//  per-course and per-term: it belongs to the study plan F06 owns, not to a profile
//  document that is meant to describe the student. A date on the profile goes stale the
//  moment the term ends, and nothing would ever clear it. Recorded as a deviation in
//  docs/03 §B and as Q11 in docs/09.
//

import Foundation

/// The student's study goals, as collected by the wizard's last step.
struct StudyGoals: Sendable, Equatable {

    /// Hours per week the student intends to study.
    var weeklyStudyGoalHours: Int

    /// The grade they are aiming for.
    var targetGrade: TargetGrade
}
