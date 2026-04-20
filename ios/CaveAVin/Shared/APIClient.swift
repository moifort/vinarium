import Foundation

/// Resolves the Firebase Functions endpoint that hosts the GraphQL API.
/// All HTTP transport now happens through GraphQLClient (Apollo iOS).
struct APIClient: Sendable {
    static let shared = APIClient()

    private static let serverURLKey = "serverURL"
    private static let defaultServerURL = "https://cave-a-vin.example.com"

    var baseURL: URL {
        let stored = UserDefaults.standard.string(forKey: Self.serverURLKey)
            ?? Self.defaultServerURL
        return URL(string: stored) ?? URL(string: Self.defaultServerURL)!
    }
}
