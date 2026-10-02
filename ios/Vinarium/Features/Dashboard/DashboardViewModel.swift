import Foundation
import SwiftUI

/// The home tab's figures and shortlists. It opens on what it showed last time: its
/// `SnapshotCache` hands the last dashboard back from disk before anything is asked of
/// the network, and the first fetch replaces it silently instead of behind a loader.
@MainActor @Observable
final class DashboardViewModel {
    init() {
        data = cache.read()
    }

    var data: DashboardData?
    var isLoading = false
    var error: String?

    /// The last dashboard on disk. Bump the version whenever `DashboardData` changes
    /// shape.
    private let cache = SnapshotCache<DashboardData>("dashboard", version: 1)

    /// A cellar worth opening the app for. Below this the app is a form that was
    /// filled in once; above it, it is being used.
    private static let stockedThreshold = 10

    func load() async {
        isLoading = true
        error = nil
        do {
            let fetched = try await DashboardAPI.getData()
            // Over the page already on screen, the shortlists' rows slide into place
            // and the figures roll over rather than the page snapping to the answer.
            withAnimation(data == nil ? nil : .smooth) { data = fetched }
            let cache = cache
            Task.detached { cache.write(fetched) }
            if fetched.bottleCount >= Self.stockedThreshold {
                trackOnce(.cellarStocked(bottles: fetched.bottleCount))
            }
        } catch {
            self.error = reportError(error)
        }
        isLoading = false
    }
}
