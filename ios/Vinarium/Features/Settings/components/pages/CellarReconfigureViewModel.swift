import Observation
import SwiftUI

/// Drives the "reconfigure my cellar" flow reached from Settings > Cave. Mirrors
/// the onboarding preset → dimensions steps, but starts from the cellar's current
/// size and persists through `reconfigureCellar` (which refuses to strand bottles).
@MainActor
@Observable
final class CellarReconfigureViewModel {
    enum Step {
        case preset
        case dimensions
    }

    var step: Step = .preset
    var rows: Int
    var cols: Int
    var zones: Int
    var choice: PresetChoice?

    private(set) var isSubmitting = false
    /// Generic failure surfaced as an alert; nil when there is nothing to show.
    var error: String?
    /// Set when the backend refuses the resize because bottles would fall outside
    /// the new grid — carries how many, so the alert can name the count.
    var blockedCount: Int?

    /// Seed the flow with the cellar's current dimensions so nothing is lost if the
    /// user only tweaks one value.
    init(rows: Int, cols: Int, zones: Int) {
        self.rows = rows
        self.cols = cols
        self.zones = zones
    }

    var canSubmit: Bool {
        (1...OnboardingLimits.maxRows).contains(rows)
            && (1...OnboardingLimits.maxCols).contains(cols)
            && (1...OnboardingLimits.maxZones).contains(zones)
    }

    /// Record the preset/custom choice and pre-fill the dimensions from it, exactly
    /// like the onboarding step does.
    func select(_ choice: PresetChoice) {
        self.choice = choice
        if case .preset(let preset) = choice {
            let grid = preset.defaultGrid()
            rows = min(grid.rows, OnboardingLimits.maxRows)
            cols = min(grid.cols, OnboardingLimits.maxCols)
            zones = min(preset.zones, OnboardingLimits.maxZones)
        }
    }

    /// Persist the new dimensions. Returns the updated info on success so the
    /// coordinator can hand it back to the settings page and dismiss; returns nil
    /// when blocked or on error (state is exposed via `blockedCount` / `error`).
    func submit() async -> CellarSettingsInfo? {
        guard canSubmit else { return nil }
        isSubmitting = true
        error = nil
        blockedCount = nil
        defer { isSubmitting = false }
        do {
            let outcome = try await SettingsAPI.reconfigureCellar(rows: rows, cols: cols, zones: zones)
            switch outcome {
            case .success(let info):
                return info
            case .blocked(let outOfBounds):
                blockedCount = outOfBounds
                return nil
            }
        } catch {
            self.error = reportError(error)
            return nil
        }
    }
}
