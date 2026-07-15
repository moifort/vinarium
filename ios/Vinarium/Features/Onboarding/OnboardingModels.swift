import Foundation

/// The steps of the first-launch setup wizard, in order.
enum OnboardingStep: Int, CaseIterable {
    case welcome, firstName, preset, dimensions, summary
}

/// A real consumer wine cooler (Boulanger / Darty catalog): brand, model,
/// manufacturer bottle capacity and number of temperature zones. The app's grid
/// is uniform, so `defaultGrid()` derives a starting rows × cols from the
/// capacity — the user can adjust it afterwards. The full list lives in
/// `CellarPreset.all` (CellarPresetCatalog.swift).
struct CellarPreset: Identifiable, Hashable {
    let id: String
    let brand: String
    let model: String
    let bottles: Int
    let zones: Int

    var displayName: String { "\(brand) \(model)" }
    var capacity: Int { bottles }

    /// An indicative uniform grid holding at least `bottles`, roughly square with
    /// slightly wider rows, capped at 26 rows (A→Z) and 100 columns.
    func defaultGrid() -> (rows: Int, cols: Int) {
        CellarPreset.grid(forBottles: bottles)
    }

    static func grid(forBottles bottles: Int) -> (rows: Int, cols: Int) {
        let count = max(1, bottles)
        var cols = Int((Double(count) * 1.4).squareRoot().rounded())
        cols = min(OnboardingLimits.maxCols, max(1, cols))
        var rows = Int((Double(count) / Double(cols)).rounded(.up))
        if rows > OnboardingLimits.maxRows {
            rows = OnboardingLimits.maxRows
            cols = min(OnboardingLimits.maxCols, Int((Double(count) / Double(rows)).rounded(.up)))
        }
        return (max(1, rows), max(1, cols))
    }
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
    /// Matches the backend CellarZones validator (1..3).
    static let maxZones = 3
}
