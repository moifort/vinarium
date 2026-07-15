import FirebaseCore
import Sentry
import SwiftUI

@main
struct VinariumApp: App {
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
        #if DEBUG
        // Dev builds (Debug config = Xcode run / simulator) never start Sentry, so
        // their noise — e.g. simulator App Hangs — stays out of the production
        // project. Distribution builds (App Store / TestFlight, archived in Release)
        // compile the branch below and keep reporting.
        #else
        let dsn = Secrets.sentryDsn
        if dsn.isEmpty { return }

        SentrySDK.start { options in
            options.dsn = dsn
            options.tracesSampleRate = 1.0
            options.enableAutoSessionTracking = true
            options.enableTimeToFullDisplayTracing = true
            options.tracePropagationTargets = []
        }
        #endif
    }
}
