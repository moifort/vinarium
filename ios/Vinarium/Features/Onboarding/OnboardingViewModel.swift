import Observation
import SwiftUI

@MainActor
@Observable
final class OnboardingViewModel {
    var firstName = ""
    var choice: PresetChoice?
    var rows = 6
    var cols = 8

    private(set) var isSubmitting = false
    var error: String?

    var trimmedFirstName: String {
        firstName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSubmit: Bool {
        !trimmedFirstName.isEmpty
            && (1...OnboardingLimits.maxRows).contains(rows)
            && (1...OnboardingLimits.maxCols).contains(cols)
    }

    var capacity: Int { rows * cols }

    /// Record the dimensioning choice and pre-fill the dimensions from it.
    func select(_ choice: PresetChoice) {
        self.choice = choice
        if case .preset(let preset) = choice {
            rows = min(preset.rows, OnboardingLimits.maxRows)
            cols = min(preset.cols, OnboardingLimits.maxCols)
        }
    }

    /// Persist the profile and cellar dimensions. Returns true on success so the
    /// coordinator can hand control back to the auth gate.
    func submit() async -> Bool {
        guard canSubmit else { return false }
        isSubmitting = true
        error = nil
        do {
            try await OnboardingAPI.completeOnboarding(
                firstName: trimmedFirstName,
                rows: rows,
                cols: cols
            )
            isSubmitting = false
            return true
        } catch {
            self.error = reportError(error)
            isSubmitting = false
            return false
        }
    }
}
