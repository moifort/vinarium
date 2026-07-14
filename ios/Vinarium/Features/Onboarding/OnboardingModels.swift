import Foundation

/// The steps of the first-launch setup wizard, in order.
enum OnboardingStep: Int, CaseIterable {
    case welcome, firstName, preset, dimensions, summary
}

/// A cellar brand/model preset that pre-fills the grid dimensions.
struct CellarPreset: Identifiable, Hashable {
    let id: String
    let brand: String
    let model: String
    let rows: Int
    let cols: Int

    var displayName: String { "\(brand) \(model)" }
    var capacity: Int { rows * cols }
}

extension CellarPreset {
    // NOTE — VALEURS À VALIDER : dimensions plausibles pour amorcer le choix, à
    // confirmer avec les fiches constructeur avant mise en production. Les rangées
    // sont plafonnées à 26 (étiquettes A→Z).
    static let all: [CellarPreset] = [
        CellarPreset(id: "eurocave-pure-l", brand: "EuroCave", model: "Pure L", rows: 12, cols: 6),
        CellarPreset(id: "eurocave-compact-s", brand: "EuroCave", model: "Compact S", rows: 8, cols: 5),
        CellarPreset(id: "liebherr-wkes", brand: "Liebherr", model: "WKes 4552", rows: 10, cols: 6),
        CellarPreset(id: "climadiff-cls210", brand: "Climadiff", model: "CLS210", rows: 14, cols: 8),
        CellarPreset(id: "vinocave-168", brand: "Vinocave", model: "168 bouteilles", rows: 14, cols: 6),
        CellarPreset(id: "avintage-av54", brand: "Avintage", model: "AV54", rows: 6, cols: 5),
    ]
}

/// The user's dimensioning choice: a known preset, or a custom manual size.
enum PresetChoice: Hashable {
    case preset(CellarPreset)
    case custom
}

enum OnboardingLimits {
    /// Rows are labelled A→Z, so at most 26.
    static let maxRows = 26
    /// Matches the backend CellarCols validator (1..100).
    static let maxCols = 100
}
