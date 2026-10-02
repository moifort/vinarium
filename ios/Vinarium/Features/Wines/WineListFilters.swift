import Foundation

/// The view, sort and filters the wine list was left on, kept in `UserDefaults` so that
/// coming back to the list — another tab, a rebuilt tab bar, a relaunch — finds it the
/// way the user set it instead of back on every wine sorted by date.
///
/// Forgotten when the session ends, with the screen snapshots: the next account opens
/// the list on its default view.
struct WineListFilters: Codable, Equatable {
    var mode: WineListMode = .all
    var sort: WineSort = .updatedAt
    var sortDescending = true
    var statusFilter: WineStatusFilter = .all
    var colorFilter: WineColor?
    var beverageTypeFilter: BeverageType?

    /// Every wine, most recently modified first: what the list opens on the first time.
    static let standard = WineListFilters()

    /// Names the snapshot of the list under these filters: each view, sort and filter
    /// keeps its own first page, so coming back to it shows its rows at once.
    var cacheKey: String {
        [
            "wine-list",
            mode.rawValue,
            sort.rawValue,
            sortDescending ? "desc" : "asc",
            statusFilter.rawValue,
            colorFilter?.rawValue ?? "any",
            beverageTypeFilter?.rawValue ?? "any",
        ].joined(separator: "-")
    }

    private static let key = "wine-list-filters"

    /// The filters saved last time, or the standard ones when there are none or they no
    /// longer decode — a case renamed since, for instance.
    static func stored() -> WineListFilters {
        guard let data = UserDefaults.standard.data(forKey: key),
              let filters = try? JSONDecoder().decode(WineListFilters.self, from: data)
        else { return .standard }
        return filters
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.key)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
