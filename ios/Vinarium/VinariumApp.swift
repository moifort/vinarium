import FirebaseCore
import SwiftUI

@main
struct VinariumApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            AuthRoot()
        }
    }
}
