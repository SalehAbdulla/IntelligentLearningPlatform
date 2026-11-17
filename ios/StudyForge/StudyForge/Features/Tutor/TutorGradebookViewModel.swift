import Foundation

@MainActor
@Observable
final class TutorGradebookViewModel {

    let course: Course
    private(set) var enrollments: [Enrollment] = []
    private(set) var hasLoaded = false
    private(set) var isExporting = false
    private(set) var exportedURL: URL? = nil
    private(set) var error: AppError? = nil

    private(set) var columns: Set<TutorGradebookColumn> = Set(TutorGradebook.defaultColumns)
    var format: TutorGradebookFormat = .csv
    var limitsToStartDate = false
    var startDate: Date
    var includesRemoved = false

    private let store: any CourseStore
    private let directory: URL
    private let clock: () -> Date

    init(
        course: Course,
        store: any CourseStore,
        directory: URL = FileManager.default.temporaryDirectory,
        clock: @escaping () -> Date = { .now }
    ) {
        self.course = course
        self.store = store
        self.directory = directory
        self.clock = clock
        self.startDate = course.termStart
    }

    var orderedColumns: [TutorGradebookColumn] { TutorGradebook.ordered(columns) }

    var rows: [Enrollment] {
        TutorGradebook.rows(enrollments, activeSince: limitsToStartDate ? startDate : nil, includeRemoved: includesRemoved)
    }

    var canExport: Bool { !rows.isEmpty && !columns.isEmpty && !isExporting }

    var scopeSummary: String { TutorStudioCopy.studentScope(rows.count, enrollments.filter { $0.status != .removed }.count) }

    func isIncluded(_ column: TutorGradebookColumn) -> Bool { columns.contains(column) }

    func toggle(_ column: TutorGradebookColumn) {
        if columns.contains(column) {
            guard columns.count > 1 else { return }
            columns.remove(column)
        } else {
            columns.insert(column)
        }
        exportedURL = nil
    }

    func settingsChanged() {
        exportedURL = nil
    }

    func value(_ column: TutorGradebookColumn, for enrollment: Enrollment) -> String {
        column.displayValue(for: enrollment, now: clock())
    }

    func load() async {
        do {
            enrollments = try await store.enrollments(courseId: course.id)
            error = nil
        } catch {
            self.error = AppError.from(error)
        }
        hasLoaded = true
    }

    @discardableResult
    func export() async -> URL? {
        guard canExport else { return nil }
        isExporting = true
        defer { isExporting = false }

        let now = clock()
        let data: Data
        switch format {
        case .csv:
            data = Data(TutorGradebook.csv(rows, columns: orderedColumns, now: now).utf8)
        case .pdf:
            data = TutorGradebook.pdf(title: TutorStudioCopy.gradebookTitle(course.name), rows: rows, columns: orderedColumns, now: now)
        }
        do {
            let url = try TutorGradebook.write(data, named: TutorGradebook.fileName(for: course, format: format, now: now), in: directory)
            exportedURL = url
            return url
        } catch {
            self.error = AppError.from(error)
            return nil
        }
    }
}
