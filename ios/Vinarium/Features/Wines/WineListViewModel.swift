import Foundation

enum WineListMode: String, CaseIterable, Identifiable {
    case all, favorites, shortlist, gifted, recommended
    var id: String { rawValue }
    var label: String {
        switch self {
        case .all: "Tous"
        case .favorites: "Favoris"
        case .shortlist: "À retenir"
        case .gifted: "Offerts"
        case .recommended: "Conseillés"
        }
    }
    var icon: String {
        switch self {
        case .all: "wineglass"
        case .favorites: "heart.fill"
        case .shortlist: "bookmark.fill"
        case .gifted: "gift"
        case .recommended: "lightbulb"
        }
    }

    var title: String {
        switch self {
        case .all: "Mes Vins"
        case .favorites: "Favoris"
        case .shortlist: "À retenir"
        case .gifted: "Offerts"
        case .recommended: "Conseillés"
        }
    }

    var subtitle: String {
        switch self {
        case .all: "Tous vos vins ajoutés"
        case .favorites: "Vos vins notés 5 étoiles"
        case .shortlist: "Vos vins à essayer encore"
        case .gifted: "Vins offerts à vos proches"
        case .recommended: "Vins recommandés par vos proches"
        }
    }

    /// Le Picker Statut n'a de sens que sur les modes non déjà filtrés par statut.
    var supportsStatusFilter: Bool {
        switch self {
        case .all, .favorites, .shortlist: true
        case .gifted, .recommended: false
        }
    }
}

enum WineSort: String, CaseIterable, Identifiable {
    case updatedAt, vintage, region, color, price, contact
    var id: String { rawValue }
    var label: String {
        switch self {
        case .updatedAt: "Date de modification"
        case .vintage: "Millésime"
        case .region: "Région"
        case .color: "Couleur"
        case .price: "Prix"
        case .contact: "Contact"
        }
    }
    var icon: String {
        switch self {
        case .updatedAt: "clock"
        case .vintage: "calendar"
        case .region: "map"
        case .color: "paintpalette"
        case .price: "eurosign.circle"
        case .contact: "person.2"
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
    /// Données brutes du serveur — remplies uniquement par `load()`.
    private(set) var allWines: [Wine] = []
    /// Démarre à true pour éviter un flash « Aucun vin » avant le premier load().
    var isLoading = true
    var hasWines = false
    var error: String?
    var sort: WineSort = .updatedAt { didSet { rebuildPresentation() } }
    var sortDescending = true { didSet { rebuildPresentation() } }
    var statusFilter: WineStatusFilter = .all { didSet { rebuildPresentation() } }
    var colorFilter: WineColor? { didSet { rebuildPresentation() } }
    var mode: WineListMode = .all { didSet { rebuildPresentation() } }

    private(set) var groupedWines: [(String, [Wine])] = []

    /// Seul point de contact réseau : appelé à l'apparition, au pull-to-refresh
    /// et après mutation. Les filtres/tris recalculent en mémoire.
    func load() async {
        isLoading = true
        error = nil
        do {
            allWines = try await WineAPI.list()
            if !allWines.isEmpty { hasWines = true }
        } catch {
            self.error = reportError(error)
        }
        rebuildPresentation()
        isLoading = false
    }

    // MARK: - Presentation pipeline: mode → statut → couleur → tri → groupage

    private func rebuildPresentation() {
        groupedWines = Self.buildGroupedWines(
            wines: filteredWines(),
            sort: sort,
            sortDescending: sortDescending
        )
    }

    private func filteredWines() -> [Wine] {
        var wines: [Wine] = switch mode {
        case .all: allWines
        case .favorites: allWines.filter { $0.rating == 5 }
        case .shortlist: allWines.filter { $0.shortlist == true && $0.rating != 5 }
        case .gifted: allWines.filter(\.isGifted)
        case .recommended: allWines.filter(\.isRecommended)
        }
        if mode.supportsStatusFilter {
            switch statusFilter {
            case .all: break
            case .inCellar: wines = wines.filter(\.isInCellar)
            case .consumed: wines = wines.filter { $0.consumedDate != nil }
            }
        }
        if let colorFilter {
            wines = wines.filter { $0.color == colorFilter }
        }
        return wines
    }

    private static func buildGroupedWines(
        wines: [Wine],
        sort: WineSort,
        sortDescending: Bool
    ) -> [(String, [Wine])] {
        if sort == .contact {
            return buildContactGroupedWines(displayed: wines, sortDescending: sortDescending)
        }

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
                let order = WineColor.allCases.firstIndex(of: wine.color) ?? 0
                return (Double(order), wine.color.label, wine)
            case .price:
                let (order, label) = priceRange(wine.purchasePrice)
                return (Double(order), label, wine)
            case .contact:
                return (0, "", wine) // unreachable: handled by early return above
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
        case .color: Double(WineColor.allCases.firstIndex(of: wine.color) ?? 0)
        case .price: wine.purchasePrice ?? 0
        case .contact: 0
        }
    }

    private static func buildContactGroupedWines(
        displayed: [Wine], sortDescending: Bool
    ) -> [(String, [Wine])] {
        var groups: [String: [Wine]] = [:]
        var noContact: [Wine] = []
        for wine in displayed {
            let contacts = wine.contacts ?? []
            if contacts.isEmpty {
                noContact.append(wine)
            } else {
                for contact in contacts {
                    groups[contact, default: []].append(wine)
                }
            }
        }
        var result = groups.sorted { first, second in
            let ascending = first.key.localizedCompare(second.key) == .orderedAscending
            return sortDescending ? !ascending : ascending
        }
        if !noContact.isEmpty {
            result.append(("Sans contact", noContact))
        }
        return result
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
