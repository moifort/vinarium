import Observation

/// Decides, once a Firebase user is signed in, whether to show the onboarding
/// wizard or the main app. Reads `me` at launch, along with the plan and the
/// allowance; `onboardingCompleted` drives the choice. Lives at `AuthRoot` scope and is refreshed on sign-in / account switch.
@MainActor
@Observable
final class OnboardingGate {
    enum State: Equatable {
        case loading
        case required
        case ready
        case failed(String)
    }

    private(set) var state: State = .loading
    /// Whether the signed-in account may see the admin surfaces. Rides the same
    /// launch `me` query, so non-admins cost no extra call: the banner and the
    /// settings row are simply absent for them.
    private(set) var isAdmin = false

    /// Returns what the launch query read, so the caller can hand the plan and
    /// the allowance on without asking the server a second time; nil on failure.
    @discardableResult
    func refresh() async -> LaunchState? {
        state = .loading
        do {
            let launch = try await OnboardingAPI.launch()
            isAdmin = launch.me.isAdmin
            state = launch.me.onboardingCompleted ? .ready : .required
            return launch
        } catch {
            state = .failed(reportError(error))
            return nil
        }
    }

    /// Called by the wizard on success to enter the app without a re-fetch.
    func markCompleted() {
        state = .ready
    }

    /// Clear the resolved state on sign-out so a different account signing in next
    /// never sees the previous user's state for a frame before `refresh()` runs.
    func reset() {
        state = .loading
        isAdmin = false
    }
}
