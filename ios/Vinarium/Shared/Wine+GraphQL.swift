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
            purchasePrice: w.purchasePrice,
            purchaseDate: w.purchaseDate,
            drinkFrom: w.drinkFrom,
            drinkUntil: w.drinkUntil,
            notes: w.notes,
            giftedBy: w.giftedBy,
            rating: w.consumption?.rating,
            isFavorite: w.consumption?.favorite ?? false,
            giftedTo: w.gift?.recipientName,
            recommendedBy: w.recommendation?.recommenderName,
            contacts: w.consumption?.contacts,
            latitude: w.latitude,
            longitude: w.longitude,
            placeName: w.placeName,
            isInCellar: w.cellar != nil,
            consumedDate: w.consumption?.consumedDate.flatMap { GraphQLHelpers.parseISO8601($0) },
            // « Offerts » = cadeaux reçus, portés par le scalaire giftedBy sur le vin
            // (le satellite gift, lui, représente un vin donné à quelqu'un).
            isGifted: w.giftedBy != nil,
            isRecommended: w.recommendation != nil,
            createdAt: GraphQLHelpers.parseISO8601(w.createdAt) ?? Date(),
            updatedAt: GraphQLHelpers.parseISO8601(w.updatedAt) ?? Date()
        )
    }
}
