import Apollo
import ApolloAPI
import FirebaseAuth
import Foundation

/// Injects the current Firebase user's ID token into every GraphQL request as
/// `Authorization: Bearer <token>`. Firebase Auth refreshes the token under
/// the hood so this is always fresh.
struct FirebaseTokenInterceptor: HTTPInterceptor {
    func intercept(
        request: URLRequest,
        next: NextHTTPInterceptorFunction
    ) async throws -> HTTPResponse {
        guard let currentUser = Auth.auth().currentUser else {
            return try await next(request)
        }
        let token: String = try await withCheckedThrowingContinuation { continuation in
            currentUser.getIDToken { token, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: token ?? "")
                }
            }
        }
        var authorizedRequest = request
        authorizedRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return try await next(authorizedRequest)
    }
}
