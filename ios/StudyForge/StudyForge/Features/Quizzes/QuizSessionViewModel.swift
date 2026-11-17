import Foundation

@MainActor
@Observable
final class QuizSessionViewModel {

    enum Phase: Equatable {
        case answering
        case feedback
        case finished
    }

    static let lowTimeSeconds = 60
    static let revisionMinutes = 15

    private(set) var quiz: Quiz
    let questions: [QuizQuestion]
    let isWeakTopicRetake: Bool

    private(set) var currentIndex = 0
    private(set) var phase: Phase
    private(set) var responses: [String: QuizResponse] = [:]
    private(set) var typedAnswers: [String: String] = [:]
    private(set) var credits: [String: QuizCredit] = [:]
    private(set) var flaggedQuestionIds: Set<String> = []
    private(set) var pendingOption: Int? = nil
    var draftAnswer = ""

    private(set) var isConfirmingSubmit = false
    private(set) var deadline: Date? = nil
    private(set) var remainingSeconds: Int? = nil
    private(set) var timedOut = false
    private(set) var isSaving = false
    private(set) var result: QuizResult? = nil
    private(set) var error: AppError? = nil
    private(set) var revisionTopics: Set<String> = []
    private(set) var isAddingToPlan = false

    private var startedAt: Date
    private var priorElapsed = 0

    private let store: any QuizStore
    private let log: any QuizAttemptLog
    private let drafts: any QuizDraftStore
    private let plans: (any StudyPlanStore)?
    private let clock: () -> Date

    init(
        quiz: Quiz,
        questions: [QuizQuestion]? = nil,
        store: any QuizStore,
        log: any QuizAttemptLog = InMemoryQuizAttemptLog(),
        drafts: any QuizDraftStore = InMemoryQuizDraftStore(),
        plans: (any StudyPlanStore)? = nil,
        clock: @escaping () -> Date = { .now }
    ) {
        let chosen = questions ?? quiz.questions
        self.quiz = quiz
        self.questions = chosen
        self.isWeakTopicRetake = questions != nil && chosen.count < quiz.questions.count
        self.store = store
        self.log = log
        self.drafts = drafts
        self.plans = plans
        self.clock = clock
        let now = clock()
        self.startedAt = now
        self.phase = chosen.isEmpty ? .finished : .answering
        if let minutes = quiz.timerMinutes, !chosen.isEmpty {
            let end = now.addingTimeInterval(TimeInterval(minutes * 60))
            self.deadline = end
            self.remainingSeconds = minutes * 60
        }
    }

    var currentQuestion: QuizQuestion? {
        questions.indices.contains(currentIndex) ? questions[currentIndex] : nil
    }

    var currentKind: QuizQuestionKind? { currentQuestion.map(QuizQuestionKind.init) }

    var progressText: String { QuizCopy.progress(min(currentIndex + 1, questions.count), questions.count) }

    var progressFraction: Double {
        questions.isEmpty ? 0 : Double(answeredCount) / Double(questions.count)
    }

    var answeredCount: Int {
        questions.filter { isAnswered($0) }.count
    }

    var unansweredNumbers: [Int] {
        questions.enumerated().compactMap { isAnswered($0.element) ? nil : $0.offset + 1 }
    }

    var isLastQuestion: Bool { currentIndex >= questions.count - 1 }

    var currentResponse: QuizResponse? { currentQuestion.flatMap { responses[$0.id] } }

    var currentCredit: QuizCredit? { currentQuestion.flatMap { credits[$0.id] } }

    var currentOutcome: QuizOutcome? {
        guard let question = currentQuestion, phase == .feedback else { return nil }
        return QuizInsights.outcome(responses[question.id], credit: credits[question.id])
    }

    var canSubmitTypedAnswer: Bool {
        phase == .answering && !draftAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canCheck: Bool {
        guard phase == .answering, let kind = currentKind else { return false }
        return kind == .shortAnswer ? canSubmitTypedAnswer : pendingOption != nil
    }

    var isTimed: Bool { deadline != nil }

    var timeText: String? { remainingSeconds.map(QuizInsights.clockText) }

    var isRunningLow: Bool { (remainingSeconds ?? .max) <= Self.lowTimeSeconds }

    var elapsedSeconds: Int {
        priorElapsed + max(0, Int(clock().timeIntervalSince(startedAt)))
    }

    var canAddToPlan: Bool { plans != nil }

    func isAnswered(_ question: QuizQuestion) -> Bool {
        responses[question.id]?.selectedOptionIndex != nil
    }

    func isFlagged(_ question: QuizQuestion) -> Bool {
        flaggedQuestionIds.contains(question.id)
    }

    func isLowConfidence(_ question: QuizQuestion) -> Bool {
        question.provenance.confidence == .low
    }

    func citationLabel(for question: QuizQuestion) -> String {
        question.provenance.pageNumbers.isEmpty ? QuizCopy.source : question.provenance.citationLabel
    }

    func isInRevisionPlan(_ question: QuizQuestion) -> Bool {
        revisionTopics.contains(question.topic)
    }

    func choose(_ option: Int) {
        guard phase == .answering, let question = currentQuestion, question.options.indices.contains(option) else { return }
        pendingOption = option
    }

    func check() {
        guard canCheck else { return }
        if currentKind == .shortAnswer {
            submitTypedAnswer()
        } else if let pendingOption {
            select(pendingOption)
        }
    }

    func select(_ option: Int) {
        guard phase == .answering, let question = currentQuestion, question.options.indices.contains(option) else { return }
        pendingOption = nil
        responses[question.id] = QuizResponse(
            questionId: question.id,
            selectedOptionIndex: option,
            isCorrect: option == question.correctOptionIndex
        )
        phase = .feedback
        Task { await saveDraft() }
    }

    func submitTypedAnswer() {
        guard canSubmitTypedAnswer, let question = currentQuestion else { return }
        let answer = QuizAnswerMarker.limited(draftAnswer.trimmingCharacters(in: .whitespacesAndNewlines))
        let expected = question.options.indices.contains(question.correctOptionIndex) ? question.options[question.correctOptionIndex] : ""
        let credit = QuizAnswerMarker.credit(for: answer, expected: expected)
        typedAnswers[question.id] = answer
        credits[question.id] = credit
        responses[question.id] = QuizResponse(
            questionId: question.id,
            selectedOptionIndex: question.correctOptionIndex,
            isCorrect: credit == .full
        )
        phase = .feedback
        Task { await saveDraft() }
    }

    func skip() async {
        guard phase == .answering else { return }
        draftAnswer = ""
        pendingOption = nil
        await advance()
    }

    func next() async {
        guard phase == .feedback else { return }
        await advance()
    }

    func toggleFlag() {
        guard let question = currentQuestion, phase != .finished else { return }
        if flaggedQuestionIds.contains(question.id) {
            flaggedQuestionIds.remove(question.id)
        } else {
            flaggedQuestionIds.insert(question.id)
        }
        Task { await saveDraft() }
    }

    func requestSubmit() async {
        guard phase != .finished else { return }
        if unansweredNumbers.isEmpty {
            await finish()
        } else {
            isConfirmingSubmit = true
        }
    }

    func cancelSubmit() {
        isConfirmingSubmit = false
    }

    func confirmSubmit() async {
        isConfirmingSubmit = false
        await finish()
    }

    func reviewUnanswered() {
        isConfirmingSubmit = false
        guard let index = questions.firstIndex(where: { !isAnswered($0) }) else { return }
        go(to: index)
    }

    func go(to index: Int) {
        guard phase != .finished, questions.indices.contains(index) else { return }
        currentIndex = index
        draftAnswer = ""
        pendingOption = nil
        phase = isAnswered(questions[index]) ? .feedback : .answering
    }

    func tick() async {
        guard let deadline, phase != .finished else { return }
        let left = Int(deadline.timeIntervalSince(clock()).rounded(.up))
        remainingSeconds = max(0, left)
        if left <= 0 {
            timedOut = true
            await finish()
        }
    }

    func resume() async {
        guard phase != .finished,
              let draft = await drafts.draft(forQuiz: quiz.id),
              draft.questionIds == questions.map(\.id) else { return }
        responses = Dictionary(draft.responses.map { ($0.questionId, $0) }, uniquingKeysWith: { _, last in last })
        typedAnswers = draft.typedAnswers
        credits = draft.credits
        flaggedQuestionIds = Set(draft.flaggedQuestionIds)
        priorElapsed = draft.elapsedSeconds
        startedAt = clock()
        if quiz.timerMinutes != nil {
            deadline = draft.deadline
        }
        go(to: min(max(draft.currentIndex, 0), questions.count - 1))
        await tick()
    }

    func pause() async {
        await saveDraft()
    }

    func addToRevisionPlan() async {
        guard let plans, let question = currentQuestion, !revisionTopics.contains(question.topic), !isAddingToPlan else { return }
        isAddingToPlan = true
        defer { isAddingToPlan = false }

        let now = clock()
        let session = StudySession(
            subject: QuizCopy.revisionSubject(question.topic),
            estimatedMinutes: Self.revisionMinutes,
            scheduledAt: Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
        )
        do {
            if var plan = try await plans.all().first {
                plan.sessions.append(session)
                plan.updatedAt = now
                try await plans.add(plan)
            } else {
                let plan = StudyPlan(
                    input: StudyPlanInput(subjects: [question.topic], weeklyHours: 1, intensity: .light),
                    sessions: [session],
                    createdAt: now,
                    updatedAt: now
                )
                try await plans.add(plan)
            }
            revisionTopics.insert(question.topic)
        } catch {
            self.error = AppError.from(error)
        }
    }

    private func advance() async {
        if let nextIndex = nextIndex(after: currentIndex) {
            currentIndex = nextIndex
            draftAnswer = ""
            pendingOption = nil
            phase = .answering
            await saveDraft()
        } else {
            await requestSubmit()
        }
    }

    private func nextIndex(after index: Int) -> Int? {
        let following = index + 1
        return questions.indices.contains(following) ? following : nil
    }

    private func finish() async {
        guard phase != .finished, !isSaving else { return }
        isSaving = true
        isConfirmingSubmit = false
        defer { isSaving = false }

        let now = clock()
        let ordered = questions.map { question in
            responses[question.id] ?? QuizResponse(questionId: question.id, selectedOptionIndex: nil, isCorrect: false)
        }
        let attempt = QuizAttempt(responses: ordered, createdAt: now)
        let record = QuizAttemptRecord(
            id: attempt.id,
            quizId: quiz.id,
            questionIds: questions.map(\.id),
            durationSeconds: elapsedSeconds,
            flaggedQuestionIds: questions.map(\.id).filter { flaggedQuestionIds.contains($0) },
            typedAnswers: typedAnswers,
            credits: credits,
            timedOut: timedOut,
            completedAt: now
        )
        quiz.attempts.insert(attempt, at: 0)
        result = QuizResult(quiz: quiz, attempt: attempt, record: record)
        phase = .finished
        if let deadline {
            remainingSeconds = max(0, Int(deadline.timeIntervalSince(now).rounded(.up)))
        }

        do {
            try await store.add(quiz)
        } catch {
            self.error = AppError.from(error)
        }
        do {
            try await log.save(record)
        } catch {
            if self.error == nil { self.error = AppError.from(error) }
        }
        await drafts.clear(quizId: quiz.id)
    }

    private func saveDraft() async {
        guard phase != .finished, !questions.isEmpty else { return }
        let draft = QuizDraft(
            quizId: quiz.id,
            questionIds: questions.map(\.id),
            responses: questions.compactMap { responses[$0.id] },
            typedAnswers: typedAnswers,
            credits: credits,
            flaggedQuestionIds: Array(flaggedQuestionIds),
            currentIndex: currentIndex,
            deadline: deadline,
            elapsedSeconds: elapsedSeconds,
            savedAt: clock()
        )
        try? await drafts.save(draft)
    }
}
