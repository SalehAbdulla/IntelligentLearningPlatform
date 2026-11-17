import Foundation

enum QuizCopy {

    static func text(_ key: String) -> String {
        Bundle.main.localizedString(forKey: key, value: nil, table: "Quizzes")
    }

    static func format(_ key: String, _ arguments: any CVarArg...) -> String {
        String(format: text(key), locale: .current, arguments: arguments)
    }

    static var homeTitle: String { text("quiz.home.title") }
    static var newQuiz: String { text("quiz.home.new") }
    static var emptyTitle: String { text("quiz.home.emptyTitle") }
    static var emptyBody: String { text("quiz.home.emptyBody") }
    static var makeQuiz: String { text("quiz.home.make") }
    static var missed: String { text("quiz.home.missed") }
    static var retake: String { text("quiz.home.retake") }
    static var resume: String { text("quiz.home.resume") }
    static var start: String { text("quiz.home.start") }
    static var notTaken: String { text("quiz.home.notTaken") }
    static var inProgress: String { text("quiz.home.inProgress") }
    static func questionCount(_ count: Int) -> String { format("quiz.home.questions", count) }
    static var deleteQuiz: String { text("quiz.home.delete") }
    static var deleteTitle: String { text("quiz.home.deleteTitle") }
    static func deleteMessage(_ title: String) -> String { format("quiz.home.deleteMessage", title) }
    static func scoreLine(_ score: String, _ percent: String) -> String { format("quiz.home.score", score, percent) }
    static var history: String { text("quiz.home.history") }
    static func rowAccessibility(_ title: String, _ score: String, _ date: String) -> String {
        format("quiz.home.a11yRow", title, score, date)
    }

    static var builderTitle: String { text("quiz.builder.title") }
    static var chooseMaterial: String { text("quiz.builder.chooseMaterial") }
    static var noMaterials: String { text("quiz.builder.noMaterials") }
    static var typeLabel: String { text("quiz.builder.type") }
    static var countLabel: String { text("quiz.builder.count") }
    static var difficultyLabel: String { text("quiz.builder.difficulty") }
    static var timerLabel: String { text("quiz.builder.timer") }
    static var timerOn: String { text("quiz.builder.timerOn") }
    static var timerOff: String { text("quiz.builder.timerOff") }
    static func minutes(_ count: Int) -> String { format("quiz.builder.minutes", count) }
    static var focusLabel: String { text("quiz.builder.focus") }
    static var focusPlaceholder: String { text("quiz.builder.focusPlaceholder") }
    static var focusFooter: String { text("quiz.builder.focusFooter") }
    static var generateQuiz: String { text("quiz.builder.generate") }
    static var tooShort: String { text("quiz.builder.tooShort") }
    static var noQuestions: String { text("quiz.builder.noQuestions") }
    static func quizTitle(_ material: String, _ number: Int) -> String { format("quiz.builder.quizTitle", material, number) }
    static func settingsSummary(_ type: String, _ difficulty: String) -> String { format("quiz.builder.summary", type, difficulty) }
    static var generalTopic: String { text("quiz.builder.generalTopic") }

    static func typeShortTitle(_ type: QuizQuestionType) -> String {
        switch type {
        case .multipleChoice: text("quiz.type.mcq")
        case .trueFalse: text("quiz.type.trueFalse")
        case .shortAnswer: text("quiz.type.short")
        case .mixed: text("quiz.type.mixed")
        }
    }

    static func typeTitle(_ type: QuizQuestionType) -> String {
        switch type {
        case .multipleChoice: text("quiz.type.mcqLong")
        case .trueFalse: text("quiz.type.trueFalseLong")
        case .shortAnswer: text("quiz.type.shortLong")
        case .mixed: text("quiz.type.mixed")
        }
    }

    static func difficultyTitle(_ difficulty: QuizDifficulty) -> String {
        switch difficulty {
        case .easy: text("quiz.difficulty.easy")
        case .medium: text("quiz.difficulty.medium")
        case .hard: text("quiz.difficulty.hard")
        }
    }

    static var generatingTitle: String { text("quiz.generating.title") }
    static func generatingProgress(_ done: Int, _ total: Int) -> String { format("quiz.generating.progress", done, total) }
    static var preparing: String { text("quiz.generating.preparing") }
    static var grounded: String { text("quiz.generating.grounded") }
    static var groundedBody: String { text("quiz.generating.groundedBody") }
    static func dropped(_ count: Int) -> String { format("quiz.generating.dropped", count) }

    static func progress(_ current: Int, _ total: Int) -> String { format("quiz.take.progress", current, total) }
    static var skip: String { text("quiz.take.skip") }
    static var next: String { text("quiz.take.next") }
    static var flag: String { text("quiz.take.flag") }
    static var unflag: String { text("quiz.take.unflag") }
    static var flagged: String { text("quiz.take.flagged") }
    static func timeLeft(_ time: String) -> String { format("quiz.take.timeLeft", time) }
    static var answerPlaceholder: String { text("quiz.take.answerPlaceholder") }
    static var checkAnswer: String { text("quiz.take.check") }
    static var lowConfidence: String { text("quiz.take.lowConfidence") }
    static func trueFalseStem(_ question: String, _ claim: String) -> String { format("quiz.take.trueFalseStem", question, claim) }
    static var offline: String { text("quiz.take.offline") }
    static var leaveTitle: String { text("quiz.take.leaveTitle") }
    static var leaveMessage: String { text("quiz.take.leaveMessage") }
    static var leave: String { text("quiz.take.leave") }
    static var keepGoing: String { text("quiz.take.keepGoing") }
    static var closeQuiz: String { text("quiz.take.close") }
    static var submit: String { text("quiz.take.submit") }
    static func option(_ number: Int, _ total: Int, _ text: String) -> String { format("quiz.take.option", number, total, text) }
    static var trueOption: String { text("quiz.option.true") }
    static var falseOption: String { text("quiz.option.false") }

    static var correct: String { text("quiz.feedback.correct") }
    static var incorrect: String { text("quiz.feedback.incorrect") }
    static var partial: String { text("quiz.feedback.partial") }
    static var correctTag: String { text("quiz.feedback.correctTag") }
    static var yoursTag: String { text("quiz.feedback.yoursTag") }
    static var nextQuestion: String { text("quiz.feedback.next") }
    static var seeResults: String { text("quiz.feedback.finish") }
    static var addToPlan: String { text("quiz.feedback.addToPlan") }
    static var addedToPlan: String { text("quiz.feedback.addedToPlan") }
    static func modelAnswer(_ answer: String) -> String { format("quiz.feedback.modelAnswer", answer) }
    static func yourTypedAnswer(_ answer: String) -> String { format("quiz.feedback.yourAnswer", answer) }
    static var source: String { text("quiz.source") }
    static func cite(_ label: String) -> String { format("quiz.cite", label) }

    static var submitTitle: String { text("quiz.submit.title") }
    static func unanswered(_ count: Int) -> String {
        count == 1 ? text("quiz.submit.unansweredOne") : format("quiz.submit.unanswered", count)
    }
    static func unansweredBody(_ numbers: [Int]) -> String {
        let list = ListFormatter.localizedString(byJoining: numbers.map { $0.formatted() })
        return numbers.count == 1 ? format("quiz.submit.bodyOne", list) : format("quiz.submit.body", list)
    }
    static func submitTimeLeft(_ time: String) -> String { format("quiz.submit.timeLeft", time) }
    static var submitNow: String { text("quiz.submit.now") }
    static var reviewUnanswered: String { text("quiz.submit.review") }

    static func score(_ earned: String, _ total: Int) -> String { format("quiz.result.score", earned, total) }
    static func percent(_ value: Int) -> String { format("quiz.result.percent", value) }
    static func scoreAccessibility(_ earned: String, _ total: Int, _ percent: Int) -> String {
        format("quiz.result.a11y", earned, total, percent)
    }
    static func completedIn(_ duration: String) -> String { format("quiz.result.completedIn", duration) }
    static var timeUp: String { text("quiz.result.timeUp") }
    static var topicHeading: String { text("quiz.result.topics") }
    static func focus(_ topic: String) -> String { format("quiz.result.focus", topic) }
    static var allStrong: String { text("quiz.result.allStrong") }
    static var review: String { text("quiz.result.review") }
    static var retakeWeak: String { text("quiz.result.retakeWeak") }
    static var retakeQuiz: String { text("quiz.result.retake") }
    static var allAttempts: String { text("quiz.result.allAttempts") }
    static var done: String { text("quiz.result.done") }
    static var weakRetake: String { text("quiz.result.weakRetake") }
    static func duration(_ minutes: Int, _ seconds: Int) -> String { format("quiz.duration", minutes, seconds) }
    static func seconds(_ seconds: Int) -> String { format("quiz.seconds", seconds) }

    static var reviewTitle: String { text("quiz.review.title") }
    static func questionNumber(_ number: Int) -> String { format("quiz.review.number", number) }
    static func correctAnswer(_ answer: String) -> String { format("quiz.review.correctAnswer", answer) }
    static func yourAnswer(_ answer: String) -> String { format("quiz.review.yourAnswer", answer) }
    static var skipped: String { text("quiz.review.skipped") }
    static var flaggedTag: String { text("quiz.review.flagged") }
    static var halfCredit: String { text("quiz.review.halfCredit") }
    static func topicTag(_ topic: String) -> String { format("quiz.review.topic", topic) }

    static func attemptCount(_ count: Int) -> String {
        count == 1 ? text("quiz.attempts.countOne") : format("quiz.attempts.count", count)
    }
    static var chartTitle: String { text("quiz.attempts.chart") }
    static func attemptRow(_ number: Int, _ score: String) -> String { format("quiz.attempts.row", number, score) }
    static func attemptDetail(_ date: String, _ duration: String) -> String { format("quiz.attempts.detail", date, duration) }
    static var markingTitle: String { text("quiz.attempts.markingTitle") }
    static var markingBody: String { text("quiz.attempts.markingBody") }
    static var backToResults: String { text("quiz.attempts.back") }
    static var noAttempts: String { text("quiz.attempts.empty") }
    static func chartPoint(_ number: Int, _ percent: Int) -> String { format("quiz.attempts.chartA11y", number, percent) }

    static func revisionSubject(_ topic: String) -> String { format("quiz.revision.subject", topic) }
    static var quizzesEntry: String { text("quiz.entry.quizzes") }
    static var quizMe: String { text("quiz.entry.quizMe") }
}
