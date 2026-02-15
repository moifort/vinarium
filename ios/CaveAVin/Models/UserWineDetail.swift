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
    let createdAt: Date
    let updatedAt: Date
    let cellar: CellarInfo?
    let consumption: ConsumptionInfo?
}

struct CellarInfo: Codable, Sendable {
    let row: String
    let col: Int
    let dateIn: Date
}

struct ConsumptionInfo: Codable, Sendable {
    let dateOut: Date
    let consumedDate: Date?
    let rating: Int?
    let tastingNotes: String?
}
