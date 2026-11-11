import Apollo
import Foundation

enum DashboardAPI {
    static func getData() async throws -> DashboardData {
        let data = try await GraphQLHelpers.fetch(
            GraphQLClient.shared.apollo,
            query: VinariumGraphQL.DashboardQuery()
        )
        let d = data.dashboard
        // A slot is named with its cellar once the household has several.
        let cellars = data.cellars.map { (id: $0.id, name: $0.name) }
        return DashboardData(
            bottleCount: d.bottleCount,
            capacity: d.capacity,
            totalValue: d.totalValue,
            readyToDrinkCount: d.readyToDrinkCount,
            favoriteCount: d.favoriteCount,
            readyToDrink: d.readyToDrink.map {
                DashboardWine(
                    id: $0.id,
                    name: $0.name,
                    beverageType: BeverageType(graphql: $0.beverageType),
                    subtype: $0.subtype.flatMap { BeverageSubtype(graphql: $0) },
                    producer: $0.producer,
                    color: $0.color.map { WineColor(graphql: $0) },
                    vintage: $0.vintage,
                    notes: $0.notes,
                    isFavorite: $0.isFavorite,
                    position: $0.position,
                    cellarName: CellarPositionLabel.cellarName(cellarId: $0.cellarId, cellars: cellars),
                    urgent: $0.urgent,
                    drinkFrom: $0.drinkFrom,
                    drinkUntil: $0.drinkUntil,
                    labelFamily: BottleArtwork.LabelFamily(graphql: $0.labelFamily),
                    appellation: $0.appellation,
                    classification: $0.classification,
                    estimatedPrice: $0.estimatedPrice,
                    stock: $0.stock
                )
            },
            favorites: d.favorites.map {
                DashboardFavorite(
                    id: $0.id,
                    name: $0.name,
                    beverageType: BeverageType(graphql: $0.beverageType),
                    subtype: $0.subtype.flatMap { BeverageSubtype(graphql: $0) },
                    producer: $0.producer,
                    color: $0.color.map { WineColor(graphql: $0) },
                    vintage: $0.vintage,
                    estimatedPrice: $0.estimatedPrice,
                    tastingDate: $0.tastingDate.flatMap { GraphQLHelpers.parseISO8601($0) },
                    rating: $0.rating.map { Int($0) },
                    labelFamily: BottleArtwork.LabelFamily(graphql: $0.labelFamily),
                    appellation: $0.appellation,
                    classification: $0.classification,
                    position: $0.position,
                    drinkUntil: $0.drinkUntil,
                    stock: $0.stock
                )
            },
            lastBottle: d.lastBottle.map {
                DashboardEntry(
                    wine: DashboardEntryWine(
                        id: $0.wine.id,
                        name: $0.wine.name,
                        beverageType: BeverageType(graphql: $0.wine.beverageType),
                        color: $0.wine.color.map { WineColor(graphql: $0) },
                        vintage: $0.wine.vintage
                    ),
                    position: CellarPositionLabel.text($0.position, cellarId: $0.cellarId, cellars: cellars),
                    date: GraphQLHelpers.parseISO8601($0.date) ?? Date(),
                    rating: nil
                )
            },
            lastExit: d.lastExit.map { mapHistory($0) },
            history: d.history.map { mapHistory($0) }
        )
    }
}

private func mapHistory<T: DashboardJournalEvent>(_ e: T) -> DashboardHistoryEvent {
    DashboardHistoryEvent(
        type: e.eventType,
        date: GraphQLHelpers.parseISO8601(e.dateString) ?? Date(),
        wineId: e.wineIdString,
        wineName: e.wineNameString,
        wineBeverageType: e.wineBeverageTypeValue,
        wineSubtype: e.wineSubtypeValue,
        wineColor: e.wineColorValue,
        wineVintage: e.wineVintageValue,
        position: e.positionString,
        rating: nil,
        memberName: e.memberNameValue,
        producer: e.producerValue,
        labelFamily: e.labelFamilyValue
    )
}

protocol DashboardJournalEvent {
    var eventType: String { get }
    var dateString: String { get }
    var wineIdString: String { get }
    var wineNameString: String { get }
    var wineBeverageTypeValue: BeverageType { get }
    var wineSubtypeValue: BeverageSubtype? { get }
    var wineColorValue: WineColor? { get }
    var wineVintageValue: Int? { get }
    var positionString: String { get }
    /// The household member behind the move, nil when it was you.
    var memberNameValue: String? { get }
    var producerValue: String? { get }
    var labelFamilyValue: BottleArtwork.LabelFamily? { get }
}

extension BottleArtwork.LabelFamily {
    /// The family the API names, nil for one this build does not draw yet.
    init?(graphql value: GraphQLEnum<VinariumGraphQL.LabelFamily>) {
        self.init(rawValue: value.rawValue.lowercased())
    }
}

extension VinariumGraphQL.DashboardQuery.Data.Dashboard.LastExit: DashboardJournalEvent {
    var eventType: String {
        switch type { case .case(.in): return "in"; case .case(.out): return "out"; case .unknown: return "in" }
    }
    var dateString: String { date }
    var wineIdString: String { beverageId }
    var wineNameString: String { beverageName }
    var wineBeverageTypeValue: BeverageType { BeverageType(graphql: wineBeverageType) }
    var wineSubtypeValue: BeverageSubtype? { wineSubtype.flatMap { BeverageSubtype(graphql: $0) } }
    var wineColorValue: WineColor? { wineColor.map { WineColor(graphql: $0) } }
    var wineVintageValue: Int? { wineVintage }
    var positionString: String { position }
    var memberNameValue: String? { actor.isMine ? nil : actor.displayName }
    var producerValue: String? { beverageProducer }
    var labelFamilyValue: BottleArtwork.LabelFamily? { BottleArtwork.LabelFamily(graphql: wineLabelFamily) }
}

extension VinariumGraphQL.DashboardQuery.Data.Dashboard.History: DashboardJournalEvent {
    var eventType: String {
        switch type { case .case(.in): return "in"; case .case(.out): return "out"; case .unknown: return "in" }
    }
    var dateString: String { date }
    var wineIdString: String { beverageId }
    var wineNameString: String { beverageName }
    var wineBeverageTypeValue: BeverageType { BeverageType(graphql: wineBeverageType) }
    var wineSubtypeValue: BeverageSubtype? { wineSubtype.flatMap { BeverageSubtype(graphql: $0) } }
    var wineColorValue: WineColor? { wineColor.map { WineColor(graphql: $0) } }
    var wineVintageValue: Int? { wineVintage }
    var positionString: String { position }
    var memberNameValue: String? { actor.isMine ? nil : actor.displayName }
    var producerValue: String? { beverageProducer }
    var labelFamilyValue: BottleArtwork.LabelFamily? { BottleArtwork.LabelFamily(graphql: wineLabelFamily) }
}
