import Foundation

struct DashboardData: Codable, Sendable {
    let bottleCount: Int
    let capacity: Int
    let totalValue: Double
    /// Every ready bottle and every favorite, the two lists below being capped.
    let readyToDrinkCount: Int
    let favoriteCount: Int
    let readyToDrink: [DashboardWine]
    let favorites: [DashboardFavorite]
    let lastBottle: DashboardEntry?
    let lastExit: DashboardHistoryEvent?
    let history: [DashboardHistoryEvent]
}

struct DashboardFavorite: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let beverageType: BeverageType
    let subtype: BeverageSubtype?
    let producer: String?
    let color: WineColor?
    let vintage: Int?
    let estimatedPrice: Double?
    let tastingDate: Date?
    let rating: Int?
    // Optional so a dashboard cached before the drawn labels still decodes.
    var labelFamily: BottleArtwork.LabelFamily? = nil
    var appellation: String? = nil
    var classification: String? = nil
    // Optional so a dashboard cached before the vignettes' column still decodes.
    /// The slot of this wine, or of an identical bottle; nil when none is stored.
    var position: String? = nil
    var drinkUntil: Int? = nil
    /// How many identical bottles the cellars hold.
    var stock: Int? = nil
}

struct DashboardWine: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let beverageType: BeverageType
    let subtype: BeverageSubtype?
    let producer: String?
    let color: WineColor?
    let vintage: Int?
    let notes: String?
    let isFavorite: Bool
    let position: String
    /// The cellar the bottle stands in, once the household has several.
    var cellarName: String? = nil
    let urgent: Bool
    let drinkUntil: Int?
    // Optional so a dashboard cached before the drawn labels still decodes.
    var labelFamily: BottleArtwork.LabelFamily? = nil
    var appellation: String? = nil
    var classification: String? = nil
    // Optional so a dashboard cached before the vignettes' column still decodes.
    var estimatedPrice: Double? = nil
    /// How many identical bottles the cellars hold.
    var stock: Int? = nil
}

struct DashboardEntry: Codable, Sendable {
    let wine: DashboardEntryWine
    let position: String
    let date: Date
    let rating: Int?
}

struct DashboardEntryWine: Codable, Sendable {
    let id: String
    let name: String
    let beverageType: BeverageType
    let color: WineColor?
    let vintage: Int?
}

struct DashboardHistoryEvent: Codable, Identifiable, Sendable {
    let type: String
    let date: Date
    let wineId: String
    let wineName: String
    let wineBeverageType: BeverageType
    let wineSubtype: BeverageSubtype?
    let wineColor: WineColor?
    let wineVintage: Int?
    let position: String
    let rating: Int?
    /// The household member behind the move, nil when it was you.
    let memberName: String?
    /// The wine's producer; optional so a dashboard cached before it existed still decodes.
    var producer: String? = nil
    var labelFamily: BottleArtwork.LabelFamily? = nil

    var id: String { "\(type)-\(wineName)-\(date.timeIntervalSince1970)" }

    var isEntry: Bool { type == "in" }
}
