import Apollo
import Foundation

/// One page of the wine list, mirroring the server's `Wines` payload.
struct WinePage {
    let items: [Wine]
    let hasMore: Bool
    let totalCount: Int
}

enum WineAPI {
    static func list(
        mode: WineListMode,
        sort: WineSort,
        sortDescending: Bool,
        statusFilter: WineStatusFilter,
        color: WineColor?,
        beverageType: BeverageType?,
        limit: Int,
        after: String?
    ) async throws -> WinePage {
        let query = VinariumGraphQL.WineListQuery(
            mode: .some(.case(gqlMode(mode))),
            status: .some(.case(gqlStatus(statusFilter))),
            color: color.map { .some(graphQLColor($0)) } ?? .none,
            beverageType: beverageType.map { .some($0.graphQLValue) } ?? .none,
            sort: .some(.case(gqlSort(sort))),
            order: .some(.case(sortDescending ? .desc : .asc)),
            limit: .some(Int32(limit)),
            after: GraphQLHelpers.graphQLNullable(after)
        )
        let data = try await GraphQLHelpers.fetch(GraphQLClient.shared.apollo, query: query)
        return WinePage(
            items: data.beverages.items.map { Wine(listFields: $0.fragments.wineListFields) },
            hasMore: data.beverages.hasMore,
            totalCount: data.beverages.totalCount
        )
    }

    static func getDetail(id: String) async throws -> UserWineDetail {
        let data = try await GraphQLHelpers.fetch(
            GraphQLClient.shared.apollo,
            query: VinariumGraphQL.WineDetailQuery(id: id)
        )
        guard let wine = data.beverage else { throw APIError.invalidResponse }
        return mapDetail(wine.fragments.wineDetailFields)
    }

    /// Add a bottle together with what the form already says about it: the
    /// viewer's tasting note and the recommendation behind it land with the bottle,
    /// in one mutation, or none of them does.
    static func create(
        _ request: CreateWineRequest,
        tasting: TastingEntry? = nil,
        recommendation: RecommendationEntry? = nil
    ) async throws -> Wine {
        var input = addWineInput(from: request)
        input.tasting = tasting.map { .some($0.graphQLInput) } ?? .none
        input.recommendation = recommendation.map { .some($0.graphQLInput) } ?? .none
        let data = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.AddWineMutation(input: input)
        )
        let created = data.addBeverage
        let createdDetails = created.details?.asWineDetails
        return Wine(
            id: created.id,
            name: created.name,
            beverageType: BeverageType(graphql: created.beverageType),
            color: createdDetails?.color.map { WineColor(graphql: $0) },
            subtype: created.subtype.flatMap { BeverageSubtype(graphql: $0) },
            vintage: createdDetails?.vintage,
            createdAt: GraphQLHelpers.parseISO8601(created.createdAt) ?? Date(),
            updatedAt: GraphQLHelpers.parseISO8601(created.updatedAt) ?? Date()
        )
    }

    static func delete(id: String) async throws {
        _ = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.DeleteWineMutation(id: id)
        )
    }

    /// Reads a label photo. A description typed alongside is read with it and
    /// settles what the label does not show.
    static func scan(imageData: Data, description: String? = nil) async throws -> ScanResult {
        let base64 = imageData.base64EncodedString()
        let data = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.ScanWineMutation(
                imageBase64: base64,
                description: description.map { .some($0) } ?? .none
            )
        )
        return ScanResult(data.scanBeverage.fragments.scanResultFields)
    }

    /// Names a beverage from what is typed about it, without a photo. Same
    /// answer, same allowance as a scan.
    static func identify(description: String) async throws -> ScanResult {
        let data = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.IdentifyWineMutation(description: description)
        )
        return ScanResult(data.identifyBeverage.fragments.scanResultFields)
    }

    /// Toggle the favorite (heart) flag without clobbering an existing tasting note.
    static func setFavorite(id: String, favorite: Bool) async throws {
        _ = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.MarkFavoriteMutation(beverageId: id, favorite: favorite)
        )
    }

    /// Save the whole wine sheet in one call. The bottle, its tasting note, its
    /// gift and its recommendation are four records: sending them one mutation at a
    /// time meant four round trips and a half-saved sheet as soon as one failed.
    /// Only the parts the user touched are sent — an absent part is left alone.
    /// Returns the sheet as saved, so the screen needs no second read.
    static func saveSheet(
        id: String,
        wine: UpdateWineRequest,
        tasting: TastingDraft? = nil,
        gift: GiftDraft? = nil,
        recommendation: RecommendationDraft? = nil
    ) async throws -> UserWineDetail {
        let formatter = ISO8601DateFormatter()
        return try await save(
            id: id,
            VinariumGraphQL.BeverageSheetInput(
                beverage: .some(updateWineInput(from: wine)),
                gift: gift.map { draft in
                    .some(
                        VinariumGraphQL.GivenGiftInput(
                            giftedDate: .some(formatter.string(from: draft.date)),
                            recipientName: GraphQLHelpers.graphQLNullable(draft.recipientName)
                        )
                    )
                } ?? .none,
                recommendation: recommendation.map { draft in
                    .some(
                        RecommendationEntry(
                            recommenderName: draft.recommenderName,
                            comment: draft.comment
                        ).graphQLInput
                    )
                } ?? .none,
                tasting: tasting.map { draft in
                    .some(
                        TastingEntry(
                            consumedDate: draft.consumedDate.map { formatter.string(from: $0) },
                            rating: draft.rating == 0 ? nil : draft.rating,
                            contacts: draft.contacts,
                            // An emptied comment travels as such: that is how it is erased.
                            tastingNotes: draft.tastingNotes
                        ).graphQLInput
                    )
                } ?? .none
            )
        )
    }

    /// Save the viewer's own notes on a wine — a heart, a tasting, a
    /// recommendation — leaving the bottle itself alone. Works on a housemate's
    /// shared-cellar bottle too. Returns the sheet as saved.
    static func saveNotes(
        id: String,
        tasting: TastingEntry? = nil,
        recommendation: RecommendationEntry? = nil
    ) async throws -> UserWineDetail {
        try await save(
            id: id,
            VinariumGraphQL.BeverageSheetInput(
                recommendation: recommendation.map { .some($0.graphQLInput) } ?? .none,
                tasting: tasting.map { .some($0.graphQLInput) } ?? .none
            )
        )
    }

    private static func save(
        id: String,
        _ input: VinariumGraphQL.BeverageSheetInput
    ) async throws -> UserWineDetail {
        let data = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.SaveWineSheetMutation(id: id, input: input)
        )
        return mapDetail(data.saveBeverageSheet.fragments.wineDetailFields)
    }
}

/// A tasting note as sent to the server. The server overlays the fields it
/// receives onto the existing note, so an absent field leaves the previous value in
/// place. An empty comment is sent verbatim rather than dropped: that is how the
/// user erases what they wrote.
struct TastingEntry {
    var consumedDate: String?
    var rating: Int?
    var contacts: [String]?
    var tastingNotes: String?
    var favorite: Bool?

    var graphQLInput: VinariumGraphQL.TastingInput {
        VinariumGraphQL.TastingInput(
            consumedDate: GraphQLHelpers.graphQLNullable(consumedDate),
            contacts: GraphQLHelpers.graphQLNullable(contacts),
            favorite: GraphQLHelpers.graphQLNullable(favorite),
            rating: GraphQLHelpers.graphQLNullable(rating),
            tastingNotes: tastingNotes.map { .some($0) } ?? .none
        )
    }
}

/// Who recommended a wine, and what they said.
struct RecommendationEntry {
    var recommenderName: String?
    var comment: String?

    var graphQLInput: VinariumGraphQL.RecommendationInput {
        VinariumGraphQL.RecommendationInput(
            comment: GraphQLHelpers.graphQLNullable(comment),
            recommenderName: GraphQLHelpers.graphQLNullable(recommenderName)
        )
    }
}

// MARK: - Mapping helpers

private func graphQLColor(_ color: WineColor) -> GraphQLEnum<VinariumGraphQL.WineColor> {
    color.graphQLValue
}

private func gqlMode(_ mode: WineListMode) -> VinariumGraphQL.BeverageListMode {
    switch mode {
    case .all: .all
    case .favorites: .favorites
    case .gifted: .gifted
    case .recommended: .recommended
    }
}

private func gqlStatus(_ status: WineStatusFilter) -> VinariumGraphQL.BeverageStatusFilter {
    switch status {
    case .all: .all
    case .inCellar: .inCellar
    case .consumed: .consumed
    }
}

private func gqlSort(_ sort: WineSort) -> VinariumGraphQL.BeverageSort {
    switch sort {
    case .updatedAt: .updatedAt
    case .vintage: .vintage
    case .region: .region
    case .color: .color
    case .price: .price
    // Sorting by person is a purely client-side grouping, reserved for the
    // gifted/recommended views where the server returns the complete subset: the sort
    // asked of the server then has no effect on the sections.
    case .person: .updatedAt
    }
}

private func mapDetail(_ w: VinariumGraphQL.WineDetailFields) -> UserWineDetail {
    let details = w.details?.asWineDetails
    return UserWineDetail(
        id: w.id,
        name: w.name,
        beverageType: BeverageType(graphql: w.beverageType),
        color: details?.color.map { WineColor(graphql: $0) },
        subtype: w.subtype.flatMap { BeverageSubtype(graphql: $0) },
        domain: w.producer,
        vintage: details?.vintage,
        appellation: details?.appellation,
        cuvee: details?.cuvee,
        region: w.region,
        country: w.country,
        grapeVarieties: details?.grapeVarieties ?? [],
        alcoholContent: w.alcoholContent,
        classification: details?.classification,
        purchasePrice: w.purchase?.price,
        purchaseDate: w.purchase?.date,
        drinkFrom: details?.drinkWindow?.from,
        drinkUntil: details?.drinkWindow?.until,
        notes: w.notes,
        giftedBy: w.gift?.received?.from,
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
                favorite: $0.favorite
            )
        },
        // GiftInfo carries the "given" facet; the "received from" provenance lives in
        // giftedBy above.
        gift: w.gift?.given.map {
            GiftInfo(
                giftedDate: GraphQLHelpers.parseISO8601($0.date) ?? Date(),
                recipientName: $0.recipientName
            )
        },
        recommendation: w.recommendation.map {
            RecommendationInfo(
                recommenderName: $0.recommenderName,
                comment: $0.comment
            )
        },
        latitude: w.place?.latitude,
        longitude: w.place?.longitude,
        placeName: w.place?.name,
        isMine: w.isMine,
        ownerName: w.ownerName,
        attachments: w.attachments.compactMap {
            BeverageAttachment(fields: $0.fragments.beverageAttachmentFields)
        }
    )
}

private func addWineInput(from r: CreateWineRequest) -> VinariumGraphQL.AddBeverageInput {
    VinariumGraphQL.AddBeverageInput(
        alcoholContent: GraphQLHelpers.graphQLNullable(r.alcoholContent),
        appellation: GraphQLHelpers.graphQLNullable(r.appellation),
        beverageType: .some(r.beverageType.graphQLValue),
        classification: GraphQLHelpers.graphQLNullable(r.classification),
        color: r.color.map { .some(graphQLColor($0)) } ?? .none,
        country: GraphQLHelpers.graphQLNullable(r.country),
        cuvee: GraphQLHelpers.graphQLNullable(r.cuvee),
        drinkFrom: GraphQLHelpers.graphQLNullable(r.drinkFrom),
        drinkUntil: GraphQLHelpers.graphQLNullable(r.drinkUntil),
        giftedBy: GraphQLHelpers.graphQLNullable(r.giftedBy),
        grapeVarieties: GraphQLHelpers.graphQLNullable(r.grapeVarieties),
        latitude: GraphQLHelpers.graphQLNullable(r.latitude),
        longitude: GraphQLHelpers.graphQLNullable(r.longitude),
        name: r.name,
        notes: GraphQLHelpers.graphQLNullable(r.notes),
        placeName: GraphQLHelpers.graphQLNullable(r.placeName),
        producer: GraphQLHelpers.graphQLNullable(r.domain),
        purchaseDate: GraphQLHelpers.graphQLNullable(r.purchaseDate),
        purchasePrice: GraphQLHelpers.graphQLNullable(r.purchasePrice),
        region: GraphQLHelpers.graphQLNullable(r.region),
        subtype: r.subtype.map { .some($0.graphql) } ?? .none,
        vintage: GraphQLHelpers.graphQLNullable(r.vintage)
    )
}

private func updateWineInput(from r: UpdateWineRequest) -> VinariumGraphQL.UpdateBeverageInput {
    // `.null` erases server-side, `.none` leaves the stored value alone. Every
    // field the user emptied is listed in `cleared`, which is the whole difference
    // between "I did not touch this" and "take this away".
    func field<T>(_ name: ClearedWineField, _ value: GraphQLNullable<T>) -> GraphQLNullable<T> {
        r.cleared.contains(name) ? .null : value
    }

    return VinariumGraphQL.UpdateBeverageInput(
        alcoholContent: field(.alcoholContent, GraphQLHelpers.graphQLNullable(r.alcoholContent)),
        appellation: field(.appellation, GraphQLHelpers.graphQLNullable(r.appellation)),
        beverageType: r.beverageType.map { .some($0.graphQLValue) } ?? .none,
        classification: field(.classification, GraphQLHelpers.graphQLNullable(r.classification)),
        color: r.color.map { .some(graphQLColor($0)) } ?? .none,
        country: field(.country, GraphQLHelpers.graphQLNullable(r.country)),
        cuvee: field(.cuvee, GraphQLHelpers.graphQLNullable(r.cuvee)),
        drinkFrom: field(.drinkFrom, GraphQLHelpers.graphQLNullable(r.drinkFrom)),
        drinkUntil: field(.drinkUntil, GraphQLHelpers.graphQLNullable(r.drinkUntil)),
        giftedBy: GraphQLHelpers.graphQLNullable(r.giftedBy),
        grapeVarieties: field(.grapeVarieties, GraphQLHelpers.graphQLNullable(r.grapeVarieties)),
        latitude: field(.latitude, GraphQLHelpers.graphQLNullable(r.latitude)),
        longitude: field(.longitude, GraphQLHelpers.graphQLNullable(r.longitude)),
        name: GraphQLHelpers.graphQLNullable(r.name),
        notes: field(.notes, GraphQLHelpers.graphQLNullable(r.notes)),
        placeName: field(.placeName, GraphQLHelpers.graphQLNullable(r.placeName)),
        producer: field(.producer, GraphQLHelpers.graphQLNullable(r.domain)),
        purchaseDate: field(.purchaseDate, GraphQLHelpers.graphQLNullable(r.purchaseDate)),
        purchasePrice: field(.purchasePrice, GraphQLHelpers.graphQLNullable(r.purchasePrice)),
        region: field(.region, GraphQLHelpers.graphQLNullable(r.region)),
        subtype: r.subtype.map { .some($0.graphql) } ?? (r.cleared.contains(.subtype) ? .null : .none),
        vintage: field(.vintage, GraphQLHelpers.graphQLNullable(r.vintage))
    )
}
