import Foundation

/// Ce que l'utilisateur veut faire de la bouteille identifiée — choisi via la
/// popup (`confirmationDialog`) déclenchée par le bouton + de la fiche, une fois
/// tous les champs saisis.
enum ScanDestination: String, CaseIterable, Identifiable, Sendable {
    case cellar
    case justSave

    var id: String { rawValue }

    var label: String {
        switch self {
        case .cellar: String(localized: "Ranger en cave")
        case .justSave: String(localized: "Juste enregistrer")
        }
    }

    var icon: String {
        switch self {
        case .cellar: "square.grid.3x3"
        case .justSave: "checkmark.circle"
        }
    }

    var accessibilityId: String { "choice-\(rawValue)" }
}
