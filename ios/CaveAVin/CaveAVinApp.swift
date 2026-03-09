import Sentry
import SwiftUI

@main
struct CaveAVinApp: App {
    init() {
        UserDefaults.standard.register(defaults: [
            "serverMode": "dev",
            "serverURLDev": "http://192.168.0.16:3000",
            "serverURLProd": "https://cave.mottet.me",
        ])
        startSentry()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
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
