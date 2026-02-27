import Foundation
import Sentry

func reportError(_ error: Error) -> String {
    let nsError = error as NSError
    let isCancellation = error is CancellationError
        || (nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled)
    if !isCancellation {
        SentrySDK.capture(error: error)
    }
    return error.localizedDescription
}
