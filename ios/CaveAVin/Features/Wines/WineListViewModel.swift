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
        case .favorites: "Vos vins notés 5 étoiles"
        case .gifted: "Vins offerts à vos proches"
        case .recommended: "Vins recommandés par vos proches"
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

@MainActor @Observable
final class WineListViewModel {
    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    var wines: [Wine] = []
    var isLoading = false
    var hasWines = false
    private(set) var loadedFilterKey: String?
    var error: String?
    var sort: WineSort = .updatedAt
    var sortDescending = true
    var statusFilter: WineStatusFilter = .all
    var mode: WineListMode = .all

    var isDataStale: Bool { filterKey != loadedFilterKey }

    var displayedWines: [Wine] {
        switch mode {
        case .all: wines
        case .favorites: wines.filter { $0.rating == 5 }
        case .gifted: wines
        case .recommended: wines
        }
    }

    var groupedWines: [(String, [Wine])] {
        if sort == .contact { return contactGroupedWines }
        let keyed = displayedWines.map { wine -> (sortKey: Int, label: String, wine: Wine) in
            switch sort {
            case .updatedAt:
                let date = wine.updatedAt
                let calendar = Calendar.current
                let year = calendar.component(.year, from: date)
                let month = calendar.component(.month, from: date)
                let raw = Self.monthYearFormatter.string(from: date)
                let label = raw.prefix(1).uppercased() + raw.dropFirst()
                return (year * 100 + month, label, wine)
            case .vintage:
                let label = wine.vintage.map { "\($0)" } ?? "Sans millésime"
                return (wine.vintage ?? 0, label, wine)
            case .region:
                let label = wine.region ?? "Sans région"
                return (0, label, wine)
            case .color:
                return (0, wine.color.label, wine)
            case .price:
                let (order, label) = priceRange(wine.purchasePrice)
                return (order, label, wine)
            case .contact:
                return (0, "", wine) // unreachable: handled by early return above
            }
        }
        let grouped = Dictionary(grouping: keyed, by: \.label)
        let sorted: [(String, [Wine])]
        if sort == .region || sort == .color {
            let result = grouped.sorted { first, second in
                sortDescending ? first.key > second.key : first.key < second.key
            }
            sorted = result.map { ($0.key, $0.value.map(\.wine)) }
        } else {
            let representative = grouped.mapValues { entries in entries.first!.sortKey }
            let result = grouped.sorted { first, second in
                let a = representative[first.key]!
                let b = representative[second.key]!
                return sortDescending ? a > b : a < b
            }
            sorted = result.map { ($0.key, $0.value.map(\.wine)) }
        }
        return sorted
    }

    private var contactGroupedWines: [(String, [Wine])] {
        var groups: [String: [Wine]] = [:]
        var noContact: [Wine] = []
        for wine in displayedWines {
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
            sortDescending ? first.key > second.key : first.key < second.key
        }
        if !noContact.isEmpty {
            result.append(("Sans contact", noContact))
        }
        return result
    }

    private func priceRange(_ price: Double?) -> (order: Int, label: String) {
        guard let price else { return (999, "Sans prix") }
        switch price {
        case ..<10: return (0, "0-10 €")
        case ..<20: return (1, "10-20 €")
        case ..<50: return (2, "20-50 €")
        case ..<100: return (3, "50-100 €")
        default: return (4, "100+ €")
        }
    }

    var filterKey: String {
        "\(mode.rawValue)-\(sort.rawValue)-\(sortDescending)-\(statusFilter.rawValue)"
    }

    func load() async {
        isLoading = true
        error = nil
        do {
            let status: String? = switch mode {
            case .gifted: "gifted"
            case .recommended: "recommended"
            case .all, .favorites:
                statusFilter == .all ? nil : statusFilter.rawValue
            }
            let apiSort = sort == .contact ? "updatedAt" : sort.rawValue
            wines = try await WineAPI.list(
                sort: apiSort,
                order: sortDescending ? "desc" : "asc",
                status: status
            )
            if !wines.isEmpty { hasWines = true }
        } catch {
            self.error = error.localizedDescription
        }
        loadedFilterKey = filterKey
        isLoading = false
    }
}
