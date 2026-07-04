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
    var bottlesHasMore = false
    var isLoadingMoreBottles = false
    var history: [HistoryEvent] = []
    var historyHasMore = false
    var isLoadingMoreHistory = false
    var displayMode: CellarDisplayMode = .cave
    var isLoading = false
    var error: String?

    private let pageSize = 15
    private let prefetchThreshold = 5
    // Jeton anti-résultats périmés : un load() (pull-to-refresh, retour de scan)
    // invalide les loadMore encore en vol, sinon leur réponse tardive ajouterait
    // des doublons aux listes fraîchement rechargées.
    private var generation = 0

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
        generation += 1
        let requested = generation
        isLoadingMoreBottles = false
        isLoadingMoreHistory = false
        isLoading = true
        error = nil
        do {
            async let bottlesData = CellarAPI.getBottles(limit: pageSize, after: nil)
            async let historyData = CellarAPI.getHistory(limit: pageSize, offset: 0)
            let (b, h) = try await (bottlesData, historyData)
            guard requested == generation else { return } // un reload plus récent a pris la main
            bottles = b.bottles
            bottlesHasMore = b.hasMore
            history = h.events
            historyHasMore = h.hasMore
        } catch {
            guard requested == generation else { return }
            self.error = reportError(error)
        }
        isLoading = false
    }

    /// Charge la page suivante de bouteilles et l'ajoute à la grille.
    func loadMoreBottles() async {
        guard bottlesHasMore, !isLoadingMoreBottles, let last = bottles.last else { return }
        let requested = generation
        isLoadingMoreBottles = true
        do {
            let page = try await CellarAPI.getBottles(limit: pageSize, after: last.wineId)
            guard requested == generation else { return } // la liste a été rechargée entre-temps
            bottles.append(contentsOf: page.bottles)
            bottlesHasMore = page.hasMore
        } catch {
            guard requested == generation else { return }
            self.error = reportError(error)
        }
        isLoadingMoreBottles = false
    }

    /// Déclenche le chargement quand une bouteille proche de la fin apparaît.
    func prefetchBottlesIfNeeded(for wineId: String) {
        guard bottlesHasMore, !isLoadingMoreBottles else { return }
        guard let index = bottles.firstIndex(where: { $0.wineId == wineId }) else { return }
        if bottles.count - index <= prefetchThreshold {
            Task { await loadMoreBottles() }
        }
    }

    /// Charge la page suivante du journal et l'ajoute à l'historique.
    func loadMoreHistory() async {
        guard historyHasMore, !isLoadingMoreHistory else { return }
        let requested = generation
        isLoadingMoreHistory = true
        do {
            let page = try await CellarAPI.getHistory(limit: pageSize, offset: history.count)
            guard requested == generation else { return } // la liste a été rechargée entre-temps
            history.append(contentsOf: page.events)
            historyHasMore = page.hasMore
        } catch {
            guard requested == generation else { return }
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
