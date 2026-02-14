import Foundation

@MainActor @Observable
final class CellarGridViewModel {
    var grid: [[GridCell]] = []
    var isLoading = false
    var error: String?

    func load() async {
        isLoading = true
        error = nil
        do {
            grid = try await CellarAPI.getGrid()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
