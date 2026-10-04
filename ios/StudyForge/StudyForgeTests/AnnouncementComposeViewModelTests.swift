//
//  AnnouncementComposeViewModelTests.swift
//  StudyForgeTests
//
//  F11 — J09. The last test is the one worth keeping: an announcement's `visibility` is DERIVED
//  from its audience, and only a course-wide one is readable by a student under
//  `firestore.rules`.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Announcement compose (F11)")
@MainActor
struct AnnouncementComposeViewModelTests {

    private func viewModel(store: InMemoryCourseStore = InMemoryCourseStore()) -> AnnouncementComposeViewModel {
        AnnouncementComposeViewModel(uid: "t1", courseId: "c1", store: store)
    }

    @Test("A title and a message are both required, and the message names what is missing")
    func validation() {
        let model = viewModel()
        #expect(model.canSend == false)
        #expect(model.validationMessage == L10n.tutorTitleRequired.string)

        model.title = "Deadline moved"
        #expect(model.validationMessage == L10n.tutorBodyRequired.string)

        model.body = "The deadline is now Friday."
        #expect(model.canSend)
        #expect(model.validationMessage == nil)
    }

    @Test("Send now records it as sent, authored by the signed-in tutor")
    func sendNow() async throws {
        let store = InMemoryCourseStore()
        let model = viewModel(store: store)
        model.title = "Deadline moved"
        model.body = "The deadline is now Friday."

        let sent = await model.sendNow()

        #expect(sent)
        let stored = try #require(try await store.announcements(courseId: "c1").first)
        #expect(stored.isSent)
        #expect(stored.isScheduled == false)
        #expect(stored.authorUid == "t1")
        #expect(model.confirmationText == L10n.tutorSentBanner.string)
    }

    @Test("Scheduling queues it for the chosen date and does not mark it sent")
    func schedule() async throws {
        let store = InMemoryCourseStore()
        let model = viewModel(store: store)
        model.title = "Reminder"
        model.body = "Quiz on Sunday."
        model.wantsSchedule = true
        model.scheduledFor = Date().addingTimeInterval(60 * 60 * 24)

        let scheduled = await model.schedule()

        #expect(scheduled)
        let stored = try #require(try await store.announcements(courseId: "c1").first)
        #expect(stored.isScheduled)
        #expect(stored.isSent == false)
        #expect(model.confirmationText == L10n.tutorScheduledBanner.string)
    }

    @Test("A template fills the title and leaves the message to the tutor")
    func templateFillsTheTitleOnly() {
        let model = viewModel()

        model.applyTemplate(.newMaterial)

        #expect(model.title == L10n.tutorTemplateNewMaterial.string)
        #expect(model.body.isEmpty, "the app must not put words in a teacher's mouth")
    }

    @Test("A course-wide announcement is readable by students; anything else is not")
    func visibilityFollowsTheAudience() async throws {
        let store = InMemoryCourseStore()
        let model = viewModel(store: store)
        model.title = "Hello"
        model.body = "Body"
        model.audience = .individual

        await model.sendNow()

        let stored = try #require(try await store.announcements(courseId: "c1").first)
        #expect(stored.visibility == "tutor")
        #expect(stored.reachesStudents == false, "firestore.rules lets a student read only 'course'")
        #expect(model.reachesStudents == false)

        let courseWide = viewModel(store: InMemoryCourseStore())
        courseWide.audience = .course
        #expect(courseWide.reachesStudents)
    }

    @Test("A store failure is surfaced and nothing is claimed as sent")
    func failureIsReported() async {
        let store = InMemoryCourseStore()
        await store.forceFailure(.storageFailed)
        let model = viewModel(store: store)
        model.title = "Hello"
        model.body = "Body"

        let sent = await model.sendNow()

        #expect(sent == false)
        #expect(model.error != nil)
        #expect(model.confirmationText == nil)
    }
}
