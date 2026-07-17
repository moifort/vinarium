import Foundation

struct ScanResult: Decodable, Sendable {
    /// Faux quand l'image n'était pas une étiquette identifiable : déclenche
    /// l'écran « aucun résultat » plutôt qu'une fiche vide à remplir.
    let recognized: Bool
    let name: String
    let beverageType: BeverageType
    let domain: String?
    let vintage: Int?
    let appellation: String?
    let region: String?
    let country: String?
    let color: WineColor?
    let subtype: BeverageSubtype?
    let grapeVarieties: [String]
    let alcoholContent: Double?
    let classification: String?
    let drinkFrom: Int?
    let drinkUntil: Int?
    let estimatedPrice: Double?
}
