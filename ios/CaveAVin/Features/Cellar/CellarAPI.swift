import Foundation

enum CellarAPI {
    static func getBottles() async throws -> [CellarBottle] {
        let response: APIResponse<[CellarBottle]> = try await APIClient.shared.get("/cellar/bottles")
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

    static func place(wineId: String, row: String, col: Int) async throws {
        struct Body: Encodable, Sendable { let wineId: String; let row: String; let col: Int }
        struct Ignored: Decodable, Sendable {}
        let _: APIResponse<Ignored> = try await APIClient.shared.post(
            "/cellar/place",
            body: Body(wineId: wineId, row: row, col: col)
        )
    }

    static func remove(wineId: String, consumedDate: String? = nil, rating: Int? = nil, tastingNotes: String? = nil, contacts: [String]? = nil) async throws {
        struct Body: Encodable, Sendable {
            let wineId: String
            var consumedDate: String?
            var rating: Int?
            var tastingNotes: String?
            var contacts: [String]?
        }
        struct Ignored: Decodable, Sendable {}
        let _: APIResponse<Ignored> = try await APIClient.shared.post(
            "/cellar/remove",
            body: Body(wineId: wineId, consumedDate: consumedDate, rating: rating, tastingNotes: tastingNotes, contacts: contacts)
        )
    }

    static func gift(wineId: String, giftedDate: String, recipientName: String? = nil) async throws {
        struct GiftBody: Encodable, Sendable {
            let giftedDate: String
            var recipientName: String?
        }
        struct Body: Encodable, Sendable {
            let wineId: String
            let gift: GiftBody
        }
        struct Ignored: Decodable, Sendable {}
        let _: APIResponse<Ignored> = try await APIClient.shared.post(
            "/cellar/remove",
            body: Body(wineId: wineId, gift: GiftBody(giftedDate: giftedDate, recipientName: recipientName))
        )
    }

    static func getHistory() async throws -> [HistoryEvent] {
        let response: APIResponse<[HistoryEvent]> = try await APIClient.shared.get("/cellar/history")
        return response.data
    }
}
