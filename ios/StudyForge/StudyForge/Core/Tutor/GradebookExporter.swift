//
//  GradebookExporter.swift
//  StudyForge
//
//  F11 — the CSV behind J10's "Export CSV" (docs/03 §J J10).
//
//  WHY THIS IS A PURE FUNCTION AND NOT A VIEW MODEL METHOD
//  ------------------------------------------------------
//  A CSV that a spreadsheet refuses to open is worse than no export at all, and the failure
//  is silent: a student named `O'Brien, Sara` splits into two columns and nothing complains.
//  So the escaping is written once, tested directly, and the view model only chooses rows.
//
//  WHY THE HEADERS ARE ENGLISH
//  ---------------------------
//  A CSV header is a WIRE FORMAT, not copy — the same treatment `MaterialSource.storageValue`
//  gets. Localising `"Student ID"` would mean a column that changes name with the device
//  language, which breaks every saved spreadsheet formula and every script a tutor wrote
//  against their own export. The tutor-facing SCREEN is fully localised; the file it produces
//  is stable.
//

import Foundation

/// One column of the gradebook (J10's "column config").
enum GradebookColumn: String, Sendable, Codable, CaseIterable, Identifiable {

    case student
    case studentNumber
    case mastery
    case lastActive
    case status

    var id: String { rawValue }

    /// The column name written to the file. See the note at the top of this file.
    var csvHeader: String {
        switch self {
        case .student: "Student"
        case .studentNumber: "Student ID"
        case .mastery: "Mastery %"
        case .lastActive: "Last active"
        case .status: "Status"
        }
    }

    /// The cell value for one enrolment.
    ///
    /// Dates are ISO-8601 and statuses are their stored raw values, so the file is machine-
    /// readable before it is human-readable. An absent last-active is an EMPTY cell rather
    /// than "Never": a spreadsheet can average an empty cell and cannot average a word.
    func value(for enrollment: Enrollment) -> String {
        switch self {
        case .student: enrollment.studentName
        case .studentNumber: enrollment.studentNumber
        case .mastery: "\(enrollment.masteryPercent)"
        case .lastActive: enrollment.lastActiveAt.map { $0.formatted(.iso8601) } ?? ""
        case .status: enrollment.status.rawValue
        }
    }
}

/// Builds the gradebook CSV.
enum GradebookExporter {

    /// The columns shown by default — the four J10 lists, without the status column, which is
    /// only interesting once a roster has pending requests.
    static let defaultColumns: [GradebookColumn] = [.student, .studentNumber, .mastery, .lastActive]

    /// A CSV of the given enrolments and columns.
    ///
    /// An empty roster still produces the HEADER row: a file with zero bytes looks like a
    /// failed export, whereas a file with headers and no rows is unambiguously an empty class.
    /// Callers that want to warn about the empty case check `enrollments.isEmpty` themselves.
    static func csv(for enrollments: [Enrollment], columns: [GradebookColumn] = defaultColumns) -> String {
        let header = columns.map { escape($0.csvHeader) }.joined(separator: ",")
        let rows = enrollments.map { enrollment in
            columns.map { escape($0.value(for: enrollment)) }.joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n")
    }

    /// Quotes a field when it needs it, and doubles any interior quote.
    ///
    /// RFC 4180: a field is quoted if it contains a comma, a quote or a newline, and an
    /// interior quote becomes two. Getting this wrong is invisible until someone's name has a
    /// comma in it — which, in a cohort of real students, it will.
    static func escape(_ field: String) -> String {
        guard field.contains(",") || field.contains("\"") || field.contains("\n") else {
            return field
        }
        return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
