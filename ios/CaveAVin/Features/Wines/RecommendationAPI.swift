import Foundation

enum RecommendationAPI {
    static func create(wineId: String, recommenderName: String?, comment: String?) async throws {
        struct Body: Encodable, Sendable {
            let recommenderName: String?
            let comment: String?
        }
        struct Ignored: Decodable, Sendable {}
        let _: APIResponse<Ignored> = try await APIClient.shared.post(
            "/wines/\(wineId)/recommendation",
            body: Body(recommenderName: recommenderName, comment: comment)
        )
    }
}
