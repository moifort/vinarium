import Foundation

enum WineListMode: String, CaseIterable, Identifiable {
    case all, favorites, gifted
    var id: String { rawValue }
    var label: String {
        switch self {
        case .all: "Tous"
        case .favorites: "❤️ Favoris"
        case .gifted: "🎁 Offerts"
        }
    }
}

enum WineSort: String, CaseIterable, Identifiable {
    case createdAt, vintage, region, color, price
    var id: String { rawValue }
    var label: String {
        switch self {
        case .createdAt: "Date d'ajout"
        case .vintage: "Millésime"
        case .region: "Région"
        case .color: "Couleur"
        case .price: "Prix"
        }
    }
    var icon: String {
        switch self {
        case .createdAt: "clock"
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
    var error: String?
    var sort: WineSort = .createdAt
    var sortDescending = true
    var statusFilter: WineStatusFilter = .all
    var mode: WineListMode = .all

    var displayedWines: [Wine] {
        switch mode {
        case .all: wines
        case .favorites: wines.filter { $0.rating == 5 }
        case .gifted: wines
        }
    }

    var groupedWines: [(String, [Wine])] {
        let keyed = displayedWines.map { wine -> (sortKey: Int, label: String, wine: Wine) in
            switch sort {
            case .createdAt:
                let date = wine.createdAt
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
            case .all, .favorites:
                statusFilter == .all ? nil : statusFilter.rawValue
            }
            wines = try await WineAPI.list(
                sort: sort.rawValue,
                order: sortDescending ? "desc" : "asc",
                status: status
            )
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
