import Foundation

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

    /// That refresh failed: the figures on screen are the ones from last time, and the
    /// leading row offers to try again.
    private(set) var refreshFailed = false

    /// The server has answered at least once, so what is on screen is no longer the
    /// snapshot.
    private var loaded = false

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
            data = fetched
            loaded = true
            refreshFailed = false
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

    /// The tab appeared: a dashboard still showing last session's snapshot refreshes it
    /// in place, anything else loads as it always did.
    func loadOnAppear() async {
        if !loaded, data != nil {
            await refresh()
        } else {
            await load()
        }
    }

    /// Bring the snapshot on screen up to date without taking it away — and the retry
    /// when that failed.
    func refresh() async {
        refreshFailed = false
        await load()
        refreshFailed = !loaded
    }
}
