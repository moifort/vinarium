import Foundation

enum WineAPI {
    static func scan(imageData: Data) async throws -> ScanResult {
        let response: APIResponse<ScanResult> = try await APIClient.shared.postRaw(
            "/wines/scan",
            data: imageData,
            contentType: "application/octet-stream"
        )
        return response.data
    }

    static func create(_ request: CreateWineRequest) async throws -> Wine {
        let response: APIResponse<Wine> = try await APIClient.shared.post("/wines", body: request)
        return response.data
    }

    static func list(color: WineColor? = nil, sort: String? = nil, order: String? = nil, status: String? = nil) async throws -> [Wine] {
        var query: [String: String] = [:]
        if let color { query["color"] = color.rawValue }
        if let sort { query["sort"] = sort }
        if let order { query["order"] = order }
        if let status { query["status"] = status }
        let response: APIResponse<[Wine]> = try await APIClient.shared.get("/wines", query: query)
        return response.data
    }

    static func get(id: String) async throws -> Wine {
        let response: APIResponse<Wine> = try await APIClient.shared.get("/wines/\(id)")
        return response.data
    }

    static func getDetail(id: String) async throws -> UserWineDetail {
        let response: APIResponse<UserWineDetail> = try await APIClient.shared.get("/wines/\(id)")
        return response.data
    }

    static func update(id: String, _ request: UpdateWineRequest) async throws -> Wine {
        let response: APIResponse<Wine> = try await APIClient.shared.put("/wines/\(id)", body: request)
        return response.data
    }

    static func delete(id: String) async throws {
        try await APIClient.shared.delete("/wines/\(id)")
    }

    static func getBottleImage(id: String) async throws -> Data {
        try await APIClient.shared.getRawData("/wines/\(id)/bottle-image")
    }

    static func addToFavorites(id: String) async throws {
        struct Empty: Encodable, Sendable {}
        struct Ignored: Decodable, Sendable {}
        let _: APIResponse<Ignored> = try await APIClient.shared.post(
            "/wines/\(id)/favorite",
            body: Empty()
        )
    }

    static func addToShortlist(
        id: String,
        consumedDate: String,
        rating: Int?,
        contacts: [String]?,
        tastingNotes: String?
    ) async throws {
        struct Body: Encodable, Sendable {
            let consumedDate: String
            let rating: Int?
            let contacts: [String]?
            let tastingNotes: String?
        }
        struct Ignored: Decodable, Sendable {}
        let body = Body(
            consumedDate: consumedDate,
            rating: rating,
            contacts: contacts,
            tastingNotes: tastingNotes
        )
        let _: APIResponse<Ignored> = try await APIClient.shared.post(
            "/wines/\(id)/shortlist",
            body: body
        )
    }
}
