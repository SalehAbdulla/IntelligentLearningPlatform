//
//  GradebookExporterTests.swift
//  StudyForgeTests
//
//  F11 — the CSV behind J10. The escaping tests are the point: a student named `O'Brien, Sara`
//  splits a naive export into two columns and nothing complains.
//

import Foundation
import Testing
@testable import StudyForge

@Suite("Gradebook export (F11)")
struct GradebookExporterTests {

    private func member(
        name: String = "Sara Ali",
        number: String = "202300001",
        mastery: Int = 80,
        lastActive: Date? = nil,
        status: EnrollmentStatus = .active
    ) -> Enrollment {
        Enrollment(
            courseId: "c1",
            uid: UUID().uuidString,
            studentName: name,
            studentNumber: number,
            masteryPercent: mastery,
            lastActiveAt: lastActive,
            status: status
        )
    }

    @Test("The header row is written even for an empty roster")
    func emptyRosterKeepsHeaders() {
        let csv = GradebookExporter.csv(for: [])
        #expect(csv.contains("Student"))
        #expect(csv.contains("Mastery %"))
        #expect(csv.split(separator: "\n").count == 1, "headers only, no data rows")
    }

    @Test("A plain row is written unquoted")
    func plainRow() {
        let csv = GradebookExporter.csv(
            for: [member()],
            columns: [.student, .studentNumber, .mastery]
        )
        let lines = csv.split(separator: "\n")

        #expect(lines.count == 2)
        #expect(lines[1] == "Sara Ali,202300001,80")
    }

    @Test("A comma in a name is quoted, so the row keeps its columns")
    func commaIsQuoted() {
        let csv = GradebookExporter.csv(
            for: [member(name: "O'Brien, Sara")],
            columns: [.student, .studentNumber]
        )
        let lines = csv.split(separator: "\n")

        #expect(lines[1] == "\"O'Brien, Sara\",202300001")
    }

    @Test("An interior quote is doubled, per RFC 4180")
    func quoteIsDoubled() {
        let csv = GradebookExporter.csv(for: [member(name: "Sara \"S\" Ali")], columns: [.student])
        #expect(csv.contains("\"Sara \"\"S\"\" Ali\""))
    }

    @Test("A missing last-active is an EMPTY cell, not the word Never")
    func missingLastActiveIsEmpty() {
        let csv = GradebookExporter.csv(for: [member(lastActive: nil)], columns: [.lastActive])
        let lines = csv.split(separator: "\n", omittingEmptySubsequences: false)

        #expect(lines[1].isEmpty, "a spreadsheet can average an empty cell and cannot average a word")
    }

    @Test("The status column writes the stored value, not a localised label")
    func statusIsAStoredValue() {
        let csv = GradebookExporter.csv(for: [member(status: .pending)], columns: [.status])
        #expect(csv.contains("pending"))
    }

    @Test("The date is ISO-8601, so the file is machine-readable before human-readable")
    func dateIsISO8601() {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let csv = GradebookExporter.csv(for: [member(lastActive: date)], columns: [.lastActive])

        #expect(csv.contains(date.formatted(.iso8601)))
    }

    @Test("Escaping is a no-op for text that needs no quoting")
    func escapeIsANoOp() {
        #expect(GradebookExporter.escape("Sara Ali") == "Sara Ali")
        #expect(GradebookExporter.escape("a,b") == "\"a,b\"")
        #expect(GradebookExporter.escape("a\"b") == "\"a\"\"b\"")
        #expect(GradebookExporter.escape("a\nb") == "\"a\nb\"")
    }
}
