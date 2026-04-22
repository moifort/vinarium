import Apollo
import Foundation

enum DashboardAPI {
    static func getData() async throws -> DashboardData {
        let data = try await GraphQLHelpers.fetch(
            GraphQLClient.shared.apollo,
            query: VinariumGraphQL.DashboardQuery()
        )
        let d = data.dashboard
        return DashboardData(
            bottleCount: d.bottleCount,
            totalValue: d.totalValue,
            readyToDrink: d.readyToDrink.map {
                DashboardWine(
                    id: $0.id,
                    name: $0.name,
                    color: mapDashboardColor($0.color),
                    position: $0.position,
                    urgent: $0.urgent,
                    drinkUntil: $0.drinkUntil
                )
            },
            favorites: d.favorites.map {
                DashboardFavorite(
                    id: $0.id,
                    name: $0.name,
                    color: mapDashboardColor($0.color),
                    vintage: $0.vintage,
                    estimatedPrice: $0.estimatedPrice,
                    tastingDate: $0.tastingDate.flatMap { GraphQLHelpers.parseISO8601($0) }
                )
            },
            shortlist: d.shortlist.map {
                DashboardShortlistEntry(
                    id: $0.id,
                    name: $0.name,
                    color: mapDashboardColor($0.color),
                    vintage: $0.vintage,
                    estimatedPrice: $0.estimatedPrice,
                    tastingDate: $0.tastingDate.flatMap { GraphQLHelpers.parseISO8601($0) },
                    rating: $0.rating.map { Int($0) }
                )
            },
            lastBottle: d.lastBottle.map {
                DashboardEntry(
                    wine: DashboardEntryWine(
                        id: $0.wine.id,
                        name: $0.wine.name,
                        color: mapDashboardColor($0.wine.color),
                        vintage: $0.wine.vintage
                    ),
                    position: $0.position,
                    date: GraphQLHelpers.parseISO8601($0.date) ?? Date(),
                    rating: nil
                )
            },
            lastExit: d.lastExit.map { mapHistory($0) },
            history: d.history.map { mapHistory($0) }
        )
    }
}

private func mapDashboardColor(_ graphql: GraphQLEnum<VinariumGraphQL.WineColor>) -> WineColor {
    switch graphql {
    case .case(let value):
        switch value {
        case .red: return .red
        case .white: return .white
        case .rose: return .rosé
        case .sparkling: return .sparkling
        case .sweet: return .sweet
        }
    case .unknown:
        return .red
    }
}

private func mapHistory<T: DashboardJournalEvent>(_ e: T) -> DashboardHistoryEvent {
    DashboardHistoryEvent(
        type: e.eventType,
        date: GraphQLHelpers.parseISO8601(e.dateString) ?? Date(),
        wineId: e.wineIdString,
        wineName: e.wineNameString,
        wineColor: WineColor(rawValue: e.wineColorString.lowercased()) ?? .red,
        position: e.positionString,
        rating: nil
    )
}

protocol DashboardJournalEvent {
    var eventType: String { get }
    var dateString: String { get }
    var wineIdString: String { get }
    var wineNameString: String { get }
    var wineColorString: String { get }
    var positionString: String { get }
}

extension VinariumGraphQL.DashboardQuery.Data.Dashboard.LastExit: DashboardJournalEvent {
    var eventType: String {
        switch type { case .case(.in): return "in"; case .case(.out): return "out"; case .unknown: return "in" }
    }
    var dateString: String { date }
    var wineIdString: String { wineId }
    var wineNameString: String { wineName }
    var wineColorString: String { wineColor }
    var positionString: String { position }
}

extension VinariumGraphQL.DashboardQuery.Data.Dashboard.History: DashboardJournalEvent {
    var eventType: String {
        switch type { case .case(.in): return "in"; case .case(.out): return "out"; case .unknown: return "in" }
    }
    var dateString: String { date }
    var wineIdString: String { wineId }
    var wineNameString: String { wineName }
    var wineColorString: String { wineColor }
    var positionString: String { position }
}
