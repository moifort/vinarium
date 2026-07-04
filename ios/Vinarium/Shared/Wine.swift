import Foundation

enum WineColor: String, Codable, CaseIterable, Identifiable {
    case red
    case white
    case rosé
    case sparkling
    case sweet

    var id: String { rawValue }

    var label: String {
        switch self {
        case .red: "Rouge"
        case .white: "Blanc"
        case .rosé: "Rosé"
        case .sparkling: "Pétillant"
        case .sweet: "Moelleux"
        }
    }

    var displayColor: WineDisplayColor {
        switch self {
        case .red: .red
        case .white: .yellow
        case .rosé: .pink
        case .sparkling: .mint
        case .sweet: .orange
        }
    }
}

import SwiftUI

enum WineDisplayColor {
    case red, yellow, pink, mint, orange

    var color: Color {
        switch self {
        case .red: Color(red: 0.5, green: 0.05, blue: 0.1)      // bordeaux
        case .yellow: Color(red: 0.85, green: 0.88, blue: 0.55)  // paille/vert clair
        case .pink: Color(red: 1.0, green: 0.42, blue: 0.55)     // rose vif
        case .mint: Color(red: 1.0, green: 0.82, blue: 0.0)      // or champagne
        case .orange: Color(red: 0.82, green: 0.52, blue: 0.08)  // ambre miel
        }
    }
}

struct Wine: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    var beverageType: BeverageType = .wine
    var color: WineColor? = nil
    var style: String? = nil
    var domain: String? = nil
    var vintage: Int? = nil
    var appellation: String? = nil
    var region: String? = nil
    var country: String? = nil
    var grapeVarieties: [String]? = nil
    var alcoholContent: Double? = nil
    var classification: String? = nil
    var purchasePrice: Double? = nil
    var purchaseDate: String? = nil
    var drinkFrom: Int? = nil
    var drinkUntil: Int? = nil
    var notes: String? = nil
    var giftedBy: String? = nil
    var rating: Int? = nil
    var isFavorite: Bool = false
    var giftedTo: String? = nil
    var recommendedBy: String? = nil
    var contacts: [String]? = nil
    var latitude: Double? = nil
    var longitude: Double? = nil
    var placeName: String? = nil
    // Status flags derived from the nested GraphQL fields — power the in-memory
    // list filters. Explicit booleans because recipient/recommender names are
    // optional: a gift without a name is still a gift.
    var isInCellar: Bool = false
    var consumedDate: Date? = nil
    var isGifted: Bool = false
    var isRecommended: Bool = false
    let createdAt: Date
    let updatedAt: Date
}

struct CreateWineRequest: Encodable, Sendable {
    let name: String
    var beverageType: BeverageType = .wine
    var color: WineColor?
    var style: String?
    var domain: String?
    var vintage: Int?
    var appellation: String?
    var region: String?
    var country: String?
    var grapeVarieties: [String]?
    var alcoholContent: Double?
    var classification: String?
    var purchasePrice: Double?
    var purchaseDate: String?
    var drinkFrom: Int?
    var drinkUntil: Int?
    var notes: String?
    var giftedBy: String?
    var rating: Int?
    var consumedDate: String?
    var tastingNotes: String?
    var contacts: [String]?
    var favorite: Bool?
    var latitude: Double?
    var longitude: Double?
    var placeName: String?
}

struct UpdateWineRequest: Encodable, Sendable {
    var name: String?
    var beverageType: BeverageType?
    var color: WineColor?
    var style: String?
    var domain: String?
    var vintage: Int?
    var appellation: String?
    var region: String?
    var country: String?
    var grapeVarieties: [String]?
    var classification: String?
    var purchasePrice: Double?
    var purchaseDate: String?
    var drinkFrom: Int?
    var drinkUntil: Int?
    var giftedBy: String?
    var notes: String?
    var latitude: Double?
    var longitude: Double?
    var placeName: String?
}
