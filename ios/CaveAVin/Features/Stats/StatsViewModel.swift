import Foundation

@MainActor @Observable
final class StatsViewModel {
    var summary: FinanceSummary?
    var isLoading = false
    var error: String?

    func load() async {
        isLoading = true
        error = nil
        do {
            summary = try await FinanceAPI.getSummary()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
