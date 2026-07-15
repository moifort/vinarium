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
    // Real consumer wine coolers (French market: Climadiff / La Sommelière). The
    // app's grid is uniform, so each cooler's shelf-and-capacity layout is mapped
    // to rows × cols = its manufacturer capacity (rows are A→Z, ≤ 26). These are a
    // starting point the user can adjust. Sources: climadiff.com, lasommeliere.com.
    static let all: [CellarPreset] = [
        CellarPreset(id: "climadiff-cuvee12", brand: "Climadiff", model: "Cuvée 12", rows: 4, cols: 3),
        CellarPreset(id: "climadiff-cle18", brand: "Climadiff", model: "CLE18", rows: 6, cols: 3),
        CellarPreset(id: "climadiff-cli24", brand: "Climadiff", model: "CLI24", rows: 3, cols: 8),
        CellarPreset(id: "lasommeliere-ls28", brand: "La Sommelière", model: "LS28", rows: 4, cols: 7),
        CellarPreset(id: "lasommeliere-ls50", brand: "La Sommelière", model: "LS50", rows: 5, cols: 10),
        CellarPreset(id: "lasommeliere-ls100", brand: "La Sommelière", model: "LS100", rows: 10, cols: 10),
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
