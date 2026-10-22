import Foundation

enum SummaryCopy {

    static func text(_ key: String) -> String {
        Bundle.main.localizedString(forKey: key, value: nil, table: "Summaries")
    }

    static func format(_ key: String, _ arguments: any CVarArg...) -> String {
        String(format: text(key), locale: .current, arguments: arguments)
    }

    static var configureTitle: String { text("summary.configure.title") }
    static var focusOptionalLabel: String { text("summary.focus.optionalLabel") }
    static var focusHint: String { text("summary.focus.hint") }
    static var tldr: String { text("summary.tldr") }
    static func allowance(remaining: Int, limit: Int) -> String { format("summary.allowance", remaining, limit) }

    static func focusTooMany(_ limit: Int) -> String { format("summary.focus.error.tooMany", limit) }
    static func focusTooLong(_ limit: Int) -> String { format("summary.focus.error.tooLong", limit) }
    static var focusSymbols: String { text("summary.focus.error.symbols") }
    static var focusRepeated: String { text("summary.focus.error.repeated") }
    static var materialEmpty: String { text("summary.material.error.empty") }
    static func materialShort(minimum: Int, actual: Int) -> String { format("summary.material.error.short", minimum, actual) }
    static var editTitleError: String { text("summary.edit.error.title") }
    static var editTldrError: String { text("summary.edit.error.tldr") }
    static var editPointsError: String { text("summary.edit.error.points") }
    static func reset(hours: Int, minutes: Int) -> String { format("summary.reset", hours, minutes) }
    static var timedOut: String { text("summary.timedOut") }

    static var generatingHeading: String { text("summary.generating.heading") }
    static func generatingAccessibility(engine: String) -> String { format("summary.generating.a11y", engine) }

    static var edit: String { text("summary.action.edit") }
    static var save: String { text("summary.action.save") }
    static var saved: String { text("summary.action.saved") }
    static var share: String { text("summary.action.share") }
    static var cards: String { text("summary.action.cards") }
    static var edited: String { text("summary.edited") }
    static var discardTitle: String { text("summary.discard.title") }
    static var discardMessage: String { text("summary.discard.message") }
    static var discardConfirm: String { text("summary.discard.confirm") }
    static var cardsTitle: String { text("summary.cards.title") }
    static var cardsUnavailable: String { text("summary.cards.unavailable") }
    static var aiDrafted: String { text("summary.aiDrafted") }
    static var shareWatermark: String { text("summary.share.watermark") }
    static func shareSource(label: String, fileName: String, page: String) -> String { format("summary.share.source", label, fileName, page) }
    static func summaryTitle(_ materialTitle: String) -> String { format("summary.title.suffix", materialTitle) }

    static func page(_ number: Int) -> String { format("summary.page", number) }
    static func citeChip(_ number: Int) -> String { format("summary.chip.cite", number) }
    static func sourcePage(label: String, page: Int) -> String { format("summary.sourcePage", label, page) }
    static func sourceAccessibility(label: String, page: String) -> String { format("summary.a11y.source", label, page) }
    static func confidence(level: String, score: String) -> String { format("summary.confidence.label", level, score) }
    static var levelHigh: String { text("summary.level.high") }
    static var levelMedium: String { text("summary.level.medium") }
    static var levelLow: String { text("summary.level.low") }
    static func relevance(_ score: String) -> String { format("summary.relevance", score) }
    static var openInViewer: String { text("summary.openInViewer") }

    static var editSheetTitle: String { text("summary.edit.title") }
    static var titleField: String { text("summary.edit.titleField") }
    static var addKeyPoint: String { text("summary.edit.addPoint") }
    static func pointsFooter(count: Int, characters: Int) -> String { format("summary.edit.pointsFooter", count, characters) }
    static var watermarkToggle: String { text("summary.edit.watermarkToggle") }
    static func watermarkFooter(citation: String) -> String { format("summary.edit.watermarkFooter", citation) }
    static var discardChangesTitle: String { text("summary.edit.discardTitle") }
    static var keepEditing: String { text("summary.edit.keepEditing") }

    static var quotaTitle: String { text("summary.quota.title") }
    static func quotaBody(_ reset: String) -> String { format("summary.quota.body", reset) }
    static var quotaOnDevice: String { text("summary.quota.onDevice") }
    static var quotaOnDeviceSubtitle: String { text("summary.quota.onDeviceSubtitle") }
    static var quotaUpgrade: String { text("summary.quota.upgrade") }
    static var quotaUpgradeSubtitle: String { text("summary.quota.upgradeSubtitle") }
    static var quotaLater: String { text("summary.quota.later") }
    static var quotaUpgradeUnavailable: String { text("summary.quota.upgradeUnavailable") }

    static func viewerPage(_ number: Int) -> String { format("summary.viewer.page", number) }

    static var addToFolder: String { text("summary.folder.add") }
    static var folderTitle: String { text("summary.folder.title") }
    static var folderSearch: String { text("summary.folder.search") }
    static var folderNewPlaceholder: String { text("summary.folder.newPlaceholder") }
    static var folderCreate: String { text("summary.folder.create") }
    static func folderShared(members: Int) -> String { format("summary.folder.shared", members) }
    static var folderPrivate: String { text("summary.folder.private") }
    static var folderViewOnly: String { text("summary.folder.viewOnly") }
    static var folderAlready: String { text("summary.folder.already") }
    static func folderAdded(_ name: String) -> String { format("summary.folder.added", name) }
    static var folderEmpty: String { text("summary.folder.empty") }
    static func folderNoMatches(_ query: String) -> String { format("summary.folder.noMatches", query) }
    static var folderNameError: String { text("summary.folder.error.name") }
    static var folderUnavailable: String { text("summary.folder.unavailable") }
}
