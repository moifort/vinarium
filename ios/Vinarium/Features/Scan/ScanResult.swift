import Foundation

struct ScanResult: Decodable, Sendable {
    /// False when the image was not an identifiable label: it opens the "no result"
    /// screen rather than an empty form to fill in.
    let recognized: Bool
    let name: String
    let beverageType: BeverageType
    let domain: String?
    let vintage: Int?
    let appellation: String?
    let cuvee: String?
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

extension ScanResult {
    /// The server's answer, the same shape for a photo and a description.
    init(_ s: VinariumGraphQL.ScanResultFields) {
        self.init(
            recognized: s.recognized,
            name: s.name,
            beverageType: BeverageType(graphql: s.beverageType),
            domain: s.domain,
            vintage: s.vintage,
            appellation: s.appellation,
            cuvee: s.cuvee,
            region: s.region,
            country: s.country,
            color: s.color.map { WineColor(graphql: $0) },
            subtype: s.subtype.flatMap { BeverageSubtype(graphql: $0) },
            grapeVarieties: s.grapeVarieties ?? [],
            alcoholContent: s.alcoholContent,
            classification: s.classification,
            drinkFrom: s.drinkFrom,
            drinkUntil: s.drinkUntil,
            estimatedPrice: s.estimatedPrice
        )
    }
}
