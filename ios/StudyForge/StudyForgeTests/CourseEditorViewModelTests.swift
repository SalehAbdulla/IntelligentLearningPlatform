//
//  CourseEditorViewModelTests.swift
//  StudyForgeTests
//
//  F11 — J03's validation and the create/edit distinction.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Course editor (F11)")
@MainActor
struct CourseEditorViewModelTests {

    @Test("A new course cannot be saved without a name and a code")
    func validation() {
        let viewModel = CourseEditorViewModel(uid: "t1", store: InMemoryCourseStore())
        #expect(viewModel.canSave == false)
        #expect(viewModel.validationMessage == L10n.tutorNameRequired.string)

        viewModel.name = "Database Systems"
        #expect(viewModel.validationMessage == L10n.tutorCodeRequired.string)

        viewModel.code = "IT8108"
        #expect(viewModel.canSave)
        #expect(viewModel.validationMessage == nil)
    }

    @Test("Whitespace is not a name")
    func whitespaceIsNotAName() {
        let viewModel = CourseEditorViewModel(uid: "t1", store: InMemoryCourseStore())
        viewModel.name = "   "
        viewModel.code = "IT8108"

        #expect(viewModel.canSave == false)
    }

    @Test("Creating writes a course owned by the signed-in tutor, with its values trimmed")
    func create() async throws {
        let store = InMemoryCourseStore()
        let viewModel = CourseEditorViewModel(uid: "t1", store: store)
        viewModel.name = "  Database Systems  "
        viewModel.code = "  it8108  "
        viewModel.enrolmentMode = .approval
        viewModel.colourIndex = 3

        let saved = await viewModel.save()

        #expect(saved)
        let course = try #require(try await store.courses(tutorUid: "t1").first)
        #expect(course.name == "Database Systems")
        #expect(course.code == "it8108")
        #expect(course.tutorUid == "t1")
        #expect(course.enrolmentMode == .approval)
        #expect(course.colourIndex == 3)
    }

    @Test("Editing keeps the course's identity, its roster and its publications")
    func editPreservesIdentity() async throws {
        let existing = Course(
            id: "c1",
            name: "Old name",
            code: "OLD",
            tutorUid: "t1",
            enrolledUids: ["s1", "s2"],
            publishedMaterials: [PublishedMaterial(materialId: "m1", title: "Lecture 4")]
        )
        let store = InMemoryCourseStore(courses: [existing])

        // Build the editor the way the VIEW does, from the course being edited.
        let loaded = try #require(try await store.course(id: "c1"))
        let viewModel = CourseEditorViewModel(uid: "t1", store: store, existing: loaded)
        #expect(viewModel.isEditing)

        viewModel.name = "New name"
        viewModel.code = "NEW"
        let saved = await viewModel.save()

        #expect(saved)
        let course = try #require(try await store.course(id: "c1"))
        #expect(course.id == "c1", "editing must not fork the course")
        #expect(course.name == "New name")
        #expect(course.enrolmentCount == 2, "the roster survives an edit")
        #expect(course.publishedMaterials.count == 1, "so do the publications")
    }

    @Test("A store failure is surfaced, and save reports failure")
    func failureIsReported() async {
        let store = InMemoryCourseStore()
        await store.forceFailure(.storageFailed)
        let viewModel = CourseEditorViewModel(uid: "t1", store: store)
        viewModel.name = "Course"
        viewModel.code = "C1"

        let saved = await viewModel.save()

        #expect(saved == false)
        #expect(viewModel.error != nil)
    }

    @Test("The screen title distinguishes create from edit")
    func titles() {
        let creating = CourseEditorViewModel(uid: "t1", store: InMemoryCourseStore())
        #expect(creating.title == L10n.tutorNewCourse.string)

        let editing = CourseEditorViewModel(
            uid: "t1",
            store: InMemoryCourseStore(),
            existing: Course(name: "x", code: "x", tutorUid: "t1")
        )
        #expect(editing.title == L10n.tutorEditCourse.string)
    }
}
