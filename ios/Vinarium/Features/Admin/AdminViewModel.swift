import SwiftUI

/// Charge les métriques admin. Partagé entre le bandeau et l'écran Admin, pour
/// qu'ouvrir la feuille ne relance pas un appel déjà affiché dans le bandeau.
@MainActor @Observable
final class AdminViewModel {
    private(set) var metrics: AdminMetrics?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            metrics = try await AdminAPI.metrics()
        } catch {
            errorMessage = reportError(error)
        }
    }
}
