import Foundation

@MainActor @Observable
final class DashboardViewModel {
    var data: DashboardData?
    var isLoading = false
    var error: String?

    func load() async {
        isLoading = true
        error = nil
        do {
            data = try await DashboardAPI.getData()
        } catch {
            self.error = reportError(error)
        }
        isLoading = false
    }
}
