import SwiftUI

enum BeverageType: String, Codable, CaseIterable, Identifiable, Sendable {
    case wine
    case spirit
    case beer
    case sake
    case cider
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .wine: "Vin"
        case .spirit: "Spiritueux"
        case .beer: "Bière"
        case .sake: "Saké"
        case .cider: "Cidre"
        case .other: "Autre"
        }
    }

    var icon: String {
        switch self {
        case .wine: "wineglass"
        case .spirit: "flame"
        case .beer: "mug"
        case .sake: "cup.and.saucer"
        case .cider: "applelogo"
        case .other: "questionmark.circle"
        }
    }

    /// Première lettre du type, affichée dans la pastille des boissons non-vin.
    var initial: String { String(label.prefix(1)).uppercased() }

    var displayColor: Color {
        switch self {
        case .wine: Color(red: 0.5, green: 0.05, blue: 0.1)      // bordeaux
        case .spirit: Color(red: 0.72, green: 0.45, blue: 0.2)   // ambre
        case .beer: Color(red: 0.93, green: 0.72, blue: 0.23)    // doré
        case .sake: Color(red: 0.85, green: 0.85, blue: 0.78)    // riz
        case .cider: Color(red: 0.62, green: 0.75, blue: 0.22)   // pomme
        case .other: Color(.systemGray)
        }
    }

    /// Le producteur change de nom selon la boisson — pilote le libellé du formulaire.
    var producerLabel: String {
        switch self {
        case .wine: "Domaine"
        case .spirit: "Distillerie"
        case .beer: "Brasserie"
        case .sake: "Kura"
        case .cider: "Cidrerie"
        case .other: "Producteur"
        }
    }
}
