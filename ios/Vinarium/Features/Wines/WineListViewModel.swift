import Foundation

enum WineListMode: String, CaseIterable, Identifiable {
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

enum WineSort: String, CaseIterable, Identifiable {
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

enum WineStatusFilter: String, CaseIterable, Identifiable {
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
/// so a relaunch shows the list straight away and refreshes it underneath —
/// `isRefreshing`, the spinner row leading the list, instead of a loader taking the
/// screen.
@MainActor @Observable
final class WineListViewModel {
    init() {
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
    /// Last loadMore failed: the sentinel turns into a retry button instead of a
    /// spinner that would keep turning forever without a new attempt.
    private(set) var loadMoreFailed = false

    /// A list already on screen is being brought up to date: the rows stay put and a
    /// spinner row leads the list. Set only on the cached list's refresh — a
    /// pull-to-refresh is left alone, the system's own control already spins for it.
    private(set) var isRefreshing = false

    /// That refresh failed: the rows on screen are the ones from last time, and the
    /// leading row offers to try again — otherwise nothing would say they are stale.
    private(set) var refreshFailed = false

    /// Page 0 has come back from the server at least once, so the rows on screen are no
    /// longer the cached ones.
    private var loaded = false

    /// The list's opening page on disk. Bump the version whenever `Wine` changes shape.
    private let cache = SnapshotCache<[Wine]>("wine-list", version: 1)

    var error: String?
    // Any view/sort/filter change reloads page 0 from the server.
    var sort: WineSort = .updatedAt { didSet { if oldValue != sort { scheduleReload() } } }
    var sortDescending = true { didSet { if oldValue != sortDescending { scheduleReload() } } }
    var statusFilter: WineStatusFilter = .all {
        didSet { if oldValue != statusFilter { scheduleReload() } }
    }
    var colorFilter: WineColor? { didSet { if oldValue != colorFilter { scheduleReload() } } }
    var beverageTypeFilter: BeverageType? {
        didSet { if oldValue != beverageTypeFilter { scheduleReload() } }
    }
    var mode: WineListMode = .all {
        didSet {
            guard oldValue != mode else { return }
            // Sorting by person does not exist outside the gifted/recommended views,
            // so fall back to the default sort. Its didSet schedules a reload that is
            // redundant with ours (same request, one of the two wins): harmless, no flash.
            if !WineSort.available(for: mode).contains(sort) { sort = .updatedAt }
            scheduleReload()
        }
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

    /// Reloads page 0, cancelling a previous reload still in flight (rapid filter
    /// changes). Clears the list and goes back to the loading state so the view shows
    /// the loader and starts over. Called from the `didSet` hooks and from navigation.
    func scheduleReload() {
        reloadTask?.cancel()
        generation += 1
        wines = []
        groupedWines = []
        hasMore = false
        isLoadingMore = false // stale loadMore calls bail out without touching this state
        loadMoreFailed = false
        isRefreshing = false
        refreshFailed = false
        isLoading = true
        reloadTask = Task { await load() }
    }

    /// Loads the first page (on a view/sort/filter change, on appear, on pull-to-refresh
    /// and after a mutation).
    func load() async {
        let requested = generation
        isLoading = true
        error = nil
        do {
            let page = try await fetchPage(after: nil)
            guard requested == generation else { return } // response from a stale view
            wines = page.items
            hasMore = page.hasMore
            loaded = true
            refreshFailed = false
            saveCache()
        } catch is CancellationError {
            // Reload cancelled by a more recent filter change, so ignore it.
            return
        } catch {
            guard requested == generation else { return }
            self.error = reportError(error)
        }
        rebuildPresentation()
        isLoading = false
    }

    /// The list appeared, or was asked to reload: a list still showing the last
    /// session's wines refreshes them under a leading spinner row, anything else loads
    /// as it always did — rows already fetched this session stay on screen silently.
    func loadOnAppear() async {
        if !loaded, !wines.isEmpty {
            await refresh()
        } else {
            await load()
        }
    }

    /// Bring the rows already on screen up to date without taking them away — the
    /// cached list's refresh, and the retry when that refresh failed.
    func refresh() async {
        isRefreshing = true
        refreshFailed = false
        await load()
        // A view, sort or filter change took the list over meanwhile: it emptied the
        // rows and reset both flags, and this refresh no longer has anything to say.
        guard isRefreshing else { return }
        isRefreshing = false
        refreshFailed = !loaded
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
            self.error = reportError(error)
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

    /// Keep the list's opening page on disk — only when the list is showing exactly
    /// that: every wine, the default order, no filter. Another view, sort or filter is
    /// not what the next launch opens on, and the file stays one page long however far
    /// the user scrolled. Written off the main actor: the list is on screen already and
    /// has nothing to gain from waiting on a file.
    private func saveCache() {
        guard mode == .all, sort == .updatedAt, sortDescending, statusFilter == .all,
              colorFilter == nil, beverageTypeFilter == nil
        else { return }
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
