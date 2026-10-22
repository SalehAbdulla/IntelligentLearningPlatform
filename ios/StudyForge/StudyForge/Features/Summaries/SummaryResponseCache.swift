import Foundation

actor SummaryResponseCache {

    static let shared = SummaryResponseCache()

    private var entries: [String: AIGenerated<AISummary>] = [:]
    private var order: [String] = []
    private let capacity: Int

    init(capacity: Int = 32) {
        self.capacity = max(capacity, 1)
    }

    @MainActor
    static func key(for request: SummaryRequest) -> String {
        let focus = request.focusTopics
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
            .sorted()
            .joined(separator: ",")
        return AICostGovernor.cacheKey(
            text: request.context.text,
            language: request.context.language,
            learningStyle: request.context.learningStyle,
            variant: "summary|\(request.length.rawValue)|\(request.style.rawValue)|\(focus)"
        )
    }

    func value(for key: String) -> AIGenerated<AISummary>? {
        entries[key]
    }

    func store(_ value: AIGenerated<AISummary>, for key: String) {
        if entries[key] == nil {
            order.append(key)
        }
        entries[key] = value
        while order.count > capacity {
            let evicted = order.removeFirst()
            entries[evicted] = nil
        }
    }

    func removeAll() {
        entries.removeAll()
        order.removeAll()
    }

    var count: Int { entries.count }
}
