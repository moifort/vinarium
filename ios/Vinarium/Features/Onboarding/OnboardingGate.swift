import Observation

/// Decides, once a Firebase user is signed in, whether to show the onboarding
/// wizard or the main app. Reads `me` at launch; `onboardingCompleted` drives the
/// choice. Lives at `AuthRoot` scope and is refreshed on sign-in / account switch.
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

    func refresh() async {
        state = .loading
        do {
            let me = try await OnboardingAPI.loadMe()
            state = me.onboardingCompleted ? .ready : .required
        } catch {
            state = .failed(reportError(error))
        }
    }

    /// Called by the wizard on success to enter the app without a re-fetch.
    func markCompleted() {
        state = .ready
    }
}
