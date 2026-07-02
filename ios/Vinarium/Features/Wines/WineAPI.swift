import Apollo
import Foundation

enum WineAPI {
    static func list() async throws -> [Wine] {
        let data = try await GraphQLHelpers.fetch(
            GraphQLClient.shared.apollo,
            query: VinariumGraphQL.WineListQuery()
        )
        return data.wines.map(mapWine)
    }

    static func getDetail(id: String) async throws -> UserWineDetail {
        let data = try await GraphQLHelpers.fetch(
            GraphQLClient.shared.apollo,
            query: VinariumGraphQL.WineDetailQuery(id: id)
        )
        guard let wine = data.wine else { throw APIError.invalidResponse }
        return mapDetail(wine)
    }

    static func create(_ request: CreateWineRequest) async throws -> Wine {
        let input = addWineInput(from: request)
        let data = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.AddWineMutation(input: input)
        )
        let created = data.addWine
        return Wine(
            id: created.id,
            name: created.name,
            color: WineColor(graphql: created.color),
            vintage: created.vintage,
            createdAt: GraphQLHelpers.parseISO8601(created.createdAt) ?? Date(),
            updatedAt: GraphQLHelpers.parseISO8601(created.updatedAt) ?? Date()
        )
    }

    static func update(id: String, _ request: UpdateWineRequest) async throws -> Wine {
        let input = updateWineInput(from: request)
        let data = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.UpdateWineMutation(id: id, input: input)
        )
        let updated = data.updateWine
        return Wine(
            id: updated.id,
            name: updated.name,
            color: WineColor(graphql: updated.color),
            vintage: updated.vintage,
            createdAt: Date(),
            updatedAt: GraphQLHelpers.parseISO8601(updated.updatedAt) ?? Date()
        )
    }

    static func delete(id: String) async throws {
        _ = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.DeleteWineMutation(id: id)
        )
    }

    static func scan(imageData: Data) async throws -> ScanResult {
        let base64 = imageData.base64EncodedString()
        let data = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.ScanWineMutation(imageBase64: base64)
        )
        let s = data.scanWine
        return ScanResult(
            name: s.name,
            domain: s.domain,
            vintage: s.vintage,
            appellation: s.appellation,
            region: s.region,
            country: s.country,
            color: WineColor(graphql: s.color),
            grapeVarieties: s.grapeVarieties ?? [],
            alcoholContent: nil,
            classification: s.classification,
            drinkFrom: s.drinkFrom,
            drinkUntil: s.drinkUntil,
            estimatedPrice: s.estimatedPrice
        )
    }

    static func addToFavorites(id: String) async throws {
        _ = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.MarkFavoriteMutation(wineId: id)
        )
    }

    static func addToShortlist(
        id: String,
        consumedDate: String? = nil,
        rating: Int? = nil,
        contacts: [String]? = nil,
        tastingNotes: String? = nil
    ) async throws {
        let input = VinariumGraphQL.ShortlistInput(
            consumedDate: GraphQLHelpers.graphQLNullable(consumedDate),
            contacts: GraphQLHelpers.graphQLNullable(contacts),
            rating: GraphQLHelpers.graphQLNullable(rating),
            tastingNotes: GraphQLHelpers.graphQLNullable(tastingNotes)
        )
        _ = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.AddToShortlistMutation(wineId: id, input: input)
        )
    }
}

// MARK: - Mapping helpers

private func graphQLColor(_ color: WineColor) -> GraphQLEnum<VinariumGraphQL.WineColor> {
    switch color {
    case .red: return .case(.red)
    case .white: return .case(.white)
    case .rosé: return .case(.rose)
    case .sparkling: return .case(.sparkling)
    case .sweet: return .case(.sweet)
    }
}

private func mapWine(_ w: VinariumGraphQL.WineListQuery.Data.Wine) -> Wine {
    Wine(
        id: w.id,
        name: w.name,
        color: WineColor(graphql: w.color),
        domain: w.domain,
        vintage: w.vintage,
        appellation: w.appellation,
        region: w.region,
        country: w.country,
        grapeVarieties: w.grapeVarieties,
        alcoholContent: nil,
        classification: w.classification,
        purchasePrice: w.purchasePrice,
        purchaseDate: w.purchaseDate,
        drinkFrom: w.drinkFrom,
        drinkUntil: w.drinkUntil,
        notes: w.notes,
        giftedBy: w.giftedBy,
        rating: w.consumption?.rating,
        shortlist: w.consumption?.shortlist,
        giftedTo: w.gift?.recipientName,
        recommendedBy: w.recommendation?.recommenderName,
        contacts: w.consumption?.contacts,
        latitude: w.latitude,
        longitude: w.longitude,
        placeName: w.placeName,
        isInCellar: w.cellar != nil,
        consumedDate: w.consumption?.consumedDate.flatMap { GraphQLHelpers.parseISO8601($0) },
        isGifted: w.gift != nil,
        isRecommended: w.recommendation != nil,
        createdAt: GraphQLHelpers.parseISO8601(w.createdAt) ?? Date(),
        updatedAt: GraphQLHelpers.parseISO8601(w.updatedAt) ?? Date()
    )
}

private func mapDetail(_ w: VinariumGraphQL.WineDetailQuery.Data.Wine) -> UserWineDetail {
    UserWineDetail(
        id: w.id,
        name: w.name,
        color: WineColor(graphql: w.color),
        domain: w.domain,
        vintage: w.vintage,
        appellation: w.appellation,
        region: w.region,
        country: w.country,
        grapeVarieties: w.grapeVarieties ?? [],
        alcoholContent: nil,
        classification: w.classification,
        purchasePrice: w.purchasePrice,
        purchaseDate: w.purchaseDate,
        drinkFrom: w.drinkFrom,
        drinkUntil: w.drinkUntil,
        notes: w.notes,
        giftedBy: w.giftedBy,
        createdAt: GraphQLHelpers.parseISO8601(w.createdAt) ?? Date(),
        updatedAt: GraphQLHelpers.parseISO8601(w.updatedAt) ?? Date(),
        cellar: w.cellar.map {
            CellarInfo(
                row: $0.rowLabel,
                col: $0.colLabel,
                dateIn: GraphQLHelpers.parseISO8601($0.createdAt) ?? Date(),
                dateOut: nil
            )
        },
        consumption: w.consumption.map {
            ConsumptionInfo(
                consumedDate: $0.consumedDate.flatMap { GraphQLHelpers.parseISO8601($0) },
                rating: $0.rating,
                tastingNotes: $0.tastingNotes,
                contacts: $0.contacts,
                shortlist: $0.shortlist
            )
        },
        gift: w.gift.map {
            GiftInfo(
                giftedDate: GraphQLHelpers.parseISO8601($0.giftedDate) ?? Date(),
                recipientName: $0.recipientName
            )
        },
        recommendation: w.recommendation.map {
            RecommendationInfo(
                recommenderName: $0.recommenderName,
                comment: $0.comment
            )
        },
        latitude: w.latitude,
        longitude: w.longitude,
        placeName: w.placeName
    )
}

private func addWineInput(from r: CreateWineRequest) -> VinariumGraphQL.AddWineInput {
    VinariumGraphQL.AddWineInput(
        appellation: GraphQLHelpers.graphQLNullable(r.appellation),
        classification: GraphQLHelpers.graphQLNullable(r.classification),
        color: graphQLColor(r.color),
        country: GraphQLHelpers.graphQLNullable(r.country),
        domain: GraphQLHelpers.graphQLNullable(r.domain),
        drinkFrom: GraphQLHelpers.graphQLNullable(r.drinkFrom),
        drinkUntil: GraphQLHelpers.graphQLNullable(r.drinkUntil),
        giftedBy: GraphQLHelpers.graphQLNullable(r.giftedBy),
        grapeVarieties: GraphQLHelpers.graphQLNullable(r.grapeVarieties),
        latitude: GraphQLHelpers.graphQLNullable(r.latitude),
        longitude: GraphQLHelpers.graphQLNullable(r.longitude),
        name: r.name,
        notes: GraphQLHelpers.graphQLNullable(r.notes),
        placeName: GraphQLHelpers.graphQLNullable(r.placeName),
        purchaseDate: GraphQLHelpers.graphQLNullable(r.purchaseDate),
        purchasePrice: GraphQLHelpers.graphQLNullable(r.purchasePrice),
        region: GraphQLHelpers.graphQLNullable(r.region),
        vintage: GraphQLHelpers.graphQLNullable(r.vintage)
    )
}

private func updateWineInput(from r: UpdateWineRequest) -> VinariumGraphQL.UpdateWineInput {
    VinariumGraphQL.UpdateWineInput(
        appellation: GraphQLHelpers.graphQLNullable(r.appellation),
        classification: GraphQLHelpers.graphQLNullable(r.classification),
        color: r.color.map { .some(graphQLColor($0)) } ?? .none,
        country: GraphQLHelpers.graphQLNullable(r.country),
        domain: GraphQLHelpers.graphQLNullable(r.domain),
        drinkFrom: GraphQLHelpers.graphQLNullable(r.drinkFrom),
        drinkUntil: GraphQLHelpers.graphQLNullable(r.drinkUntil),
        giftedBy: GraphQLHelpers.graphQLNullable(r.giftedBy),
        grapeVarieties: GraphQLHelpers.graphQLNullable(r.grapeVarieties),
        latitude: GraphQLHelpers.graphQLNullable(r.latitude),
        longitude: GraphQLHelpers.graphQLNullable(r.longitude),
        name: GraphQLHelpers.graphQLNullable(r.name),
        notes: GraphQLHelpers.graphQLNullable(r.notes),
        placeName: GraphQLHelpers.graphQLNullable(r.placeName),
        purchaseDate: GraphQLHelpers.graphQLNullable(r.purchaseDate),
        purchasePrice: GraphQLHelpers.graphQLNullable(r.purchasePrice),
        region: GraphQLHelpers.graphQLNullable(r.region),
        vintage: GraphQLHelpers.graphQLNullable(r.vintage)
    )
}
