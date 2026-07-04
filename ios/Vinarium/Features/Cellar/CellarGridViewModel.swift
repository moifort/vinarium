import Foundation

enum CellarDisplayMode: String, CaseIterable, Identifiable {
    case cave = "Cave"
    case journal = "Journal"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .cave: "cabinet"
        case .journal: "clock"
        }
    }

    var label: String { rawValue }

    var title: String {
        switch self {
        case .cave: "Ma Cave"
        case .journal: "Journal"
        }
    }

    var subtitle: String {
        switch self {
        case .cave: "Vos bouteilles en cave"
        case .journal: "Historique des entrées et sorties"
        }
    }
}

@MainActor @Observable
final class CellarGridViewModel {
    var bottles: [CellarBottle] = []
    var history: [HistoryEvent] = []
    var historyHasMore = false
    var isLoadingMoreHistory = false
    var displayMode: CellarDisplayMode = .cave
    var isLoading = false
    var error: String?

    private let historyPageSize = 15
    private let prefetchThreshold = 5

    var groupedRows: [CellarRowGroup] {
        Dictionary(grouping: bottles, by: \.rowLabel)
            .sorted(by: { $0.key < $1.key })
            .map { row, items in
                CellarRowGroup(
                    row: row,
                    items: items.sorted(by: { $0.colLabel < $1.colLabel }).map {
                        CellarRowItem(
                            id: $0.wine.id,
                            name: $0.wine.name,
                            beverageType: $0.wine.beverageType,
                            color: $0.wine.color,
                            vintage: $0.wine.vintage,
                            position: $0.position
                        )
                    }
                )
            }
    }

    func load() async {
        isLoading = true
        error = nil
        do {
            async let bottlesData = CellarAPI.getBottles()
            async let historyData = CellarAPI.getHistory(limit: historyPageSize, offset: 0)
            let (b, h) = try await (bottlesData, historyData)
            bottles = b
            history = h.events
            historyHasMore = h.hasMore
        } catch {
            self.error = reportError(error)
        }
        isLoading = false
    }

    /// Charge la page suivante du journal et l'ajoute à l'historique.
    func loadMoreHistory() async {
        guard historyHasMore, !isLoadingMoreHistory else { return }
        isLoadingMoreHistory = true
        do {
            let page = try await CellarAPI.getHistory(limit: historyPageSize, offset: history.count)
            history.append(contentsOf: page.events)
            historyHasMore = page.hasMore
        } catch {
            self.error = reportError(error)
        }
        isLoadingMoreHistory = false
    }

    /// Déclenche le chargement quand un événement proche de la fin apparaît.
    func prefetchHistoryIfNeeded(for eventId: String) {
        guard historyHasMore, !isLoadingMoreHistory else { return }
        guard let index = history.firstIndex(where: { $0.id == eventId }) else { return }
        if history.count - index <= prefetchThreshold {
            Task { await loadMoreHistory() }
        }
    }
}
