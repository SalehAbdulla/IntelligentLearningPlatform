import Foundation
import Testing
@testable import StudyForge

@Suite("Tutor gradebook export (F11)")
@MainActor
struct TutorGradebookTests {

    private let now = Date(timeIntervalSince1970: 2_000_000_000)

    private func student(_ name: String, mastery: Int = 70, daysAgo: Double? = 1, status: EnrollmentStatus = .active) -> Enrollment {
        Enrollment(
            courseId: "c1",
            uid: "uid-\(name)",
            studentName: name,
            studentNumber: "ID-\(name)",
            masteryPercent: mastery,
            lastActiveAt: daysAgo.map { now.addingTimeInterval(-$0 * 86_400) },
            status: status
        )
    }

    private var course: Course {
        Course(id: "c1", name: "Data Structures", code: "CS 201", tutorUid: "tutor", termStart: now.addingTimeInterval(-30 * 86_400))
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    @Test("Rows are sorted by name, hide removed students and respect the start date")
    func rows() {
        let enrollments = [student("Zed", daysAgo: 40), student("Amal"), student("Old", status: .removed), student("New", daysAgo: nil)]

        #expect(TutorGradebook.rows(enrollments, activeSince: nil).map(\.studentName) == ["Amal", "New", "Zed"])
        #expect(TutorGradebook.rows(enrollments, activeSince: nil, includeRemoved: true).count == 4)
        #expect(TutorGradebook.rows(enrollments, activeSince: now.addingTimeInterval(-7 * 86_400)).map(\.studentName) == ["Amal"])
    }

    @Test("Columns keep a fixed order whatever order they were picked in")
    func columnOrder() {
        #expect(TutorGradebook.ordered([.risk, .student, .mastery]) == [.student, .mastery, .risk])
    }

    @Test("The CSV has a header, escapes commas and lists risk flags")
    func csv() {
        let rows = [student("Ali, Noor", mastery: 40, daysAgo: 10)]
        let text = TutorGradebook.csv(rows, columns: [.student, .mastery, .risk], now: now)
        let lines = text.components(separatedBy: "\n")

        #expect(lines.first == "Student,Mastery %,Risk flags")
        #expect(lines.last == "\"Ali, Noor\",40,lowMastery inactive")
    }

    @Test("The file name uses the course code and the date")
    func fileName() {
        let name = TutorGradebook.fileName(for: course, format: .csv, now: now)
        #expect(name.hasPrefix("CS-201-gradebook-"))
        #expect(name.hasSuffix(".csv"))
    }

    @Test("A PDF is produced and written to disk")
    func pdfWritten() throws {
        let data = TutorGradebook.pdf(title: "CS201", rows: (0..<40).map { student("S\($0)") }, columns: TutorGradebook.defaultColumns, now: now)
        #expect(data.starts(with: Data("%PDF".utf8)))

        let url = try TutorGradebook.write(data, named: "test.pdf", in: temporaryDirectory())
        #expect(FileManager.default.fileExists(atPath: url.path))
    }

    @Test("The gradebook screen keeps at least one column and exports the chosen format")
    func viewModelExport() async throws {
        let store = InMemoryCourseStore(courses: [course], enrollments: [student("Amal"), student("Badr", daysAgo: 60)])
        let viewModel = TutorGradebookViewModel(course: course, store: store, directory: temporaryDirectory(), clock: { now })
        await viewModel.load()

        for column in TutorGradebook.defaultColumns { viewModel.toggle(column) }
        #expect(viewModel.orderedColumns == [.lastActive])
        viewModel.toggle(.student)
        #expect(viewModel.orderedColumns == [.student, .lastActive])

        viewModel.limitsToStartDate = true
        viewModel.startDate = now.addingTimeInterval(-7 * 86_400)
        #expect(viewModel.rows.map(\.studentName) == ["Amal"])
        #expect(viewModel.scopeSummary == TutorStudioCopy.studentScope(1, 2))

        let url = try #require(await viewModel.export())
        #expect(url.pathExtension == "csv")
        #expect(viewModel.exportedURL == url)

        viewModel.format = .pdf
        viewModel.settingsChanged()
        #expect(viewModel.exportedURL == nil)
        #expect(try #require(await viewModel.export()).pathExtension == "pdf")
    }

    @Test("Nothing to export disables the export")
    func emptyExport() async {
        let viewModel = TutorGradebookViewModel(course: course, store: InMemoryCourseStore(courses: [course]), directory: temporaryDirectory())
        await viewModel.load()

        #expect(!viewModel.canExport)
        #expect(await viewModel.export() == nil)
    }
}
