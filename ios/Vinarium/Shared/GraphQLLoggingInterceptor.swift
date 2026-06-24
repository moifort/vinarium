import Apollo
import ApolloAPI
import Foundation
import OSLog

private let log = Logger(subsystem: "com.polyforms.vinarium.app", category: "graphql")

struct GraphQLLoggingInterceptor: GraphQLInterceptor {
    func intercept<Request: GraphQLRequest>(
        request: Request,
        next: NextInterceptorFunction<Request>
    ) async throws -> InterceptorResultStream<Request> {
        return await next(request)
            .map { parsedResult in
                if let errors = parsedResult.result.errors, !errors.isEmpty {
                    for error in errors {
                        let code = (error.extensions?["code"] as? String) ?? "<no code>"
                        let message = error.message ?? "<no message>"
                        log.error(
                            "\(Request.Operation.operationName, privacy: .public) [\(code, privacy: .public)] \(message, privacy: .public)"
                        )
                    }
                }
                return parsedResult
            }
    }
}
