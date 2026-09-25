import FirebaseCore
import SwiftUI

/// Top-level gate: shows the blocking update screen when the backend no longer
/// supports this build; otherwise LoginView when no Firebase user is signed in; once signed
/// in, reads the onboarding state and shows the wizard until it is completed,
/// otherwise the main TabView (`ContentView`). Also catches invitation links, both
/// the universal link (`https://vinarium-prod.web.app/rejoindre/<CODE>`) and the
/// custom scheme (`vinarium://rejoindre/<CODE>`), and presents the join sheet.
struct AuthRoot: View {
    @State private var session = AuthSession()
    @State private var gate = OnboardingGate()
    @State private var supportGate = AppSupportGate()
    /// App-scoped: it listens to `Transaction.updates` for the whole lifetime of
    /// the app, so a renewal landing mid-session is picked up wherever the user is.
    @State private var subscriptions = SubscriptionStore()
    @Environment(\.scenePhase) private var scenePhase

    /// A pending invitation code, kept until the app is ready to present the join
    /// sheet (a link opened while signed out surfaces after sign-in + onboarding).
    /// `ContentView` owns the presentation so it can refresh the shared cave on join.
    @State private var joinRequest: HouseholdJoinRequest?

    /// The opening's curtain, `LaunchCurtain`, over everything until the first
    /// screen is laid out underneath. Comes down again when an account signs in
    /// from the login, for that session's launch query.
    @State private var curtain: Curtain = Self.hasCurtain ? .holding : .lifted
    /// When the curtain last came down; it holds `LaunchCurtain.minimumHold` from there.
    @State private var curtainLowered = Date()

    private enum Curtain {
        case holding, revealing, lifted
    }

    /// The end-to-end scenarios tap a screen the moment it exists; the curtain
    /// would take those taps. They run without it.
    private static var hasCurtain: Bool {
        #if DEBUG
        !UITestEnvironment.isActive
        #else
        true
        #endif
    }

    var body: some View {
        ZStack {
            Group {
                if case .updateRequired(let appStoreURL) = supportGate.state {
                    UpdateRequiredView(appStoreURL: appStoreURL)
                } else if session.user == nil {
                    LoginView()
                } else {
                    signedIn
                }
            }
            if curtain != .lifted {
                LaunchCurtain(revealing: curtain == .revealing)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .environment(session)
        .environment(subscriptions)
        .environment(\.isAdmin, gate.isAdmin)
        .task { await supportGate.check() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await supportGate.check() } }
        }
        .task(id: session.user?.uid) {
            if session.user != nil {
                await launch()
            } else {
                gate.reset()
            }
        }
        .task(id: isSettled) { await settleCurtain() }
        .onOpenURL { url in
            if let code = Self.joinCode(from: url) {
                joinRequest = HouseholdJoinRequest(code: code)
            }
        }
    }

    @ViewBuilder
    private var signedIn: some View {
        switch gate.state {
        case .loading:
            // Behind the curtain, in its colour: nothing to see until the launch
            // query answers, and no flash of another background when the curtain
            // comes down again over the login.
            LaunchCurtain.background.ignoresSafeArea()
        case .required:
            OnboardingView(onCompleted: { gate.markCompleted() })
        case .ready:
            ContentView(joinRequest: $joinRequest)
        case .failed(let message):
            ContentUnavailableView {
                Label("Connexion impossible", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Réessayer") { Task { await launch() } }
            }
        }
    }

    /// The opening of the app: one query settles the onboarding gate and the plan,
    /// then the App Store offers load without holding the screen.
    private func launch() async {
        guard let launch = await gate.refresh() else { return }
        subscriptions.adopt(entitlement: launch.entitlement, quota: launch.quota)
        await subscriptions.refreshStore()
    }

    /// Nothing left to wait for behind the curtain: the login, the wizard, the
    /// app or the retry screen is laid out.
    private var isSettled: Bool {
        session.user == nil || gate.state != .loading
    }

    /// Lifts the curtain once the screen behind it is settled and it has held
    /// long enough, or lowers it again when a sign-in starts a launch query.
    /// Runs as a task keyed on `isSettled`, so a change cancels the pending one.
    private func settleCurtain() async {
        guard Self.hasCurtain else { return }
        guard isSettled else {
            if curtain == .lifted { lowerCurtain() }
            return
        }
        guard curtain == .holding else { return }
        let remaining = LaunchCurtain.minimumHold - Date().timeIntervalSince(curtainLowered)
        if remaining > 0 {
            try? await Task.sleep(for: .seconds(remaining))
        }
        if Task.isCancelled { return }
        withAnimation(.easeIn(duration: 0.5)) {
            curtain = .revealing
        } completion: {
            // A sign-in that started during the exit finds the curtain back down
            // for its launch query, instead of a bare charcoal screen.
            if isSettled {
                curtain = .lifted
            } else {
                lowerCurtain()
            }
        }
    }

    private func lowerCurtain() {
        curtainLowered = Date()
        withAnimation(.easeOut(duration: 0.25)) { curtain = .holding }
    }

    /// Extracts an invitation code from either the universal link
    /// (`https://<host>/rejoindre/<CODE>`) or the custom scheme
    /// (`vinarium://rejoindre/<CODE>`, the web page's "open in app" fallback).
    private static func joinCode(from url: URL) -> String? {
        // Custom scheme: "rejoindre" is the host, the code the single path segment.
        if url.scheme == InvitationLink.scheme {
            guard url.host == "rejoindre" else { return nil }
            let code = url.pathComponents.filter { $0 != "/" }.first?.uppercased() ?? ""
            return code.isEmpty ? nil : code
        }
        // Universal link: "rejoindre" and the code are both path segments.
        guard url.host == InvitationLink.host else { return nil }
        let parts = url.pathComponents.filter { $0 != "/" }
        guard parts.count == 2, parts[0] == "rejoindre" else { return nil }
        let code = parts[1].uppercased()
        return code.isEmpty ? nil : code
    }
}

#Preview {
    // `AuthSession` reads `Auth.auth()` on init, which traps when Firebase was
    // never configured: the canvas does not run `VinariumApp.init`, so the gate
    // configures it here. With no session in the simulator this lands on the
    // login screen, which is the only state the canvas can reach on its own.
    if FirebaseApp.app() == nil { FirebaseApp.configure() }
    return AuthRoot()
}
