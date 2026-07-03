import Foundation

struct ScanResult: Decodable, Sendable {
    let name: String
    let beverageType: BeverageType
    let domain: String?
    let vintage: Int?
    let appellation: String?
    let region: String?
    let country: String?
    let color: WineColor?
    let style: String?
    let grapeVarieties: [String]
    let alcoholContent: Double?
    let classification: String?
    let drinkFrom: Int?
    let drinkUntil: Int?
    let estimatedPrice: Double?
}
