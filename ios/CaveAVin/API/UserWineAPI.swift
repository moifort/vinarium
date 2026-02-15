import Foundation

enum UserWineAPI {
    static func get(id: String) async throws -> UserWineDetail {
        let response: APIResponse<UserWineDetail> = try await APIClient.shared.get("/user-wine/\(id)")
        return response.data
    }
}
