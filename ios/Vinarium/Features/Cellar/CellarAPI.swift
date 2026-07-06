import Apollo
import Foundation

/// One page of cellar journal events.
struct HistoryPage {
    let events: [HistoryEvent]
    let hasMore: Bool
}

/// One page of cellar bottles.
struct BottlesPage {
    let bottles: [CellarBottle]
    let hasMore: Bool
}

enum CellarAPI {
    static func getBottles(limit: Int, after: String?) async throws -> BottlesPage {
        let data = try await GraphQLHelpers.fetch(
            GraphQLClient.shared.apollo,
            query: VinariumGraphQL.CellarBottlesQuery(
                limit: .some(limit),
                after: GraphQLHelpers.graphQLNullable(after)
            )
        )
        let bottles = data.cellarBottles.items.map { b in
            CellarBottle(
                wineId: b.wineId,
                wine: Wine(
                    id: b.wine.id,
                    name: b.wine.name,
                    beverageType: BeverageType(graphql: b.wine.beverageType),
                    color: b.wine.color.map { WineColor(graphql: $0) },
                    subtype: b.wine.subtype.flatMap { BeverageSubtype(graphql: $0) },
                    domain: b.wine.domain,
                    vintage: b.wine.vintage,
                    appellation: b.wine.appellation,
                    region: b.wine.region,
                    country: b.wine.country,
                    classification: b.wine.classification,
                    purchasePrice: b.wine.purchase?.price,
                    drinkFrom: b.wine.drinkWindow?.from,
                    drinkUntil: b.wine.drinkWindow?.until,
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                rowLabel: b.rowLabel,
                colLabel: b.colLabel,
                createdAt: GraphQLHelpers.parseISO8601(b.createdAt) ?? Date()
            )
        }
        return BottlesPage(bottles: bottles, hasMore: data.cellarBottles.hasMore)
    }

    /// Toutes les bouteilles de la cave (grille complète pour placer/déplacer une
    /// bouteille). La cave est bornée par sa capacité physique : une grande page
    /// la couvre entièrement.
    static func getAllBottles() async throws -> [CellarBottle] {
        try await getBottles(limit: 1000, after: nil).bottles
    }

    static func getHistory(limit: Int, offset: Int) async throws -> HistoryPage {
        let data = try await GraphQLHelpers.fetch(
            GraphQLClient.shared.apollo,
            query: VinariumGraphQL.CellarHistoryQuery(limit: .some(limit), offset: .some(offset))
        )
        let events = data.journalEvents.items.map { e in
            HistoryEvent(
                type: mapEventType(e.type),
                date: GraphQLHelpers.parseISO8601(e.date) ?? Date(),
                wineId: e.wineId,
                wineName: e.wineName,
                wineBeverageType: BeverageType(graphql: e.wineBeverageType),
                wineColor: e.wineColor.map { WineColor(graphql: $0) },
                position: e.position
            )
        }
        return HistoryPage(events: events, hasMore: data.journalEvents.hasMore)
    }

    static func suggest() async throws -> CellarSuggestion {
        let data = try await GraphQLHelpers.fetch(
            GraphQLClient.shared.apollo,
            query: VinariumGraphQL.SuggestCellarPositionQuery()
        )
        guard let position = data.suggestCellarPosition else {
            throw APIError.invalidResponse
        }
        return CellarSuggestion(row: position.rowLabel, col: position.colLabel)
    }

    static func place(wineId: String, row: String, col: Int) async throws {
        let rowIndex = rowIndexFromLabel(row)
        _ = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.PlaceBottleMutation(wineId: wineId, row: rowIndex, col: col)
        )
    }

    static func move(wineId: String, row: String, col: Int) async throws {
        let rowIndex = rowIndexFromLabel(row)
        _ = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.MoveBottleMutation(wineId: wineId, row: rowIndex, col: col)
        )
    }

    static func remove(
        wineId: String,
        consumedDate: String? = nil,
        rating: Int? = nil,
        tastingNotes: String? = nil,
        contacts: [String]? = nil
    ) async throws {
        let input = VinariumGraphQL.ConsumptionInput(
            consumedDate: GraphQLHelpers.graphQLNullable(consumedDate),
            contacts: GraphQLHelpers.graphQLNullable(contacts),
            favorite: .none,
            rating: GraphQLHelpers.graphQLNullable(rating),
            tastingNotes: GraphQLHelpers.graphQLNullable(tastingNotes)
        )
        _ = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.ConsumeBottleMutation(wineId: wineId, input: input)
        )
    }

    static func gift(
        wineId: String,
        giftedDate: String,
        recipientName: String?
    ) async throws {
        let input = VinariumGraphQL.GiftInput(
            giftedDate: giftedDate,
            recipientName: GraphQLHelpers.graphQLNullable(recipientName)
        )
        _ = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.GiftBottleMutation(wineId: wineId, input: input)
        )
    }
}

private func rowIndexFromLabel(_ label: String) -> Int {
    // Server mirrors rowLabel = String.fromCharCode(65 + row), so "A" -> 0, "B" -> 1, ...
    guard let scalar = label.unicodeScalars.first else { return 0 }
    return Int(scalar.value) - 65
}

private func mapEventType(_ graphql: GraphQLEnum<VinariumGraphQL.JournalEventType>) -> HistoryEventType {
    switch graphql {
    case .case(.in): return .entry
    case .case(.out): return .exit
    case .unknown: return .entry
    }
}
