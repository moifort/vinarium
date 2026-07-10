import Foundation

struct UserWineDetail: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let beverageType: BeverageType
    let color: WineColor?
    let subtype: BeverageSubtype?
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
    let latitude: Double?
    let longitude: Double?
    let placeName: String?
    /// Whether this wine belongs to the viewer. False for a housemate's wine seen
    /// through the shared cellar — owner-only actions are hidden then.
    let isMine: Bool
    /// The owning household member's name, when the wine isn't the viewer's own.
    let ownerName: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        beverageType = try container.decodeIfPresent(BeverageType.self, forKey: .beverageType) ?? .wine
        color = try container.decodeIfPresent(WineColor.self, forKey: .color)
        subtype = try container.decodeIfPresent(BeverageSubtype.self, forKey: .subtype)
        domain = try container.decodeIfPresent(String.self, forKey: .domain)
        vintage = try container.decodeIfPresent(Int.self, forKey: .vintage)
        appellation = try container.decodeIfPresent(String.self, forKey: .appellation)
        region = try container.decodeIfPresent(String.self, forKey: .region)
        country = try container.decodeIfPresent(String.self, forKey: .country)
        grapeVarieties = try container.decode([String].self, forKey: .grapeVarieties)
        alcoholContent = try container.decodeIfPresent(Double.self, forKey: .alcoholContent)
        classification = try container.decodeIfPresent(String.self, forKey: .classification)
        purchasePrice = try container.decodeIfPresent(Double.self, forKey: .purchasePrice)
        purchaseDate = try container.decodeIfPresent(String.self, forKey: .purchaseDate)
        drinkFrom = try container.decodeIfPresent(Int.self, forKey: .drinkFrom)
        drinkUntil = try container.decodeIfPresent(Int.self, forKey: .drinkUntil)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        giftedBy = try container.decodeIfPresent(String.self, forKey: .giftedBy)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        cellar = try container.decodeIfPresent(CellarInfo.self, forKey: .cellar)
        consumption = try container.decodeIfPresent(ConsumptionInfo.self, forKey: .consumption)
        gift = try container.decodeIfPresent(GiftInfo.self, forKey: .gift)
        recommendation = try container.decodeIfPresent(RecommendationInfo.self, forKey: .recommendation)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        placeName = try container.decodeIfPresent(String.self, forKey: .placeName)
        isMine = try container.decodeIfPresent(Bool.self, forKey: .isMine) ?? true
        ownerName = try container.decodeIfPresent(String.self, forKey: .ownerName)
    }

    init(
        id: String, name: String, beverageType: BeverageType = .wine, color: WineColor?,
        subtype: BeverageSubtype? = nil, domain: String?, vintage: Int?,
        appellation: String?, region: String?, country: String?, grapeVarieties: [String],
        alcoholContent: Double?, classification: String?, purchasePrice: Double?,
        purchaseDate: String?, drinkFrom: Int?, drinkUntil: Int?, notes: String?,
        giftedBy: String?, createdAt: Date, updatedAt: Date,
        cellar: CellarInfo?, consumption: ConsumptionInfo?, gift: GiftInfo?,
        recommendation: RecommendationInfo?,
        latitude: Double? = nil, longitude: Double? = nil, placeName: String? = nil,
        isMine: Bool = true, ownerName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.beverageType = beverageType
        self.color = color
        self.subtype = subtype
        self.domain = domain
        self.vintage = vintage
        self.appellation = appellation
        self.region = region
        self.country = country
        self.grapeVarieties = grapeVarieties
        self.alcoholContent = alcoholContent
        self.classification = classification
        self.purchasePrice = purchasePrice
        self.purchaseDate = purchaseDate
        self.drinkFrom = drinkFrom
        self.drinkUntil = drinkUntil
        self.notes = notes
        self.giftedBy = giftedBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.cellar = cellar
        self.consumption = consumption
        self.gift = gift
        self.recommendation = recommendation
        self.latitude = latitude
        self.longitude = longitude
        self.placeName = placeName
        self.isMine = isMine
        self.ownerName = ownerName
    }
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
    let favorite: Bool?
}

struct RecommendationInfo: Codable, Sendable {
    let recommenderName: String?
    let comment: String?
}
