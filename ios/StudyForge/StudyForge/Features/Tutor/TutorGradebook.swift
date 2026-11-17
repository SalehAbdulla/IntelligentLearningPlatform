import UIKit

enum TutorGradebookColumn: String, CaseIterable, Identifiable, Sendable {
    case student
    case studentNumber
    case mastery
    case lastActive
    case status
    case risk

    var id: String { rawValue }

    var title: String {
        switch self {
        case .student: TutorStudioCopy.columnStudent
        case .studentNumber: TutorStudioCopy.columnStudentNumber
        case .mastery: TutorStudioCopy.columnMastery
        case .lastActive: TutorStudioCopy.columnLastActive
        case .status: TutorStudioCopy.columnStatus
        case .risk: TutorStudioCopy.columnRisk
        }
    }

    var csvHeader: String {
        switch self {
        case .student: "Student"
        case .studentNumber: "Student ID"
        case .mastery: "Mastery %"
        case .lastActive: "Last active"
        case .status: "Status"
        case .risk: "Risk flags"
        }
    }

    func csvValue(for enrollment: Enrollment, now: Date) -> String {
        switch self {
        case .student: enrollment.studentName
        case .studentNumber: enrollment.studentNumber
        case .mastery: "\(enrollment.masteryPercent)"
        case .lastActive: enrollment.lastActiveAt.map { $0.formatted(.iso8601) } ?? ""
        case .status: enrollment.status.rawValue
        case .risk: TutorStudentInsights.riskFlags(for: enrollment, now: now).map(\.rawValue).joined(separator: " ")
        }
    }

    func displayValue(for enrollment: Enrollment, now: Date) -> String {
        switch self {
        case .student: enrollment.studentName
        case .studentNumber: enrollment.studentNumber
        case .mastery: TutorStudioCopy.percent(enrollment.masteryPercent)
        case .lastActive: TutorStudentInsights.lastActiveText(enrollment, now: now)
        case .status: TutorStudioCopy.statusTitle(enrollment.status)
        case .risk: TutorStudentInsights.riskFlags(for: enrollment, now: now).map(TutorStudioCopy.riskTitle).joined(separator: ", ")
        }
    }
}

enum TutorGradebookFormat: String, CaseIterable, Identifiable, Sendable {
    case csv
    case pdf

    var id: String { rawValue }
    var fileExtension: String { rawValue }
}

enum TutorGradebook {

    static let defaultColumns: [TutorGradebookColumn] = [.student, .studentNumber, .mastery, .lastActive]

    static func rows(_ enrollments: [Enrollment], activeSince start: Date?, includeRemoved: Bool = false) -> [Enrollment] {
        enrollments
            .filter { includeRemoved || $0.status != .removed }
            .filter { enrollment in
                guard let start else { return true }
                guard let lastActive = enrollment.lastActiveAt else { return false }
                return lastActive >= start
            }
            .sorted { $0.studentName.localizedCaseInsensitiveCompare($1.studentName) == .orderedAscending }
    }

    static func ordered(_ columns: Set<TutorGradebookColumn>) -> [TutorGradebookColumn] {
        TutorGradebookColumn.allCases.filter { columns.contains($0) }
    }

    static func csv(_ rows: [Enrollment], columns: [TutorGradebookColumn], now: Date = .now) -> String {
        let header = columns.map { GradebookExporter.escape($0.csvHeader) }.joined(separator: ",")
        let lines = rows.map { enrollment in
            columns.map { GradebookExporter.escape($0.csvValue(for: enrollment, now: now)) }.joined(separator: ",")
        }
        return ([header] + lines).joined(separator: "\n")
    }

    @MainActor
    static func pdf(title: String, rows: [Enrollment], columns: [TutorGradebookColumn], now: Date = .now) -> Data {
        let page = CGRect(x: 0, y: 0, width: 842, height: 595)
        let margin: CGFloat = 36
        let rowHeight: CGFloat = 22
        let width = (page.width - margin * 2) / CGFloat(max(columns.count, 1))
        let titleFont = UIFont.boldSystemFont(ofSize: 18)
        let headerFont = UIFont.boldSystemFont(ofSize: 11)
        let bodyFont = UIFont.systemFont(ofSize: 11)
        let renderer = UIGraphicsPDFRenderer(bounds: page)

        return renderer.pdfData { context in
            var y = page.height
            func newPage() {
                context.beginPage()
                y = margin
                (title as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: titleFont])
                y += 32
                for (index, column) in columns.enumerated() {
                    let rect = CGRect(x: margin + CGFloat(index) * width, y: y, width: width - 6, height: rowHeight)
                    (column.title as NSString).draw(in: rect, withAttributes: [.font: headerFont])
                }
                y += rowHeight
            }
            newPage()
            for enrollment in rows {
                if y + rowHeight > page.height - margin { newPage() }
                for (index, column) in columns.enumerated() {
                    let rect = CGRect(x: margin + CGFloat(index) * width, y: y, width: width - 6, height: rowHeight)
                    (column.displayValue(for: enrollment, now: now) as NSString).draw(in: rect, withAttributes: [.font: bodyFont])
                }
                y += rowHeight
            }
        }
    }

    static func fileName(for course: Course, format: TutorGradebookFormat, now: Date = .now) -> String {
        let code = course.code.isEmpty ? "course" : course.code
        let safe = code.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }.joined(separator: "-")
        let day = now.formatted(.iso8601.year().month().day())
        return "\(safe.isEmpty ? "course" : safe)-gradebook-\(day).\(format.fileExtension)"
    }

    static func write(_ data: Data, named name: String, in directory: URL = FileManager.default.temporaryDirectory) throws -> URL {
        let folder = directory.appendingPathComponent("Gradebooks", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        return url
    }
}
