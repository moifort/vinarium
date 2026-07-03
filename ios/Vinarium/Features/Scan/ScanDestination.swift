import Foundation

/// Ce que l'utilisateur veut faire de la bouteille identifiée — choisi juste après
/// l'analyse, avant le formulaire de vérification.
enum ScanDestination: String, CaseIterable, Identifiable, Sendable {
    case cellar
    case favorite
    case shortlist
    case recommendation

    var id: String { rawValue }

    var label: String {
        switch self {
        case .cellar: "Ma cave"
        case .favorite: "Favori"
        case .shortlist: "À retenir"
        case .recommendation: "Conseillé"
        }
    }

    var caption: String {
        switch self {
        case .cellar: "Ranger la bouteille dans la cave"
        case .favorite: "Un coup de cœur dégusté"
        case .shortlist: "Goûté, à ne pas oublier"
        case .recommendation: "Recommandé par quelqu'un"
        }
    }

    var icon: String {
        switch self {
        case .cellar: "square.grid.3x3"
        case .favorite: "heart.fill"
        case .shortlist: "bookmark.fill"
        case .recommendation: "person.badge.plus"
        }
    }

    var ctaTitle: String {
        switch self {
        case .cellar: "Ajouter à la cave"
        case .favorite: "Ajouter aux favoris"
        case .shortlist: "Ajouter à retenir"
        case .recommendation: "Ajouter le conseil"
        }
    }
}
