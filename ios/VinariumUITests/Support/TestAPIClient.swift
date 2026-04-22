import Foundation

struct TestWine: Decodable {
    let id: String
    let name: String
    let color: String
}

struct TestAPIResponse<T: Decodable>: Decodable {
    let status: Int
    let data: T
}

final class TestAPIClient: @unchecked Sendable {
    static let shared = TestAPIClient()

    private let baseURL: URL
    private let token = TestSecrets.apiToken
    private let session = URLSession.shared

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let withoutFraction = ISO8601DateFormatter()
        withoutFraction.formatOptions = [.withInternetDateTime]
        d.dateDecodingStrategy = .custom { decoder in
            let s = try decoder.singleValueContainer().decode(String.self)
            if let date = withFraction.date(from: s) ?? withoutFraction.date(from: s) { return date }
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Invalid date: \(s)"))
        }
        return d
    }()

    init() {
        let envURL = ProcessInfo.processInfo.environment["TEST_SERVER_URL"]
        self.baseURL = URL(string: envURL ?? "http://localhost:3000")!
    }

    // MARK: - Wines

    @discardableResult
    func createWine(_ body: [String: Any]) throws -> TestWine {
        let data = try performRequest("POST", path: "/wines", jsonBody: body)
        let response = try decoder.decode(TestAPIResponse<TestWine>.self, from: data)
        return response.data
    }

    func listWines() throws -> [TestWine] {
        let data = try performRequest("GET", path: "/wines")
        let response = try decoder.decode(TestAPIResponse<[TestWine]>.self, from: data)
        return response.data
    }

    func deleteWine(id: String) throws {
        _ = try performRequest("DELETE", path: "/wines/\(id)")
    }

    func deleteAllWines() throws {
        let wines = try listWines()
        for wine in wines {
            try deleteWine(id: wine.id)
        }
    }

    // MARK: - Test Reset

    func resetDatabase() throws {
        _ = try performRequest("POST", path: "/test/reset")
    }

    // MARK: - Cellar

    func placeWine(wineId: String, row: String, col: Int) throws {
        _ = try performRequest("POST", path: "/cellar/place", jsonBody: [
            "wineId": wineId,
            "row": row,
            "col": col,
        ])
    }

    func removeWine(wineId: String, rating: Int? = nil, notes: String? = nil) throws {
        var body: [String: Any] = ["wineId": wineId]
        if let rating { body["rating"] = rating }
        if let notes { body["tastingNotes"] = notes }
        _ = try performRequest("POST", path: "/cellar/remove", jsonBody: body)
    }

    // MARK: - HTTP

    private func performRequest(_ method: String, path: String, jsonBody: [String: Any]? = nil) throws -> Data {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        if let jsonBody {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
        }

        var responseData: Data?
        var responseError: Error?

        let semaphore = DispatchSemaphore(value: 0)
        session.dataTask(with: request) { data, response, error in
            if let error {
                responseError = error
            } else if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                responseError = NSError(domain: "TestAPI", code: http.statusCode, userInfo: [
                    NSLocalizedDescriptionKey: "HTTP \(http.statusCode) for \(method) \(path)",
                ])
            } else {
                responseData = data
            }
            semaphore.signal()
        }.resume()
        semaphore.wait()

        if let error = responseError { throw error }
        return responseData ?? Data()
    }
}
