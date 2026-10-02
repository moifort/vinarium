import Observation
import SwiftUI

/// Adds a cellar to the household the way the first one was set up: a name, then a
/// commercial model or a custom grid, then its dimensions. Presented as a sheet from
/// the cave tab and from Settings > Caves.
struct NewCellarView: View {
    let onCreated: (CellarSummary) -> Void
    let onPremiumRequired: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = NewCellarViewModel()

    var body: some View {
        NavigationStack {
            content
                .animation(.default, value: viewModel.step)
        }
        .alert(
            "Une erreur est survenue",
            isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.error ?? "")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.step {
        case .name:
            CellarNamePage(
                name: $viewModel.name,
                onNext: { viewModel.step = .preset },
                onClose: { dismiss() }
            )
        case .preset:
            PresetChoicePage(
                presets: CellarPreset.all,
                onSelect: { viewModel.select($0) },
                onNext: { viewModel.step = .dimensions },
                onBack: { viewModel.step = .name }
            )
        case .dimensions:
            DimensionsPage(
                rows: $viewModel.rows,
                cols: $viewModel.cols,
                zones: $viewModel.zones,
                nextTitle: "Créer la cave",
                isBusy: viewModel.isSubmitting,
                onNext: create,
                onBack: { viewModel.step = .preset }
            )
        }
    }

    private func create() {
        Task {
            switch await viewModel.submit() {
            case .created(let cellar):
                onCreated(cellar)
                dismiss()
            case .premiumRequired:
                onPremiumRequired()
            case .failed:
                break
            }
        }
    }
}

/// Drives the new-cellar flow. Same preset → dimensions steps as the onboarding,
/// preceded by the name a second cellar needs to tell it apart.
@MainActor
@Observable
final class NewCellarViewModel {
    enum Step {
        case name
        case preset
        case dimensions
    }

    enum Outcome {
        case created(CellarSummary)
        case premiumRequired
        case failed
    }

    var step: Step = .name
    var name = ""
    var rows = 6
    var cols = 8
    var zones = 1
    var choice: PresetChoice?

    private(set) var isSubmitting = false
    /// Generic failure surfaced as an alert; nil when there is nothing to show.
    var error: String?

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var canSubmit: Bool {
        !trimmedName.isEmpty
            && (1...OnboardingLimits.maxRows).contains(rows)
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

    func submit() async -> Outcome {
        guard canSubmit else { return .failed }
        isSubmitting = true
        error = nil
        defer { isSubmitting = false }
        do {
            let cellar = try await CellarAPI.create(name: trimmedName, rows: rows, cols: cols, zones: zones)
            return .created(cellar)
        } catch CellarError.premiumRequired {
            // The store said Premium, the server disagrees (lapsed since): the
            // server is right, the offer comes up.
            return .premiumRequired
        } catch {
            self.error = reportError(error)
            return .failed
        }
    }
}

#Preview {
    NewCellarView(onCreated: { _ in }, onPremiumRequired: {})
}
