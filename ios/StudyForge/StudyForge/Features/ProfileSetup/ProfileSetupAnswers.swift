//
//  ProfileSetupAnswers.swift
//  StudyForge
//
//  What the profile wizard's steps collected, as they are answered.
//
//  WHY THE FLOW CARRIES THESE AT ALL
//  --------------------------------
//  Each step saves its own fields to `users/{uid}` and hands them back, and until B04
//  existed nothing read them again — the flow dropped them and moved on. B04 is a
//  confirmation screen, and a confirmation that cannot read back what it is confirming is a
//  lie: the honest summary is built from the answers the steps actually produced, not from a
//  re-read of the server and certainly not from re-deriving the form's defaults.
//
//  Every field is optional because a wizard can be opened partway — the DEBUG
//  `-profileSetupStep` hatch does exactly that. A summary built from `answers` therefore
//  states what it has and stays silent about the rest, rather than inventing the values of
//  steps that were never shown.
//

import Foundation

/// The profile-wizard answers collected so far.
struct ProfileSetupAnswers: Sendable, Equatable {

    /// B01's academic fields.
    var academic: AcademicProfile?

    /// B02's learning style.
    var learningStyle: LearningStyle?

    /// B03's study goals.
    var studyGoals: StudyGoals?

    /// Nothing answered yet — the state a wizard starts in. Named so a reader does not have
    /// to work out that `ProfileSetupAnswers()` means "the student has not answered
    /// anything".
    static let empty = ProfileSetupAnswers()
}
