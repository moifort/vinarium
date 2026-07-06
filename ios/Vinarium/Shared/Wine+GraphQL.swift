import Foundation

extension Wine {
    /// Maps the shared `WineListFields` fragment (used by the wine list and the
    /// global search) into the domain model. Single source of truth so both
    /// query paths stay in sync.
    init(listFields w: VinariumGraphQL.WineListFields) {
        self.init(
            id: w.id,
            name: w.name,
            beverageType: BeverageType(graphql: w.beverageType),
            color: w.color.map { WineColor(graphql: $0) },
            subtype: w.subtype.flatMap { BeverageSubtype(graphql: $0) },
            domain: w.domain,
            vintage: w.vintage,
            appellation: w.appellation,
            region: w.region,
            country: w.country,
            grapeVarieties: w.grapeVarieties,
            alcoholContent: w.alcoholContent,
            classification: w.classification,
            purchasePrice: w.purchase?.price,
            purchaseDate: w.purchase?.date,
            drinkFrom: w.drinkWindow?.from,
            drinkUntil: w.drinkWindow?.until,
            notes: w.notes,
            giftedBy: w.gift?.received?.from,
            rating: w.consumption?.rating,
            isFavorite: w.consumption?.favorite ?? false,
            giftedTo: w.gift?.given?.recipientName,
            recommendedBy: w.recommendation?.recommenderName,
            contacts: w.consumption?.contacts,
            latitude: w.place?.latitude,
            longitude: w.place?.longitude,
            placeName: w.place?.name,
            isInCellar: w.cellar != nil,
            consumedDate: w.consumption?.consumedDate.flatMap { GraphQLHelpers.parseISO8601($0) },
            // « Offerts » = cadeaux reçus, portés par la facette received du gift
            // (la facette given, elle, représente un vin donné à quelqu'un).
            isGifted: w.gift?.received != nil,
            isRecommended: w.recommendation != nil,
            createdAt: GraphQLHelpers.parseISO8601(w.createdAt) ?? Date(),
            updatedAt: GraphQLHelpers.parseISO8601(w.updatedAt) ?? Date()
        )
    }
}
