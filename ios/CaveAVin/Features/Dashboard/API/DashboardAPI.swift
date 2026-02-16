import Foundation

enum DashboardAPI {
    static func getData() async throws -> DashboardData {
        let response: APIResponse<DashboardData> = try await APIClient.shared.get("/dashboard")
        return response.data
    }
}
