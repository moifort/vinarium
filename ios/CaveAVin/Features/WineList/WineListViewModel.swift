import Foundation

enum WineSort: String, CaseIterable, Identifiable {
    case vintage, region, color, price
    var id: String { rawValue }
    var label: String {
        switch self {
        case .vintage: "Millésime"
        case .region: "Région"
        case .color: "Couleur"
        case .price: "Prix"
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
}

@MainActor @Observable
final class WineListViewModel {
    var wines: [Wine] = []
    var isLoading = false
    var error: String?
    var sort: WineSort = .vintage
    var sortDescending = true
    var statusFilter: WineStatusFilter = .all

    var filterKey: String {
        "\(sort.rawValue)-\(sortDescending)-\(statusFilter.rawValue)"
    }

    func load() async {
        isLoading = true
        error = nil
        do {
            wines = try await WineAPI.list(
                sort: sort.rawValue,
                order: sortDescending ? "desc" : "asc",
                status: statusFilter.rawValue
            )
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
