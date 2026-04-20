import Apollo
import ApolloAPI
import FirebaseAuth
import Foundation

/// Injects the current Firebase user's ID token into every GraphQL request as
/// `Authorization: Bearer <token>`. Firebase Auth refreshes the token under
/// the hood so this is always fresh.
struct FirebaseTokenInterceptor: ApolloInterceptor {
    let id = UUID().uuidString

    func interceptAsync<Operation: GraphQLOperation>(
        chain: any RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, any Error>) -> Void
    ) {
        Task {
            do {
                if let token = try await Auth.auth().currentUser?.getIDToken() {
                    request.addHeader(name: "Authorization", value: "Bearer \(token)")
                }
                chain.proceedAsync(
                    request: request,
                    response: response,
                    interceptor: self,
                    completion: completion
                )
            } catch {
                chain.handleErrorAsync(
                    error,
                    request: request,
                    response: response,
                    completion: completion
                )
            }
        }
    }
}
