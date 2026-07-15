import Apollo
import ApolloAPI
import Foundation

enum GraphQLHelpers {
    // Cache fully disabled: `.networkOnly` never reads the normalized store, and
    // nothing in the app watches or reads it — avoids a class of stale/normalization bugs.
    static func fetch<Q: GraphQLQuery>(_ client: ApolloClient, query: Q) async throws -> Q.Data
    where Q.ResponseFormat == SingleResponseFormat {
        let response = try await client.fetch(query: query, cachePolicy: .networkOnly)
        return try unwrap(response)
    }

    static func perform<M: GraphQLMutation>(_ client: ApolloClient, mutation: M) async throws -> M.Data
    where M.ResponseFormat == SingleResponseFormat {
        let response = try await client.perform(mutation: mutation)
        return try unwrap(response)
    }

    /// Turn a `GraphQLResponse` into its `Data`, surfacing GraphQL errors and
    /// missing data as `APIError`.
    private static func unwrap<O: GraphQLOperation>(_ response: GraphQLResponse<O>) throws -> O.Data {
        if let errors = response.errors, !errors.isEmpty {
            throw APIError.graphQL(messages: errors.compactMap(\.message))
        }
        guard let data = response.data else {
            throw APIError.invalidResponse
        }
        return data
    }

    /// Decode an ISO-8601 date string from a GraphQL DateTime scalar.
    static func parseISO8601(_ string: String) -> Date? {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let withoutFraction = ISO8601DateFormatter()
        withoutFraction.formatOptions = [.withInternetDateTime]
        return withFraction.date(from: string) ?? withoutFraction.date(from: string)
    }

    /// Wrap an optional Swift value into the GraphQLNullable form expected by
    /// generated operation initializers (`.some(...)` vs `.none`).
    static func graphQLNullable<T>(_ value: T?) -> GraphQLNullable<T> {
        value.map { .some($0) } ?? .none
    }

    /// String overload: an empty/blank optional string is treated as absent
    /// (`.none`), never sent as `""`. Many server fields are branded types that
    /// require at least one character (PlaceName, Region, Domain, …), so sending
    /// `""` is rejected as BAD_USER_INPUT.
    static func graphQLNullable(_ value: String?) -> GraphQLNullable<String> {
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return .none }
        return .some(value)
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case graphQL(messages: [String])

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Réponse invalide du serveur"
        case .httpError(let code):
            return "Erreur serveur (\(code))"
        case .graphQL(let messages):
            return messages.joined(separator: " — ")
        }
    }
}
