import Foundation
import SwiftUI

enum WineListMode: String, Codable, CaseIterable, Identifiable {
    case all, favorites, gifted, recommended
    var id: String { rawValue }
    var label: String {
        switch self {
        case .all: String(localized: "Tous")
        case .favorites: String(localized: "Favoris")
        case .gifted: String(localized: "Offerts")
        case .recommended: String(localized: "Conseillés")
        }
    }
    var icon: String {
        switch self {
        case .all: "wineglass"
        case .favorites: "heart.fill"
        case .gifted: "gift"
        case .recommended: "lightbulb"
        }
    }

    var title: String {
        switch self {
        case .all: String(localized: "Mes Vins")
        case .favorites: String(localized: "Favoris")
        case .gifted: String(localized: "Offerts")
        case .recommended: String(localized: "Conseillés")
        }
    }

    var subtitle: String {
        switch self {
        case .all: String(localized: "Tous vos vins ajoutés")
        case .favorites: String(localized: "Vos coups de cœur")
        case .gifted: String(localized: "Vins qu'on vous a offerts")
        case .recommended: String(localized: "Vins recommandés par vos proches")
        }
    }

    /// The status picker only makes sense on views that are not already filtered by status.
    var supportsStatusFilter: Bool {
        switch self {
        case .all, .favorites: true
        case .gifted, .recommended: false
        }
    }
}

enum WineSort: String, Codable, CaseIterable, Identifiable {
    case updatedAt, vintage, region, color, price, person
    var id: String { rawValue }
    var label: String {
        switch self {
        case .updatedAt: String(localized: "Date de modification")
        case .vintage: String(localized: "Millésime")
        case .region: String(localized: "Région")
        case .color: String(localized: "Couleur")
        case .price: String(localized: "Prix")
        case .person: String(localized: "Par personne")
        }
    }
    var icon: String {
        switch self {
        case .updatedAt: "clock"
        case .vintage: "calendar"
        case .region: "map"
        case .color: "paintpalette"
        case .price: "eurosign.circle"
        case .person: "person"
        }
    }

    /// Sorting by person only makes sense where every wine carries one: whoever gave
    /// the bottle (gifted view) or whoever recommended it (recommended view).
    static func available(for mode: WineListMode) -> [WineSort] {
        allCases.filter { $0 != .person || mode == .gifted || mode == .recommended }
    }
}

enum WineStatusFilter: String, Codable, CaseIterable, Identifiable {
    case all, inCellar = "in-cellar", consumed
    var id: String { rawValue }
    var label: String {
        switch self {
        case .all: String(localized: "Tous")
        case .inCellar: String(localized: "En cave")
        case .consumed: String(localized: "Consommés")
        }
    }
    var icon: String {
        switch self {
        case .all: "tray.full"
        case .inCellar: "cabinet"
        case .consumed: "wineglass"
        }
    }
}

private let wineMonthYearFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale.autoupdatingCurrent
    formatter.dateFormat = "MMMM yyyy"
    return formatter
}()

/// The paginated wine list. It opens on the page it closed on: its `SnapshotCache` hands
/// back the last visit's wines from disk before a single byte is asked of the network,
/// so a relaunch shows the list straight away and refreshes it silently underneath
/// instead of behind a loader taking the screen. Every view, sort and filter keeps its
/// own snapshot, so switching between them never empties the list either.
@MainActor @Observable
final class WineListViewModel {
    init() {
        let filters = WineListFilters.stored()
        mode = filters.mode
        sort = filters.sort
        sortDescending = filters.sortDescending
        statusFilter = filters.statusFilter
        colorFilter = filters.colorFilter
        beverageTypeFilter = filters.beverageTypeFilter
        wines = cache.read() ?? []
        rebuildPresentation()
        // A cached list has nothing to wait for: it is already readable.
        isLoading = wines.isEmpty
    }

    /// Pages accumulated from the server, in the current sort order.
    private(set) var wines: [Wine] = []
    /// Starts at true to avoid an "no wine" flash before the first load() — unless the
    /// cache opened the list, in which case there is nothing to wait for.
    var isLoading = true
    var isLoadingMore = false
    var hasMore = false
    /// Last loadMore failed: the sentinel goes rather than spin forever without a new
    /// attempt, and a pull reloads the list.
    private(set) var loadMoreFailed = false

    /// The first page of the view on screen, on disk. Bump the version whenever `Wine`
    /// changes shape.
    private var cache: SnapshotCache<[Wine]> { SnapshotCache(filters.cacheKey, version: 2) }

    var error: String?
    // Any view/sort/filter change is remembered and reloads page 0 from the server.
    // Restored in init, where assignments do not run these observers.
    var sort: WineSort = .updatedAt { didSet { if oldValue != sort { filtersChanged() } } }
    var sortDescending = true { didSet { if oldValue != sortDescending { filtersChanged() } } }
    var statusFilter: WineStatusFilter = .all {
        didSet { if oldValue != statusFilter { filtersChanged() } }
    }
    var colorFilter: WineColor? { didSet { if oldValue != colorFilter { filtersChanged() } } }
    var beverageTypeFilter: BeverageType? {
        didSet { if oldValue != beverageTypeFilter { filtersChanged() } }
    }
    var mode: WineListMode = .all {
        didSet {
            guard oldValue != mode else { return }
            // Sorting by person does not exist outside the gifted/recommended views,
            // so fall back to the default sort. Its didSet schedules a reload that is
            // redundant with ours (same request, one of the two wins): harmless, no flash.
            if !WineSort.available(for: mode).contains(sort) { sort = .updatedAt }
            filtersChanged()
        }
    }

    private var filters: WineListFilters {
        WineListFilters(
            mode: mode,
            sort: sort,
            sortDescending: sortDescending,
            statusFilter: statusFilter,
            colorFilter: colorFilter,
            beverageTypeFilter: beverageTypeFilter
        )
    }

    private func filtersChanged() {
        filters.save()
        scheduleReload()
    }

    private let pageSize = 15
    // Well below pageSize, otherwise the next page would load as soon as the first
    // one is displayed (unintended chain loading).
    private let prefetchThreshold = 5
    private var reloadTask: Task<Void, Never>?
    // Stale-result token: Apollo fetches are not cancellable, so a response from a
    // previous view can arrive AFTER the one for the current view. Every
    // scheduleReload invalidates the responses of earlier generations.
    private var generation = 0

    private(set) var groupedWines: [(String, [Wine])] = []

    /// Reloads page 0 for a new view, sort or filter, cancelling a previous reload still
    /// in flight (rapid filter changes). The new view's rows from its last visit show at
    /// once; without any, the rows on screen stay until the answer moves them into place.
    /// Only an empty list falls back on the loader. Called from the `didSet` hooks.
    func scheduleReload() {
        reloadTask?.cancel()
        generation += 1
        if let cached = cache.read() {
            withAnimation(wines.isEmpty ? nil : .smooth) {
                wines = cached
                rebuildPresentation()
            }
        }
        hasMore = false
        isLoadingMore = false // stale loadMore calls bail out without touching this state
        loadMoreFailed = false
        error = nil
        isLoading = true
        reloadTask = Task { await load() }
    }

    /// Refetches page 0 after a mutation without taking the rows away: the list stays
    /// on screen untouched, and the server's answer moves, inserts or removes rows in
    /// place — an edited wine climbs to the top, a scanned one slides in. Still
    /// invalidates the loadMore calls in flight, which would append stale rows.
    func reloadInPlace() {
        reloadTask?.cancel()
        generation += 1
        isLoadingMore = false
        loadMoreFailed = false
        reloadTask = Task { await load() }
    }

    /// Loads the first page (on a view/sort/filter change, on appear, on pull-to-refresh
    /// and after a mutation). The rows on screen stay while it runs; a failure leaves
    /// them as they were and says nothing, and a pull tries again.
    func load() async {
        let requested = generation
        isLoading = true
        error = nil
        do {
            let page = try await fetchPage(after: nil)
            guard requested == generation else { return } // response from a stale view
            // Over rows already on screen, the new ones slide into place and push the
            // others aside rather than the whole list redrawing at once.
            withAnimation(wines.isEmpty ? nil : .smooth) {
                wines = page.items
                hasMore = page.hasMore
                loadMoreFailed = false
                rebuildPresentation()
            }
            saveCache()
        } catch is CancellationError {
            // Reload cancelled by a more recent filter change, so ignore it.
            return
        } catch {
            guard requested == generation else { return }
            self.error = reportError(error)
        }
        isLoading = false
    }

    /// Loads the next page and appends it to the wines already loaded.
    func loadMore() async {
        guard hasMore, !isLoadingMore, let last = wines.last else { return }
        let requested = generation
        isLoadingMore = true
        loadMoreFailed = false
        do {
            let page = try await fetchPage(after: last.id)
            guard requested == generation else { return } // the view changed in the meantime
            wines.append(contentsOf: page.items)
            hasMore = page.hasMore
            rebuildPresentation()
        } catch is CancellationError {
            return
        } catch {
            guard requested == generation else { return }
            loadMoreFailed = true
            _ = reportError(error)
        }
        isLoadingMore = false
    }

    /// Triggers the next page load when a row close to the end appears (infinite scroll).
    func prefetchIfNeeded(for wineId: String) {
        guard hasMore, !isLoadingMore else { return }
        guard let index = wines.firstIndex(where: { $0.id == wineId }) else { return }
        if wines.count - index <= prefetchThreshold {
            Task { await loadMore() }
        }
    }

    /// Keep the first page of the view on screen on disk, under that view's own name.
    /// The file stays one page long however far the user scrolled. Written off the main
    /// actor: the list is on screen already and has nothing to gain from waiting on a
    /// file.
    private func saveCache() {
        let (cache, page) = (cache, Array(wines.prefix(pageSize)))
        Task.detached { cache.write(page) }
    }

    private func fetchPage(after: String?) async throws -> WinePage {
        try await WineAPI.list(
            mode: mode,
            sort: sort,
            sortDescending: sortDescending,
            statusFilter: statusFilter,
            color: colorFilter,
            beverageType: beverageTypeFilter,
            limit: pageSize,
            after: after
        )
    }

    // MARK: - Presentation: the server filters (view, status, color, type) and
    // paginates; grouping into sections is the only thing done locally.

    private func rebuildPresentation() {
        groupedWines = Self.buildGroupedWines(
            wines: wines,
            sort: sort,
            sortDescending: sortDescending,
            mode: mode
        )
    }

    /// Bucket for wines without a person when sorting by person is active.
    private static var unnamedPersonLabel: String { String(localized: "Sans nom") }

    private static func buildGroupedWines(
        wines: [Wine],
        sort: WineSort,
        sortDescending: Bool,
        mode: WineListMode
    ) -> [(String, [Wine])] {
        // Pre-sort so items inside each group follow the sort order too —
        // Dictionary(grouping:) preserves element order within groups.
        let sorted = wines.sorted {
            sortDescending ? sortValue($0, by: sort) > sortValue($1, by: sort)
                : sortValue($0, by: sort) < sortValue($1, by: sort)
        }

        let keyed = sorted.map { wine -> (sortKey: Double, label: String, wine: Wine) in
            switch sort {
            case .updatedAt:
                let calendar = Calendar.current
                let year = calendar.component(.year, from: wine.updatedAt)
                let month = calendar.component(.month, from: wine.updatedAt)
                let raw = wineMonthYearFormatter.string(from: wine.updatedAt)
                let label = raw.prefix(1).uppercased() + raw.dropFirst()
                return (Double(year * 100 + month), label, wine)
            case .vintage:
                let label = wine.vintage.map { "\($0)" } ?? String(localized: "Sans millésime")
                return (Double(wine.vintage ?? 0), label, wine)
            case .region:
                return (0, wine.region ?? String(localized: "Sans région"), wine)
            case .color:
                if let color = wine.color {
                    let order = WineColor.allCases.firstIndex(of: color) ?? 0
                    return (Double(order), color.label, wine)
                }
                // Beverages without a color (beer, spirits...) group by type, after the wines
                let order = WineColor.allCases.count
                    + (BeverageType.allCases.firstIndex(of: wine.beverageType) ?? 0)
                return (Double(order), wine.beverageType.label, wine)
            case .price:
                let (order, label) = priceRange(wine.purchasePrice)
                return (Double(order), label, wine)
            case .person:
                // Gifted view = whoever gave the bottle; recommended view = whoever
                // recommended it. (available(for:) hides this sort in the other views.)
                let name = mode == .gifted ? wine.giftedBy : wine.recommendedBy
                return (0, name ?? unnamedPersonLabel, wine)
            }
        }

        let grouped = Dictionary(grouping: keyed, by: \.label)
        let result: [(key: String, value: [(sortKey: Double, label: String, wine: Wine)])]
        if sort == .region || sort == .person {
            // These groups have no numeric key — order them alphabetically (French-aware),
            // with the "no person" bucket pinned last whatever the direction.
            result = grouped.sorted { first, second in
                if sort == .person {
                    if first.key == unnamedPersonLabel { return false }
                    if second.key == unnamedPersonLabel { return true }
                }
                let ascending = first.key.localizedCompare(second.key) == .orderedAscending
                return sortDescending ? !ascending : ascending
            }
        } else {
            let representative = grouped.mapValues { entries in entries.first!.sortKey }
            result = grouped.sorted { first, second in
                let a = representative[first.key]!
                let b = representative[second.key]!
                return sortDescending ? a > b : a < b
            }
        }
        return result.map { ($0.key, $0.value.map(\.wine)) }
    }

    /// Per-wine comparable for intra-group ordering, aligned with the group keys.
    private static func sortValue(_ wine: Wine, by sort: WineSort) -> Double {
        switch sort {
        case .updatedAt: wine.updatedAt.timeIntervalSince1970
        case .vintage: Double(wine.vintage ?? 0)
        case .region: 0 // groups carry the ordering; keep server order inside
        // The full-subset paths (gifted/recommended) come back unsorted from the
        // server, so order inside each person's section explicitly.
        case .person: wine.updatedAt.timeIntervalSince1970
        case .color:
            Double(
                wine.color.map { WineColor.allCases.firstIndex(of: $0) ?? 0 }
                    ?? WineColor.allCases.count
                        + (BeverageType.allCases.firstIndex(of: wine.beverageType) ?? 0)
            )
        case .price: wine.purchasePrice ?? 0
        }
    }

    private static func priceRange(_ price: Double?) -> (order: Int, label: String) {
        guard let price else { return (999, String(localized: "Sans prix")) }
        // Thresholds stay in euros (matching the stored price); the labels show
        // the boundaries converted to the user's display currency.
        func bound(_ eur: Double) -> String { Money.formattedFromEur(eur, fractionLength: 0) }
        switch price {
        case ..<10: return (0, "< \(bound(10))")
        case ..<20: return (1, "\(bound(10))–\(bound(20))")
        case ..<50: return (2, "\(bound(20))–\(bound(50))")
        case ..<100: return (3, "\(bound(50))–\(bound(100))")
        default: return (4, "\(bound(100))+")
        }
    }
}
