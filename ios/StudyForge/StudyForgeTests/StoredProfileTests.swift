//
//  StoredProfileTests.swift
//  StudyForgeTests
//
//  Decoding `users/{uid}` and deciding whether a profile is complete.
//
//  Two of these matter beyond the mechanics. `decodesTheStoredVocabulary` pins the read to
//  the STORED spelling (`readwrite`), because a decoder that used `rawValue` would silently
//  drop the learning style and mark a finished profile incomplete — sending a student back
//  through a wizard they had already completed. `wrongTypesAreIgnored` is the other: a single
//  badly-typed field must not blank the document beside it.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Stored profile")
struct StoredProfileTests {

    @Test("An empty document is an incomplete profile")
    func emptyIsIncomplete() {
        #expect(StoredProfile().isComplete == false)
        #expect(StoredProfile(document: [:]).isComplete == false)
    }

    @Test("A document with all three steps answered is complete")
    func fullIsComplete() {
        #expect(StoredProfile.preview.isComplete)
    }

    @Test("Every family of fields is required")
    func eachFamilyIsRequired() {
        // Dropping any one must make the profile incomplete: a student who answered one step
        // and was let through would never be asked for the rest.
        let full = StoredProfile.preview

        var noUniversity = full
        noUniversity.university = nil
        #expect(!noUniversity.isComplete)

        var noMajor = full
        noMajor.major = nil
        #expect(!noMajor.isComplete)

        var noYear = full
        noYear.year = nil
        #expect(!noYear.isComplete)

        var noCourses = full
        noCourses.courseIds = []
        #expect(!noCourses.isComplete)

        var noStyle = full
        noStyle.learningStyle = nil
        #expect(!noStyle.isComplete)

        var noHours = full
        noHours.weeklyStudyGoalHours = nil
        #expect(!noHours.isComplete)

        var noGrade = full
        noGrade.targetGrade = nil
        #expect(!noGrade.isComplete)
    }

    @Test("The wire vocabulary is decoded through storageValue, not rawValue")
    func decodesTheStoredVocabulary() {
        // The stored spelling is `readwrite`; the Swift case is `readWrite`. Using `rawValue`
        // here would drop the style.
        let profile = StoredProfile(document: [
            ProfileField.learningStyle: "readwrite",
            ProfileField.targetGrade: "B",
        ])

        #expect(profile.learningStyle == .readWrite)
        #expect(profile.targetGrade == .b)
    }

    @Test("A value this build does not recognise decodes to nil, and its neighbours survive")
    func unknownValuesAreNil() {
        let profile = StoredProfile(document: [
            ProfileField.university: "University of Bahrain",
            ProfileField.learningStyle: "kinaesthetic",   // a spelling from some other build
            ProfileField.targetGrade: "A*",               // not on this scale
        ])

        #expect(profile.learningStyle == nil)
        #expect(profile.targetGrade == nil)
        #expect(profile.university == "University of Bahrain")
    }

    @Test("A wrongly-typed field is ignored rather than taking the read down with it")
    func wrongTypesAreIgnored() {
        let profile = StoredProfile(document: [
            ProfileField.year: "3",                   // stored as a string
            ProfileField.courseIds: "IT8108",         // stored as a string, not an array
            ProfileField.weeklyStudyGoalHours: 12.5,  // not a whole number
            ProfileField.major: "Physics",
        ])

        #expect(profile.year == nil)
        #expect(profile.courseIds == nil)
        #expect(profile.weeklyStudyGoalHours == nil)
        #expect(profile.major == "Physics")
        #expect(!profile.isComplete)
    }

    @Test("A step reads back as its write type, or not at all")
    func stepsReadBackAllOrNothing() {
        #expect(StoredProfile.preview.academicProfile != nil)
        #expect(StoredProfile.preview.studyGoals != nil)

        // Each step saves in one update, so a half-filled one is not "answered" — and the
        // wizard's resume point depends on that being true.
        let halfAcademic = StoredProfile(university: "Bahrain Polytechnic", major: "Programming", year: 2)
        #expect(halfAcademic.academicProfile == nil)

        let halfGoals = StoredProfile(weeklyStudyGoalHours: 12)
        #expect(halfGoals.studyGoals == nil)
    }
}
