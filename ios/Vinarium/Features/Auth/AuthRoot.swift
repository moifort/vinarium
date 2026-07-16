import SwiftUI

/// Top-level gate: shows LoginView when no Firebase user is signed in; once signed
/// in, reads the onboarding state and shows the wizard until it is completed,
/// otherwise the main TabView (`ContentView`). Also catches invitation links, both
/// the universal link (`https://vinarium-prod.web.app/rejoindre/<CODE>`) and the
/// custom scheme (`vinarium://rejoindre/<CODE>`), and presents the join sheet.
struct AuthRoot: View {
    @State private var session = AuthSession()
    @State private var gate = OnboardingGate()

    /// A pending invitation code, kept until the app is ready to present the join
    /// sheet (a link opened while signed out surfaces after sign-in + onboarding).
    /// `ContentView` owns the presentation so it can refresh the shared cave on join.
    @State private var joinRequest: HouseholdJoinRequest?

    var body: some View {
        Group {
            if session.user == nil {
                LoginView()
            } else {
                signedIn
            }
        }
        .environment(session)
        .task(id: session.user?.uid) {
            if session.user != nil {
                await gate.refresh()
            } else {
                gate.reset()
            }
        }
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
            ProgressView("Chargement…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                Button("Réessayer") { Task { await gate.refresh() } }
            }
        }
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
