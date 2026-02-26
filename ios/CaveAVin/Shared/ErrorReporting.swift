import Foundation
import Sentry

func reportError(_ error: Error) -> String {
    SentrySDK.capture(error: error)
    return error.localizedDescription
}
