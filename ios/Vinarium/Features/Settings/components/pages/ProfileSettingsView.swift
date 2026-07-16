import SwiftUI

struct ProfileSettingsView: View {
    @Environment(AuthSession.self) private var authSession
    @State private var firstName: String?
    @State private var isLoadingFirstName = true
    @State private var loadError: String?
    @State private var signOutError: String?

    var body: some View {
        Form {
            Section {
                firstNameRow
                if let displayName = authSession.user?.displayName, !displayName.isEmpty {
                    LabeledInfoRow(title: "Nom", value: displayName, icon: "person.text.rectangle.fill")
                }
                if let email = authSession.user?.email, !email.isEmpty {
                    LabeledInfoRow(title: "Email", value: email, icon: "envelope.fill")
                }
                LabeledInfoRow(
                    title: "Identifiant",
                    value: shortUid,
                    icon: "key.fill"
                )
            } header: {
                Text("Compte")
            } footer: {
                if let loadError {
                    Text(loadError).foregroundStyle(.red)
                }
            }

            Section {
                SignOutButton(action: signOut)
            } footer: {
                if let signOutError {
                    Text(signOutError).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadFirstName() }
    }

    @ViewBuilder
    private var firstNameRow: some View {
        if isLoadingFirstName {
            Label {
                LabeledContent("Prénom") { ProgressView() }
            } icon: {
                Image(systemName: "person.fill").foregroundStyle(.secondary)
            }
        } else if let firstName, !firstName.isEmpty {
            LabeledInfoRow(title: "Prénom", value: firstName, icon: "person.fill")
        }
    }

    private func loadFirstName() async {
        isLoadingFirstName = true
        loadError = nil
        do {
            firstName = try await OnboardingAPI.loadMe().firstName
        } catch {
            loadError = error.localizedDescription
        }
        isLoadingFirstName = false
    }

    private var shortUid: String {
        guard let uid = authSession.user?.uid else { return "—" }
        return uid.prefix(8) + "…"
    }

    private func signOut() {
        do {
            try authSession.signOut()
        } catch {
            signOutError = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        ProfileSettingsView()
            .environment(AuthSession())
    }
}
