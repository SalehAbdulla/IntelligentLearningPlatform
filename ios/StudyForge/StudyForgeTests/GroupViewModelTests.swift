//
//  GroupViewModelTests.swift
//  StudyForgeTests
//
//  Tests for the group list/join, board, chat and live-quiz flows.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Group list and join (F09)")
@MainActor
struct GroupListViewModelTests {

    private func group(id: String = "g1", code: String = "ABC123", members: [GroupMember] = []) -> StudyGroup {
        StudyGroup(id: id, name: "Database revision", inviteCode: code, members: members)
    }

    @Test("An empty store shows the empty state")
    func emptyStore() async {
        let viewModel = GroupListViewModel(store: InMemoryGroupStore())
        await viewModel.load()
        #expect(viewModel.isEmpty)
    }

    @Test("Creating a group makes the creator its owner")
    func createOwnsTheGroup() async throws {
        let store = InMemoryGroupStore()
        let viewModel = GroupListViewModel(store: store)
        viewModel.name = "  Database revision  "

        await viewModel.create(ownerName: "Sara Ali")

        let created = try await store.all().first
        #expect(created?.name == "Database revision")
        #expect(created?.members.first?.name == "Sara Ali")
        #expect(created?.members.first?.isOwner == true)
        #expect(viewModel.name.isEmpty)
    }

    @Test("A blank name creates nothing")
    func blankNameIsRefused() async throws {
        let store = InMemoryGroupStore()
        let viewModel = GroupListViewModel(store: store)
        viewModel.name = "   "
        await viewModel.create(ownerName: "Sara Ali")
        #expect(try await store.all().isEmpty)
    }

    @Test("Joining with a valid code adds the student as a member")
    func joinSucceeds() async throws {
        let store = InMemoryGroupStore(seededWith: [group(code: "ABC123")])
        let viewModel = GroupListViewModel(store: store)
        viewModel.code = " abc123 "

        await viewModel.join(as: "Sara Ali")

        #expect(viewModel.joinError == nil)
        #expect(try await store.group(id: "g1")?.contains(memberNamed: "Sara Ali") == true)
        #expect(viewModel.code.isEmpty)
    }

    @Test("A code no group carries is refused with its own message")
    func joinInvalidCode() async throws {
        let store = InMemoryGroupStore(seededWith: [group(code: "ABC123")])
        let viewModel = GroupListViewModel(store: store)
        viewModel.code = "ZZZZZZ"

        await viewModel.join(as: "Sara Ali")

        #expect(viewModel.joinError == L10n.groupJoinCodeInvalid.string)
        #expect(try await store.group(id: "g1")?.members.isEmpty == true)
    }

    @Test("Joining a group you are already in is refused")
    func joinAlreadyMember() async {
        let store = InMemoryGroupStore(seededWith: [
            group(members: [GroupMember(name: "Sara Ali", isOwner: true)])
        ])
        let viewModel = GroupListViewModel(store: store)
        viewModel.code = "ABC123"

        await viewModel.join(as: "Sara Ali")

        #expect(viewModel.joinError == L10n.groupJoinAlreadyMember.string)
    }

    @Test("Every string comes from the catalogue")
    func copyIsLocalised() {
        let viewModel = GroupListViewModel(store: InMemoryGroupStore())
        let sample = group(members: [GroupMember(name: "Sara", isOnline: true)])

        #expect(viewModel.title == L10n.groupTitle.string)
        #expect(viewModel.emptyTitle == L10n.groupEmptyTitle.string)
        #expect(viewModel.memberCount(sample) == L10n.groupMemberCount.string(1))
        #expect(viewModel.onlineCount(sample) == L10n.groupPresenceOnline.string(1))
    }
}

@Suite("Group board (F09)")
@MainActor
struct GroupDetailViewModelTests {

    @Test("Pinning a material shares it once, and unpinning removes it")
    func pinAndUnpin() async throws {
        let material = Material(title: "Lecture 4", source: .text, text: "body")
        let store = InMemoryGroupStore(seededWith: [StudyGroup(id: "g1", name: "Group")])
        let viewModel = GroupDetailViewModel(
            groupId: "g1",
            store: store,
            materials: InMemoryMaterialStore(seededWith: [material])
        )
        await viewModel.load()

        await viewModel.pin(material, by: "Sara Ali")
        await viewModel.pin(material, by: "Sara Ali")
        #expect(viewModel.resources.count == 1)
        #expect(viewModel.resources.first?.pinnedBy == "Sara Ali")

        let resource = try #require(viewModel.resources.first)
        await viewModel.unpin(resource)
        #expect(viewModel.resources.isEmpty)
    }

    @Test("Only materials not already pinned are offered")
    func availableMaterialsExcludePinned() async {
        let a = Material(title: "A", source: .text, text: "a")
        let b = Material(title: "B", source: .text, text: "b")
        let store = InMemoryGroupStore(seededWith: [
            StudyGroup(
                id: "g1",
                name: "Group",
                resources: [GroupResource(kind: .material, referenceId: a.id, title: "A", pinnedBy: "Omar")]
            )
        ])
        let viewModel = GroupDetailViewModel(
            groupId: "g1", store: store, materials: InMemoryMaterialStore(seededWith: [a, b])
        )
        await viewModel.load()

        let available = await viewModel.availableMaterials()
        #expect(available.map(\.title) == ["B"])
    }

    @Test("The owner is recognised as the host")
    func hostIsTheOwner() async {
        let store = InMemoryGroupStore(seededWith: [
            StudyGroup(id: "g1", name: "Group", members: [GroupMember(name: "Sara", isOwner: true)])
        ])
        let viewModel = GroupDetailViewModel(
            groupId: "g1", store: store, materials: InMemoryMaterialStore()
        )
        await viewModel.load()

        #expect(viewModel.isHost("Sara"))
        #expect(viewModel.isHost("Omar") == false)
    }
}

@Suite("Group chat (F09)")
@MainActor
struct GroupChatViewModelTests {

    private func model() async -> (GroupChatViewModel, InMemoryGroupStore) {
        let store = InMemoryGroupStore(seededWith: [
            StudyGroup(id: "g1", name: "Group", members: [GroupMember(name: "Sara Ali", isOwner: true)])
        ])
        let viewModel = GroupChatViewModel(groupId: "g1", store: store, me: "Sara Ali")
        await viewModel.load()
        return (viewModel, store)
    }

    @Test("Sending a message appends it, trimmed, and clears the draft")
    func sendAppends() async throws {
        let (viewModel, store) = await model()
        viewModel.draft = "  Anyone free at 6?  "

        await viewModel.send()

        #expect(viewModel.draft.isEmpty)
        #expect(viewModel.messages.count == 1)
        #expect(viewModel.messages.first?.text == "Anyone free at 6?")
        #expect(try await store.group(id: "g1")?.messages.count == 1)
    }

    @Test("A blank draft is never sent")
    func blankDraftIsRefused() async throws {
        let (viewModel, store) = await model()
        viewModel.draft = "   "
        #expect(viewModel.canSend == false)

        await viewModel.send()

        #expect(try await store.group(id: "g1")?.messages.isEmpty == true)
    }

    @Test("A message is recognised as the student's own")
    func ownMessagesAreRecognised() async {
        let (viewModel, _) = await model()
        viewModel.draft = "Mine"
        await viewModel.send()

        #expect(viewModel.isMine(viewModel.messages[0]))
        #expect(viewModel.isMine(GroupMessage(senderName: "Omar", text: "Theirs")) == false)
    }
}

@Suite("Live group quiz (F09)")
@MainActor
struct LiveQuizViewModelTests {

    private func quiz(id: String = "q1", questions: Int = 3) -> Quiz {
        Quiz(
            id: id,
            title: "Normalisation",
            questionType: .multipleChoice,
            questions: (0..<questions).map { index in
                QuizQuestion(
                    stem: "Question \(index)",
                    options: ["Correct", "Wrong 1", "Wrong 2", "Wrong 3"],
                    correctOptionIndex: 0,
                    explanation: "Because.",
                    topic: "topic-\(index)",
                    provenance: AIProvenance(materialId: "m", pageNumbers: [1], confidence: .high)
                )
            }
        )
    }

    private func model(seeded: [Quiz]) async -> LiveQuizViewModel {
        let store = InMemoryQuizStore(seededWith: seeded)
        let group = StudyGroup(
            name: "Database revision",
            members: [
                GroupMember(name: "Sara Ali", isOwner: true),
                GroupMember(name: "Omar"),
            ]
        )
        let viewModel = LiveQuizViewModel(group: group, me: "Sara Ali", quizStore: store)
        await viewModel.load()
        return viewModel
    }

    @Test("The host starts the quiz and opens the first question")
    func startOpensFirstQuestion() async {
        let viewModel = await model(seeded: [quiz()])

        viewModel.start()

        #expect(viewModel.phase == .question)
        #expect(viewModel.currentQuestion?.stem == "Question 0")
        #expect(viewModel.session?.questions.count == 3, "the whole quiz when the limit exceeds it")
    }

    @Test("Answering scores the student and reveals the answer")
    func answeringScores() async {
        let viewModel = await model(seeded: [quiz()])
        viewModel.start()

        viewModel.answer(0)   // correct

        #expect(viewModel.phase == .revealed)
        #expect(viewModel.session?.myPlayer?.score == 1)
        #expect(viewModel.session?.allAnswered == true, "the others answered too")
    }

    @Test("A wrong answer does not score")
    func wrongAnswerScoresNothing() async {
        let viewModel = await model(seeded: [quiz()])
        viewModel.start()

        viewModel.answer(1)   // wrong

        #expect(viewModel.session?.myPlayer?.score == 0)
        #expect(viewModel.phase == .revealed)
    }

    @Test("Running out of time reveals the answer without one")
    func timeoutReveals() async {
        let viewModel = await model(seeded: [quiz()])
        viewModel.start()

        // Tick past the whole question clock.
        for _ in 0..<(LiveQuizSession.questionSeconds + 1) { await viewModel.tick() }

        #expect(viewModel.phase == .revealed)
        #expect(viewModel.session?.myPlayer?.score == 0)
    }

    @Test("Advancing runs the questions and ends on the leaderboard")
    func advanceToResults() async {
        let viewModel = await model(seeded: [quiz(questions: 2)])
        viewModel.start()

        viewModel.answer(0)
        viewModel.advance()
        #expect(viewModel.phase == .question)
        #expect(viewModel.currentQuestion?.stem == "Question 1")

        viewModel.answer(0)
        viewModel.advance()
        #expect(viewModel.phase == .results)
    }

    @Test("The leaderboard ranks by score and the topic bars cover every answer")
    func leaderboardAndTopics() async {
        let viewModel = await model(seeded: [quiz(questions: 2)])
        viewModel.start()
        viewModel.answer(0)   // correct — the student scores
        viewModel.advance()
        viewModel.answer(0)   // correct again
        viewModel.advance()

        #expect(viewModel.phase == .results)
        #expect(viewModel.leaderboard.first?.id == viewModel.session?.myPlayerId, "2/2 leads")
        #expect(viewModel.topicScores.count == 2, "one bar per attempted topic")
    }

    @Test("A rematch clears the scores and returns to question one")
    func rematchResets() async {
        let viewModel = await model(seeded: [quiz(questions: 2)])
        viewModel.start()
        viewModel.answer(0)
        viewModel.advance()
        viewModel.answer(1)
        viewModel.advance()
        #expect(viewModel.session?.myPlayer?.score == 1)

        viewModel.rematch()

        #expect(viewModel.phase == .question)
        #expect(viewModel.session?.currentIndex == 0)
        #expect(viewModel.session?.myPlayer?.score == 0)
        #expect(viewModel.session?.answers.isEmpty == true)
    }

    @Test("The lobby offers no start when the student has no saved quizzes")
    func noQuizzes() async {
        let viewModel = await model(seeded: [])

        #expect(viewModel.hasQuizzes == false)
        viewModel.start()
        #expect(viewModel.session == nil, "nothing to start without a quiz")
    }
}