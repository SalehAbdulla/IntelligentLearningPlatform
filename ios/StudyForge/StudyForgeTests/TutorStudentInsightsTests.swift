import Foundation
import Testing
@testable import StudyForge

@Suite("Tutor roster insights (F11)")
struct TutorStudentInsightsTests {

    private let now = Date(timeIntervalSince1970: 2_000_000_000)

    private func student(
        _ name: String,
        number: String = "1",
        mastery: Int = 75,
        daysAgo: Double? = 1,
        status: EnrollmentStatus = .active
    ) -> Enrollment {
        Enrollment(
            courseId: "c1",
            uid: "uid-\(name)",
            studentName: name,
            studentNumber: number,
            masteryPercent: mastery,
            lastActiveAt: daysAgo.map { now.addingTimeInterval(-$0 * 86_400) },
            status: status
        )
    }

    @Test("Low mastery, inactivity and never logging in are risk flags")
    func riskFlags() {
        #expect(TutorStudentInsights.riskFlags(for: student("A"), now: now).isEmpty)
        #expect(TutorStudentInsights.riskFlags(for: student("B", mastery: 40), now: now) == [.lowMastery])
        #expect(TutorStudentInsights.riskFlags(for: student("C", daysAgo: 9), now: now) == [.inactive])
        #expect(TutorStudentInsights.riskFlags(for: student("D", mastery: 30, daysAgo: nil), now: now) == [.lowMastery, .neverActive])
        #expect(TutorStudentInsights.riskFlags(for: student("E", status: .pending), now: now) == [.pendingApproval])
        #expect(TutorStudentInsights.riskFlags(for: student("F", mastery: 10, status: .removed), now: now).isEmpty)
    }

    @Test("Pending students are not counted as at risk")
    func pendingNotAtRisk() {
        #expect(!TutorStudentInsights.isAtRisk(student("E", mastery: 10, status: .pending), now: now))
        #expect(TutorStudentInsights.isAtRisk(student("B", mastery: 40), now: now))
    }

    @Test("Filters pick out at-risk, inactive and pending students and hide removed ones")
    func filters() {
        let roster = [
            student("A"),
            student("B", mastery: 40),
            student("C", daysAgo: 10),
            student("D", status: .pending),
            student("E", status: .removed)
        ]

        #expect(roster.filter { TutorRosterFilter.all.includes($0, now: now) }.count == 4)
        #expect(roster.filter { TutorRosterFilter.atRisk.includes($0, now: now) }.map(\.studentName) == ["B", "C"])
        #expect(roster.filter { TutorRosterFilter.inactive.includes($0, now: now) }.map(\.studentName) == ["C"])
        #expect(roster.filter { TutorRosterFilter.pending.includes($0, now: now) }.map(\.studentName) == ["D"])
    }

    @Test("Search matches names and IDs and sorting follows the chosen column")
    func searchAndSort() {
        let roster = [
            student("Saleh Abdulla", number: "202301", mastery: 72, daysAgo: 0.1),
            student("Noor Ali", number: "202305", mastery: 66, daysAgo: 0.2),
            student("Mohammed A.", number: "202401702", mastery: 54, daysAgo: 1)
        ]

        #expect(TutorStudentInsights.roster(roster, query: "noor", filter: .all, sort: .name, now: now).map(\.studentName) == ["Noor Ali"])
        #expect(TutorStudentInsights.roster(roster, query: "2024", filter: .all, sort: .name, now: now).map(\.studentName) == ["Mohammed A."])
        #expect(TutorStudentInsights.roster(roster, query: "", filter: .all, sort: .name, now: now).map(\.studentName) == ["Mohammed A.", "Noor Ali", "Saleh Abdulla"])
        #expect(TutorStudentInsights.roster(roster, query: "", filter: .all, sort: .mastery, now: now).map(\.masteryPercent) == [54, 66, 72])
        #expect(TutorStudentInsights.roster(roster, query: "", filter: .all, sort: .active, now: now).first?.studentName == "Saleh Abdulla")
    }

    @Test("Activity fades over two weeks and the cohort average skips pending students")
    func activityAndAverage() {
        #expect(TutorStudentInsights.activityScore(student("A", daysAgo: 0), now: now) == 1)
        #expect(TutorStudentInsights.activityScore(student("A", daysAgo: 7), now: now) == 0.5)
        #expect(TutorStudentInsights.activityScore(student("A", daysAgo: 30), now: now) == 0)
        #expect(TutorStudentInsights.activityScore(student("A", daysAgo: nil), now: now) == 0)
        #expect(TutorStudentInsights.cohortAverage([student("A", mastery: 80), student("B", mastery: 60), student("C", mastery: 0, status: .pending)]) == 70)
        #expect(TutorStudentInsights.cohortAverage([]) == 0)
        #expect(TutorStudentInsights.firstName("Mohammed Almadhoon") == "Mohammed")
    }
}
