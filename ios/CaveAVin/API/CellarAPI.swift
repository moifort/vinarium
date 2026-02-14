import Foundation

enum CellarAPI {
    static func getConfig() async throws -> CellarConfig {
        let response: APIResponse<CellarConfig> = try await APIClient.shared.get("/cellar/config")
        return response.data
    }

    static func getGrid() async throws -> [[GridCell]] {
        let response: APIResponse<[[GridCell]]> = try await APIClient.shared.get("/cellar/grid")
        return response.data
    }

    static func getEntry(wineId: String) async throws -> CellarEntry {
        let response: APIResponse<CellarEntry> = try await APIClient.shared.get("/cellar/entry/\(wineId)")
        return response.data
    }

    static func suggest(wineId: String) async throws -> CellarSuggestion {
        struct Body: Encodable, Sendable { let wineId: String }
        let response: APIResponse<CellarSuggestion> = try await APIClient.shared.post(
            "/cellar/suggest",
            body: Body(wineId: wineId)
        )
        return response.data
    }

    static func place(wineId: String, row: String, col: Int) async throws -> CellarEntry {
        struct Body: Encodable, Sendable { let wineId: String; let row: String; let col: Int }
        let response: APIResponse<CellarEntry> = try await APIClient.shared.post(
            "/cellar/place",
            body: Body(wineId: wineId, row: row, col: col)
        )
        return response.data
    }

    static func remove(wineId: String, consumedDate: String? = nil, rating: Int? = nil, tastingNotes: String? = nil) async throws -> CellarEntry {
        struct Body: Encodable, Sendable {
            let wineId: String
            var consumedDate: String?
            var rating: Int?
            var tastingNotes: String?
        }
        let response: APIResponse<CellarEntry> = try await APIClient.shared.post(
            "/cellar/remove",
            body: Body(wineId: wineId, consumedDate: consumedDate, rating: rating, tastingNotes: tastingNotes)
        )
        return response.data
    }
}
