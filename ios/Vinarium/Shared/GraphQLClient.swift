import Apollo
import ApolloAPI
import Foundation

/// Singleton ApolloClient configured for the Firebase Functions /graphql endpoint.
/// Each request goes through:
///   1. FirebaseTokenInterceptor — injects Authorization: Bearer <ID Token>
///   2. (Apollo default chain — parsing, error handling, caching)
///   3. GraphQLLoggingInterceptor — logs operation name + GraphQL errors
final class GraphQLClient: @unchecked Sendable {
    static let shared = GraphQLClient()

    // Built once: recreating the store/transport per request would discard
    // connection reuse. The base URL is read at init — changing the server URL
    // in the debug settings requires an app restart.
    let apollo: ApolloClient

    private init() {
        let url = APIClient.shared.baseURL.appendingPathComponent("graphql")
        let store = ApolloStore()
        let interceptorProvider = AuthenticatedInterceptorProvider()
        let transport = RequestChainNetworkTransport(
            urlSession: URLSession.shared,
            interceptorProvider: interceptorProvider,
            store: store,
            endpointURL: url
        )
        apollo = ApolloClient(networkTransport: transport, store: store)
    }
}

/// In Apollo iOS 2.x, DefaultInterceptorProvider is final and cannot be subclassed.
/// Instead, conform to InterceptorProvider and delegate to DefaultInterceptorProvider.shared
/// for the standard interceptors, then inject custom ones.
struct AuthenticatedInterceptorProvider: InterceptorProvider {
    func httpInterceptors<Operation: GraphQLOperation>(
        for operation: Operation
    ) -> [any HTTPInterceptor] {
        // FirebaseTokenInterceptor runs first (pre-flight) so the token is set
        // before any other HTTP interceptor sees the URLRequest.
        [FirebaseTokenInterceptor()] + DefaultInterceptorProvider.shared.httpInterceptors(for: operation)
    }

    func graphQLInterceptors<Operation: GraphQLOperation>(
        for operation: Operation
    ) -> [any GraphQLInterceptor] {
        // GraphQLLoggingInterceptor appended last so it receives the final
        // parsed result post-flight (chain traversal is reversed on the way back).
        DefaultInterceptorProvider.shared.graphQLInterceptors(for: operation) + [GraphQLLoggingInterceptor()]
    }
}
