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
        case .red: .red
        case .yellow: Color(.systemYellow)
        case .pink: .pink
        case .mint: .mint
        case .orange: .orange
        }
    }
}

struct Wine: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let color: WineColor
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
    var imageBase64: String?
    var notes: String?
    var rating: Int?
    let createdAt: Date
    let updatedAt: Date
}

struct CreateWineRequest: Encodable, Sendable {
    let name: String
    let color: WineColor
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
    var imageBase64: String?
    var notes: String?
}

struct APIResponse<T: Decodable & Sendable>: Decodable, Sendable {
    let status: Int
    let data: T
}
