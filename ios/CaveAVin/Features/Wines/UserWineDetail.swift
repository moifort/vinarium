import Foundation

struct UserWineDetail: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let color: WineColor
    let domain: String?
    let vintage: Int?
    let appellation: String?
    let region: String?
    let country: String?
    let grapeVarieties: [String]
    let alcoholContent: Double?
    let classification: String?
    let purchasePrice: Double?
    let purchaseDate: String?
    let drinkFrom: Int?
    let drinkUntil: Int?
    let notes: String?
    let giftedBy: String?
    let createdAt: Date
    let updatedAt: Date
    let cellar: CellarInfo?
    let consumption: ConsumptionInfo?
    let gift: GiftInfo?
    let recommendation: RecommendationInfo?
}

struct CellarInfo: Codable, Sendable {
    let row: String
    let col: Int
    let dateIn: Date
    let dateOut: Date?

    enum CodingKeys: String, CodingKey {
        case row = "rowLabel"
        case col = "colLabel"
        case dateIn
        case dateOut
    }
}

struct GiftInfo: Codable, Sendable {
    let giftedDate: Date
    let recipientName: String?
}

struct ConsumptionInfo: Codable, Sendable {
    let consumedDate: Date?
    let rating: Int?
    let tastingNotes: String?
    let contacts: [String]?
}

struct RecommendationInfo: Codable, Sendable {
    let recommenderName: String?
    let comment: String?
}
