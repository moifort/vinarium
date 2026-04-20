import FirebaseCore
import Sentry
import SwiftUI

@main
struct CaveAVinApp: App {
    init() {
        FirebaseApp.configure()
        startSentry()
    }

    var body: some Scene {
        WindowGroup {
            AuthRoot()
        }
    }

    private func startSentry() {
        let dsn = Secrets.sentryDsn
        if dsn.isEmpty { return }

        SentrySDK.start { options in
            options.dsn = dsn
            options.tracesSampleRate = 1.0
            options.enableAutoSessionTracking = true
            options.enableTimeToFullDisplayTracing = true
            options.tracePropagationTargets = []
        }
    }
}
