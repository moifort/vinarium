import SwiftUI

@main
struct CaveAVinApp: App {
    init() {
        UserDefaults.standard.register(defaults: [APIClient.serverURLKey: APIClient.defaultURL])
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
