import SwiftUI

/// Top-level gate: shows LoginView when no Firebase user is signed in; once signed
/// in, reads the onboarding state and shows the wizard until it is completed,
/// otherwise the main TabView (`ContentView`). Also catches invitation universal
/// links (`https://vinarium.app/rejoindre/<CODE>`) and presents the join sheet.
struct AuthRoot: View {
    @State private var session = AuthSession()
    @State private var gate = OnboardingGate()
    @State private var joinRequest: JoinRequest?

    /// A pending invitation code, kept until the app is ready to present the join
    /// sheet (a link opened while signed out surfaces after sign-in + onboarding).
    private struct JoinRequest: Identifiable {
        let code: String
        var id: String { code }
    }

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
                joinRequest = JoinRequest(code: code)
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
            ContentView()
                .sheet(item: $joinRequest) { request in
                    JoinHouseholdSheet(code: request.code)
                }
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

    /// Extracts an invitation code from a `/rejoindre/<CODE>` universal link.
    private static func joinCode(from url: URL) -> String? {
        guard url.host == "vinarium.app" else { return nil }
        let parts = url.pathComponents.filter { $0 != "/" }
        guard parts.count == 2, parts[0] == "rejoindre" else { return nil }
        let code = parts[1].uppercased()
        return code.isEmpty ? nil : code
    }
}
