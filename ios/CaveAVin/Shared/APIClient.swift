import Foundation
import Sentry

final class APIClient: Sendable {
    static let shared = APIClient()

    static let defaultURL = "http://192.168.0.160:3000"
    static let serverURLKey = "serverURL"
    private static let apiToken = Secrets.apiToken

    var baseURL: URL {
        get {
            let stored = UserDefaults.standard.string(forKey: Self.serverURLKey) ?? Self.defaultURL
            if let url = URL(string: stored), !Self.isLoopbackURL(url) {
                return url
            }
            return URL(string: Self.defaultURL)!
        }
        set {
            UserDefaults.standard.set(newValue.absoluteString, forKey: Self.serverURLKey)
        }
    }

    private static func isLoopbackURL(_ url: URL) -> Bool {
        guard let host = url.host else { return false }
        return host == "localhost" || host == "127.0.0.1" || host == "::1"
    }

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
        try validateResponse(response, for: request)
        return try decoder.decode(T.self, from: data)
    }

    func post<T: Decodable & Sendable>(_ path: String, body: some Encodable & Sendable) async throws -> T {
        var request = authenticatedRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, for: request)
        return try decoder.decode(T.self, from: data)
    }

    func postRaw<T: Decodable & Sendable>(_ path: String, data bodyData: Data, contentType: String) async throws -> T {
        var request = authenticatedRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, for: request)
        return try decoder.decode(T.self, from: data)
    }

    func put<T: Decodable & Sendable>(_ path: String, body: some Encodable & Sendable) async throws -> T {
        var request = authenticatedRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, for: request)
        return try decoder.decode(T.self, from: data)
    }

    func getRawData(_ path: String) async throws -> Data {
        let request = authenticatedRequest(url: baseURL.appendingPathComponent(path))
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, for: request)
        return data
    }

    func delete(_ path: String) async throws {
        var request = authenticatedRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "DELETE"
        let (_, response) = try await session.data(for: request)
        try validateResponse(response, for: request)
    }

    private func validateResponse(_ response: URLResponse, for request: URLRequest) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        let breadcrumb = Breadcrumb(level: http.statusCode >= 400 ? .error : .info, category: "http")
        breadcrumb.type = "http"
        breadcrumb.data = [
            "method": request.httpMethod ?? "GET",
            "url": request.url?.path ?? "",
            "status_code": http.statusCode,
        ]
        SentrySDK.addBreadcrumb(breadcrumb)

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
