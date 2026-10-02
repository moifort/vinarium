import Foundation
import SwiftUI

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

    var label: String {
        switch self {
        case .cave: String(localized: "Cave")
        case .journal: String(localized: "Journal")
        }
    }

    var title: String {
        switch self {
        case .cave: String(localized: "Ma Cave")
        case .journal: String(localized: "Journal")
        }
    }

    var subtitle: String {
        switch self {
        case .cave: String(localized: "Vos bouteilles en cave")
        case .journal: String(localized: "Historique des entrées et sorties")
        }
    }
}

/// The cellar tab: the bottles row by row, and the journal of what came in and out. It
/// opens on what it showed last time: its `SnapshotCache` hands the first page of each
/// back from disk before anything is asked of the network, and the first fetch replaces
/// it silently instead of behind a loader. Every cellar keeps its own snapshot, so
/// switching between them never empties the list either.
@MainActor @Observable
final class CellarGridViewModel {
    init() {
        selectedCellarId = CellarSelection.stored()
        if let snapshot = cache.read() {
            bottles = snapshot.bottles
            history = snapshot.history
            cellars = snapshot.cellars
        }
    }

    /// Every cellar of the household; the picker shows once there are two.
    private(set) var cellars: [CellarSummary] = []
    /// The cellar on screen, nil for the primary one. Switching reloads its bottles.
    var selectedCellarId: String? {
        didSet {
            guard oldValue != selectedCellarId else { return }
            CellarSelection.save(selectedCellarId)
            // The new cellar's bottles from its last visit show at once; without any,
            // the list empties rather than show another cellar's bottles under its name.
            let cached = cache.read()
            withAnimation(bottles.isEmpty ? nil : .smooth) {
                bottles = cached?.bottles ?? []
            }
            bottlesHasMore = false
            Task { await load() }
        }
    }

    var selectedCellar: CellarSummary? {
        cellars.first { $0.id == selectedCellarId } ?? cellars.first
    }

    var bottles: [CellarBottle] = []
    var bottlesHasMore = false
    var isLoadingMoreBottles = false
    private(set) var bottlesLoadMoreFailed = false
    var history: [HistoryEvent] = []
    var historyHasMore = false
    /// Where the next journal page starts: right after the last event read.
    private var historyCursor: String?
    var isLoadingMoreHistory = false
    private(set) var historyLoadMoreFailed = false
    var displayMode: CellarDisplayMode = .cave
    var isLoading = false
    var error: String?

    /// The first page of bottles and of the journal on disk, one file per cellar. Bump
    /// the version whenever `CellarBottle`, `Wine` or `HistoryEvent` changes shape.
    private var cache: SnapshotCache<CellarSnapshot> {
        SnapshotCache("cellar-\(selectedCellarId ?? "primary")", version: 3)
    }

    private let pageSize = 15
    private let prefetchThreshold = 5
    // Stale-result token: a load() (pull-to-refresh, return from a scan) invalidates
    // the loadMore calls still in flight, otherwise their late response would append
    // duplicates to the freshly reloaded lists.
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
                            producer: $0.wine.listDomain,
                            beverageType: $0.wine.beverageType,
                            color: $0.wine.color,
                            vintage: $0.wine.vintage,
                            position: $0.position,
                            ownerName: $0.ownerName
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
        bottlesLoadMoreFailed = false
        historyLoadMoreFailed = false
        isLoading = true
        error = nil
        do {
            let overview: CellarOverview
            do {
                overview = try await CellarAPI.overview(limit: pageSize, cellarId: selectedCellarId)
            } catch let error as APIError where error.domainCode == "NOT_FOUND" && selectedCellarId != nil {
                // The cellar left on was deleted, or left behind with a household:
                // fall back on the primary one rather than on an error.
                guard requested == generation else { return }
                selectedCellarId = nil
                return
            }
            guard requested == generation else { return } // a more recent reload took over
            let (b, h) = (overview.bottles, overview.history)
            cellars = overview.cellars
            // Over rows already on screen, the new ones slide into place and push the
            // others aside rather than the whole list redrawing at once.
            withAnimation(bottles.isEmpty && history.isEmpty ? nil : .smooth) {
                bottles = b.bottles
                bottlesHasMore = b.hasMore
                history = h.events
                historyHasMore = h.hasMore
            }
            historyCursor = h.endCursor
            let snapshot = CellarSnapshot(
                bottles: b.bottles,
                history: h.events,
                cellars: overview.cellars,
                cellarId: selectedCellarId
            )
            let cache = cache
            Task.detached { cache.write(snapshot) }
        } catch {
            guard requested == generation else { return }
            self.error = reportError(error)
        }
        isLoading = false
    }

    /// Loads the next page of bottles and appends it to the grid.
    func loadMoreBottles() async {
        guard bottlesHasMore, !isLoadingMoreBottles, let last = bottles.last else { return }
        let requested = generation
        isLoadingMoreBottles = true
        bottlesLoadMoreFailed = false
        do {
            let page = try await CellarAPI.getBottles(
                limit: pageSize,
                after: last.wineId,
                cellarId: selectedCellarId
            )
            guard requested == generation else { return } // the list was reloaded in the meantime
            bottles.append(contentsOf: page.bottles)
            bottlesHasMore = page.hasMore
        } catch {
            guard requested == generation else { return }
            bottlesLoadMoreFailed = true
            _ = reportError(error)
        }
        isLoadingMoreBottles = false
    }

    /// Triggers the next load when a bottle close to the end appears.
    func prefetchBottlesIfNeeded(for wineId: String) {
        guard bottlesHasMore, !isLoadingMoreBottles else { return }
        guard let index = bottles.firstIndex(where: { $0.wineId == wineId }) else { return }
        if bottles.count - index <= prefetchThreshold {
            Task { await loadMoreBottles() }
        }
    }

    /// Loads the next page of the journal and appends it to the history.
    func loadMoreHistory() async {
        guard historyHasMore, !isLoadingMoreHistory else { return }
        let requested = generation
        isLoadingMoreHistory = true
        historyLoadMoreFailed = false
        do {
            let page = try await CellarAPI.getHistory(limit: pageSize, after: historyCursor)
            guard requested == generation else { return } // the list was reloaded in the meantime
            history.append(contentsOf: page.events)
            historyHasMore = page.hasMore
            historyCursor = page.endCursor
        } catch {
            guard requested == generation else { return }
            historyLoadMoreFailed = true
            _ = reportError(error)
        }
        isLoadingMoreHistory = false
    }

    /// Triggers the next load when an event close to the end appears.
    func prefetchHistoryIfNeeded(for eventId: String) {
        guard historyHasMore, !isLoadingMoreHistory else { return }
        guard let index = history.firstIndex(where: { $0.id == eventId }) else { return }
        if history.count - index <= prefetchThreshold {
            Task { await loadMoreHistory() }
        }
    }
}
