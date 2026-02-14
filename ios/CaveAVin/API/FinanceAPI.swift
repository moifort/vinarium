import Foundation

enum FinanceAPI {
    static func getSummary() async throws -> FinanceSummary {
        let response: APIResponse<FinanceSummary> = try await APIClient.shared.get("/finances/summary")
        return response.data
    }
}
