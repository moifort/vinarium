import Apollo
import Foundation

/// One page of cellar journal events. `endCursor` resumes the journal right
/// after the last event read, so a deeper page costs no more than the first.
struct HistoryPage {
    let events: [HistoryEvent]
    let hasMore: Bool
    let endCursor: String?
}

/// One page of cellar bottles.
struct BottlesPage {
    let bottles: [CellarBottle]
    let hasMore: Bool
}

/// What the cellar screen shows as it opens: the household's cellars and the first
/// page of each list.
struct CellarOverview {
    let cellars: [CellarSummary]
    let bottles: BottlesPage
    let history: HistoryPage
}

/// The whole grid of one cellar, as the placement and move screens draw it.
struct CellarGrid {
    /// Every cellar of the household, to switch the grid to another one.
    let cellars: [CellarSummary]
    let bottles: [CellarBottle]
    let rows: Int
    let cols: Int
    /// The suggested free slot, when it was asked for and the cellar is not full.
    let suggestion: CellarSuggestion?
}

/// The cellar refusals the user can meet, in their words rather than the server's.
enum CellarError: LocalizedError {
    case premiumRequired
    case tooManyCellars
    case notEmpty

    var errorDescription: String? {
        switch self {
        case .premiumRequired:
            String(localized: "Plusieurs caves sont réservées à Vinarium Premium.")
        case .tooManyCellars:
            String(localized: "Un foyer compte au plus dix caves.")
        case .notEmpty:
            String(localized: "Sortez d'abord les bouteilles de cette cave.")
        }
    }
}

enum CellarAPI {
    /// The household's cellars, the primary first.
    static func cellars() async throws -> [CellarSummary] {
        let data = try await GraphQLHelpers.fetch(
            GraphQLClient.shared.apollo,
            query: VinariumGraphQL.CellarsQuery()
        )
        return data.cellars.map { CellarSummary(fields: $0.fragments.cellarFields) }
    }

    static func create(name: String, rows: Int, cols: Int, zones: Int) async throws -> CellarSummary {
        let data = try await translatingErrors {
            try await GraphQLHelpers.perform(
                GraphQLClient.shared.apollo,
                mutation: VinariumGraphQL.CreateCellarMutation(
                    name: name,
                    rows: Int32(rows),
                    cols: Int32(cols),
                    zones: .some(Int32(zones))
                )
            )
        }
        return CellarSummary(fields: data.createCellar.fragments.cellarFields)
    }

    static func rename(id: String, name: String) async throws -> CellarSummary {
        let data = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.RenameCellarMutation(id: id, name: name)
        )
        return CellarSummary(fields: data.renameCellar.fragments.cellarFields)
    }

    /// Deletes an empty cellar; refused while a bottle stands in it.
    static func delete(id: String) async throws {
        _ = try await translatingErrors {
            try await GraphQLHelpers.perform(
                GraphQLClient.shared.apollo,
                mutation: VinariumGraphQL.DeleteCellarMutation(id: id)
            )
        }
    }

    /// `cellarId` nil reads the primary cellar.
    static func overview(limit: Int, cellarId: String? = nil) async throws -> CellarOverview {
        let data = try await GraphQLHelpers.fetch(
            GraphQLClient.shared.apollo,
            query: VinariumGraphQL.CellarOverviewQuery(
                limit: .some(Int32(limit)),
                cellarId: GraphQLHelpers.graphQLNullable(cellarId)
            )
        )
        return CellarOverview(
            cellars: data.cellars.map { CellarSummary(fields: $0.fragments.cellarFields) },
            bottles: BottlesPage(
                bottles: data.cellarBottles.items.map { bottle($0.fragments.cellarBottleFields) },
                hasMore: data.cellarBottles.hasMore
            ),
            history: HistoryPage(
                events: data.journalEvents.items.map { event($0.fragments.journalEventFields) },
                hasMore: data.journalEvents.hasMore,
                endCursor: data.journalEvents.endCursor
            )
        )
    }

    static func getBottles(limit: Int, after: String?, cellarId: String? = nil) async throws -> BottlesPage {
        let data = try await GraphQLHelpers.fetch(
            GraphQLClient.shared.apollo,
            query: VinariumGraphQL.CellarBottlesQuery(
                limit: .some(Int32(limit)),
                after: GraphQLHelpers.graphQLNullable(after),
                cellarId: GraphQLHelpers.graphQLNullable(cellarId)
            )
        )
        return BottlesPage(
            bottles: data.cellarBottles.items.map { bottle($0.fragments.cellarBottleFields) },
            hasMore: data.cellarBottles.hasMore
        )
    }

    static func getHistory(limit: Int, after: String?) async throws -> HistoryPage {
        let data = try await GraphQLHelpers.fetch(
            GraphQLClient.shared.apollo,
            query: VinariumGraphQL.CellarHistoryQuery(
                limit: .some(Int32(limit)),
                after: GraphQLHelpers.graphQLNullable(after)
            )
        )
        return HistoryPage(
            events: data.journalEvents.items.map { event($0.fragments.journalEventFields) },
            hasMore: data.journalEvents.hasMore,
            endCursor: data.journalEvents.endCursor
        )
    }

    /// Every bottle of a cellar (the primary one when `cellarId` is nil) with the
    /// grid size, and the suggested free slot when placing a bottle — one round trip.
    static func grid(withSuggestion: Bool, cellarId: String? = nil) async throws -> CellarGrid {
        let data = try await GraphQLHelpers.fetch(
            GraphQLClient.shared.apollo,
            query: VinariumGraphQL.CellarGridQuery(
                withSuggestion: withSuggestion,
                cellarId: GraphQLHelpers.graphQLNullable(cellarId)
            )
        )
        return CellarGrid(
            cellars: data.cellars.map { CellarSummary(fields: $0.fragments.cellarFields) },
            bottles: data.cellarBottles.items.map { bottle($0.fragments.cellarBottleFields) },
            rows: Int(data.cellarInfo.rows),
            cols: Int(data.cellarInfo.cols),
            suggestion: data.suggestCellarPosition.map {
                CellarSuggestion(row: $0.rowLabel, col: $0.colLabel)
            }
        )
    }

    /// Place a bottle at a grid slot named the way the UI shows it: row "A", column 1,
    /// in the given cellar or the primary one.
    static func place(
        wineId: String,
        rowLabel: String,
        colLabel: Int,
        cellarId: String? = nil
    ) async throws {
        let (row, col) = gridIndices(rowLabel: rowLabel, colLabel: colLabel)
        _ = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.PlaceBottleMutation(
                beverageId: wineId,
                row: row,
                col: col,
                cellarId: GraphQLHelpers.graphQLNullable(cellarId)
            )
        )
    }

    /// Move a bottle to a grid slot named the way the UI shows it: row "A", column 1,
    /// in the given cellar or its own.
    static func move(
        wineId: String,
        rowLabel: String,
        colLabel: Int,
        cellarId: String? = nil
    ) async throws {
        let (row, col) = gridIndices(rowLabel: rowLabel, colLabel: colLabel)
        _ = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.MoveBottleMutation(
                beverageId: wineId,
                row: row,
                col: col,
                cellarId: GraphQLHelpers.graphQLNullable(cellarId)
            )
        )
    }

    private static func translatingErrors<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch let error as APIError {
            switch error.domainCode {
            case "PREMIUM_REQUIRED": throw CellarError.premiumRequired
            case "TOO_MANY_CELLARS": throw CellarError.tooManyCellars
            case "CELLAR_NOT_EMPTY": throw CellarError.notEmpty
            default: throw error
            }
        }
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
            mutation: VinariumGraphQL.ConsumeBottleMutation(beverageId: wineId, input: input)
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
            mutation: VinariumGraphQL.GiftBottleMutation(beverageId: wineId, input: input)
        )
    }
}

/// The grid indices behind a slot's labels. Both axes are labelled for reading and
/// stored 0-based: the server mirrors rowLabel = String.fromCharCode(65 + row) and
/// colLabel = col + 1, so "A" -> 0 and column 1 -> 0. Converting the row alone would
/// shift every bottle one column to the right of the slot that was picked.
private func gridIndices(rowLabel: String, colLabel: Int) -> (row: Int32, col: Int32) {
    let rowScalar = rowLabel.unicodeScalars.first.map { Int($0.value) - 65 } ?? 0
    return (Int32(max(0, rowScalar)), Int32(max(0, colLabel - 1)))
}

private func bottle(_ b: VinariumGraphQL.CellarBottleFields) -> CellarBottle {
    let details = b.wine.details?.asWineDetails
    return CellarBottle(
        wineId: b.beverageId,
        cellarId: b.cellarId,
        wine: Wine(
            id: b.wine.id,
            name: b.wine.name,
            beverageType: BeverageType(graphql: b.wine.beverageType),
            color: details?.color.map { WineColor(graphql: $0) },
            subtype: b.wine.subtype.flatMap { BeverageSubtype(graphql: $0) },
            domain: b.wine.producer,
            vintage: details?.vintage,
            appellation: details?.appellation,
            region: b.wine.region,
            country: b.wine.country,
            classification: details?.classification,
            purchasePrice: b.wine.purchase?.price,
            drinkFrom: details?.drinkWindow?.from,
            drinkUntil: details?.drinkWindow?.until,
            createdAt: Date(),
            updatedAt: Date()
        ),
        rowLabel: b.rowLabel,
        colLabel: b.colLabel,
        createdAt: GraphQLHelpers.parseISO8601(b.createdAt) ?? Date(),
        ownerName: b.owner.isMine ? nil : b.owner.displayName
    )
}

private func event(_ e: VinariumGraphQL.JournalEventFields) -> HistoryEvent {
    HistoryEvent(
        type: mapEventType(e.type),
        date: GraphQLHelpers.parseISO8601(e.date) ?? Date(),
        wineId: e.beverageId,
        wineName: e.beverageName,
        wineBeverageType: BeverageType(graphql: e.wineBeverageType),
        wineColor: e.wineColor.map { WineColor(graphql: $0) },
        position: e.position,
        memberName: e.actor.isMine ? nil : e.actor.displayName
    )
}

private func mapEventType(_ graphql: GraphQLEnum<VinariumGraphQL.JournalEventType>) -> HistoryEventType {
    switch graphql {
    case .case(.in): return .entry
    case .case(.out): return .exit
    case .unknown: return .entry
    }
}
