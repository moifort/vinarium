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

    static func delete(id: String) async throws {
        try await APIClient.shared.delete("/wines/\(id)")
    }
}
