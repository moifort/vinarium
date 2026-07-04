import Foundation

enum WineListMode: String, CaseIterable, Identifiable {
    case all, favorites, gifted, recommended
    var id: String { rawValue }
    var label: String {
        switch self {
        case .all: "Tous"
        case .favorites: "Favoris"
        case .gifted: "Offerts"
        case .recommended: "Conseillés"
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
        case .all: "Mes Vins"
        case .favorites: "Favoris"
        case .gifted: "Offerts"
        case .recommended: "Conseillés"
        }
    }

    var subtitle: String {
        switch self {
        case .all: "Tous vos vins ajoutés"
        case .favorites: "Vos coups de cœur"
        case .gifted: "Vins qu'on vous a offerts"
        case .recommended: "Vins recommandés par vos proches"
        }
    }

    /// Le Picker Statut n'a de sens que sur les modes non déjà filtrés par statut.
    var supportsStatusFilter: Bool {
        switch self {
        case .all, .favorites: true
        case .gifted, .recommended: false
        }
    }
}

enum WineSort: String, CaseIterable, Identifiable {
    case updatedAt, vintage, region, color, price
    var id: String { rawValue }
    var label: String {
        switch self {
        case .updatedAt: "Date de modification"
        case .vintage: "Millésime"
        case .region: "Région"
        case .color: "Couleur"
        case .price: "Prix"
        }
    }
    var icon: String {
        switch self {
        case .updatedAt: "clock"
        case .vintage: "calendar"
        case .region: "map"
        case .color: "paintpalette"
        case .price: "eurosign.circle"
        }
    }
}

enum WineStatusFilter: String, CaseIterable, Identifiable {
    case all, inCellar = "in-cellar", consumed
    var id: String { rawValue }
    var label: String {
        switch self {
        case .all: "Tous"
        case .inCellar: "En cave"
        case .consumed: "Consommés"
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
    formatter.locale = Locale(identifier: "fr_FR")
    formatter.dateFormat = "MMMM yyyy"
    return formatter
}()

@MainActor @Observable
final class WineListViewModel {
    /// Pages accumulées depuis le serveur, dans l'ordre de tri courant.
    private(set) var wines: [Wine] = []
    /// Démarre à true pour éviter un flash « Aucun vin » avant le premier load().
    var isLoading = true
    var isLoadingMore = false
    var hasMore = false
    var totalCount = 0
    var hasWines = false
    var error: String?
    // Tout changement de vue/tri/filtre recharge la page 0 côté serveur.
    var sort: WineSort = .updatedAt { didSet { if oldValue != sort { scheduleReload() } } }
    var sortDescending = true { didSet { if oldValue != sortDescending { scheduleReload() } } }
    var statusFilter: WineStatusFilter = .all {
        didSet { if oldValue != statusFilter { scheduleReload() } }
    }
    var colorFilter: WineColor? { didSet { if oldValue != colorFilter { scheduleReload() } } }
    var beverageTypeFilter: BeverageType? {
        didSet { if oldValue != beverageTypeFilter { scheduleReload() } }
    }
    var mode: WineListMode = .all { didSet { if oldValue != mode { scheduleReload() } } }

    private let pageSize = 15
    private let prefetchThreshold = 10
    private var reloadTask: Task<Void, Never>?

    private(set) var groupedWines: [(String, [Wine])] = []

    /// Recharge la page 0, en annulant un rechargement précédent encore en cours
    /// (changements de filtre rapides). Vide la liste et repasse en chargement pour
    /// que la vue affiche le loader et reparte de zéro. Appelé par les `didSet` et
    /// la navigation.
    func scheduleReload() {
        reloadTask?.cancel()
        wines = []
        groupedWines = []
        hasMore = false
        isLoading = true
        reloadTask = Task { await load() }
    }

    /// Charge la première page (au changement de vue/tri/filtre, à l'apparition,
    /// au pull-to-refresh et après une mutation).
    func load() async {
        isLoading = true
        error = nil
        do {
            let page = try await fetchPage(after: nil)
            wines = page.items
            hasMore = page.hasMore
            totalCount = page.totalCount
            if !wines.isEmpty { hasWines = true }
        } catch is CancellationError {
            // Rechargement annulé par un changement de filtre plus récent — on ignore.
        } catch {
            self.error = reportError(error)
        }
        rebuildPresentation()
        isLoading = false
        continueLoadingIfFilteredEmpty()
    }

    /// Charge la page suivante et l'ajoute aux vins déjà chargés.
    func loadMore() async {
        guard hasMore, !isLoadingMore, let last = wines.last else { return }
        isLoadingMore = true
        do {
            let page = try await fetchPage(after: last.id)
            wines.append(contentsOf: page.items)
            hasMore = page.hasMore
            totalCount = page.totalCount
            rebuildPresentation()
        } catch is CancellationError {
        } catch {
            self.error = reportError(error)
        }
        isLoadingMore = false
        continueLoadingIfFilteredEmpty()
    }

    /// Les filtres couleur/type s'appliquent côté client : si la page courante ne
    /// contient aucun match mais qu'il reste des pages, on continue de charger
    /// jusqu'à trouver des résultats (ou épuiser la liste).
    private func continueLoadingIfFilteredEmpty() {
        guard groupedWines.isEmpty, hasMore, !isLoadingMore else { return }
        Task { await loadMore() }
    }

    /// Déclenche le chargement de la page suivante quand une ligne proche de la
    /// fin apparaît (infinite scroll).
    func prefetchIfNeeded(for wineId: String) {
        guard hasMore, !isLoadingMore else { return }
        guard let index = wines.firstIndex(where: { $0.id == wineId }) else { return }
        if wines.count - index <= prefetchThreshold {
            Task { await loadMore() }
        }
    }

    private func fetchPage(after: String?) async throws -> WinePage {
        try await WineAPI.list(
            mode: mode,
            sort: sort,
            sortDescending: sortDescending,
            statusFilter: statusFilter,
            color: colorFilter,
            limit: pageSize,
            after: after
        )
    }

    // MARK: - Presentation: le serveur filtre/trie par vue ; on regroupe en
    // sections localement (le filtre couleur reste appliqué côté client).

    private func rebuildPresentation() {
        let displayed = wines.filter { wine in
            (colorFilter == nil || wine.color == colorFilter)
                && (beverageTypeFilter == nil || wine.beverageType == beverageTypeFilter)
        }
        groupedWines = Self.buildGroupedWines(
            wines: displayed,
            sort: sort,
            sortDescending: sortDescending
        )
    }

    private static func buildGroupedWines(
        wines: [Wine],
        sort: WineSort,
        sortDescending: Bool
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
                let label = wine.vintage.map { "\($0)" } ?? "Sans millésime"
                return (Double(wine.vintage ?? 0), label, wine)
            case .region:
                return (0, wine.region ?? "Sans région", wine)
            case .color:
                if let color = wine.color {
                    let order = WineColor.allCases.firstIndex(of: color) ?? 0
                    return (Double(order), color.label, wine)
                }
                // Boissons sans couleur (bière, spiritueux...) : groupées par type, après les vins
                let order = WineColor.allCases.count
                    + (BeverageType.allCases.firstIndex(of: wine.beverageType) ?? 0)
                return (Double(order), wine.beverageType.label, wine)
            case .price:
                let (order, label) = priceRange(wine.purchasePrice)
                return (Double(order), label, wine)
            }
        }

        let grouped = Dictionary(grouping: keyed, by: \.label)
        let result: [(key: String, value: [(sortKey: Double, label: String, wine: Wine)])]
        if sort == .region {
            // Region groups have no numeric key — order them alphabetically (French-aware)
            result = grouped.sorted { first, second in
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
        guard let price else { return (999, "Sans prix") }
        switch price {
        case ..<10: return (0, "0-10 €")
        case ..<20: return (1, "10-20 €")
        case ..<50: return (2, "20-50 €")
        case ..<100: return (3, "50-100 €")
        default: return (4, "100+ €")
        }
    }
}
