import SwiftUI

/// Top-level gate: shows LoginView when no Firebase user is signed in; once signed
/// in, reads the onboarding state and shows the wizard until it is completed,
/// otherwise the main TabView (`ContentView`).
struct AuthRoot: View {
    @State private var session = AuthSession()
    @State private var gate = OnboardingGate()

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
            if session.user != nil { await gate.refresh() }
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
}
