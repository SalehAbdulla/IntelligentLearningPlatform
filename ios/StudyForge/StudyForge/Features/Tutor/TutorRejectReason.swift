import Foundation

enum TutorRejectReason: String, CaseIterable, Identifiable, Sendable {
    case inaccurate
    case unsupported
    case offTopic
    case other

    var id: String { rawValue }

    static let noteMaxCharacters = 200

    var title: String {
        switch self {
        case .inaccurate: TutorStudioCopy.rejectInaccurate
        case .unsupported: TutorStudioCopy.rejectUnsupported
        case .offTopic: TutorStudioCopy.rejectOffTopic
        case .other: TutorStudioCopy.rejectOther
        }
    }

    var requiresNote: Bool { self == .other }

    func canSubmit(note: String) -> Bool {
        !requiresNote || !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func reasonText(note: String) -> String {
        let trimmed = String(note.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.noteMaxCharacters))
        if requiresNote { return trimmed }
        return trimmed.isEmpty ? title : TutorStudioCopy.reasonWithNote(title, trimmed)
    }
}
