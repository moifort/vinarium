import Foundation

final class APIClient: Sendable {
    static let shared = APIClient()

    private static let defaultURL = "https://cave.mottet.me"
    private static let apiToken = "801B91EB-9D7E-4AAA-B944-DB7E500BD3A7"

    var baseURL: URL {
        get {
            let stored = UserDefaults.standard.string(forKey: "serverURL") ?? Self.defaultURL
            return URL(string: stored) ?? URL(string: Self.defaultURL)!
        }
        set {
            UserDefaults.standard.set(newValue.absoluteString, forKey: "serverURL")
        }
    }

    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
    private let encoder = JSONEncoder()

    private func authenticatedRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(Self.apiToken)", forHTTPHeaderField: "Authorization")
        return request
    }

    func get<T: Decodable & Sendable>(_ path: String, query: [String: String] = [:]) async throws -> T {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        let request = authenticatedRequest(url: components.url!)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try decoder.decode(T.self, from: data)
    }

    func post<T: Decodable & Sendable>(_ path: String, body: some Encodable & Sendable) async throws -> T {
        var request = authenticatedRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try decoder.decode(T.self, from: data)
    }

    func postRaw<T: Decodable & Sendable>(_ path: String, data bodyData: Data, contentType: String) async throws -> T {
        var request = authenticatedRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try decoder.decode(T.self, from: data)
    }

    func put<T: Decodable & Sendable>(_ path: String, body: some Encodable & Sendable) async throws -> T {
        var request = authenticatedRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try decoder.decode(T.self, from: data)
    }

    func delete(_ path: String) async throws {
        var request = authenticatedRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "DELETE"
        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpError(http.statusCode)
        }
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Réponse invalide du serveur"
        case .httpError(let code):
            return "Erreur serveur (\(code))"
        }
    }
}
