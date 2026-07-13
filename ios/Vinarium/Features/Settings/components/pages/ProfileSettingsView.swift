import SwiftUI

struct ProfileSettingsView: View {
    @Environment(AuthSession.self) private var authSession
    @State private var error: String?

    var body: some View {
        Form {
            Section("Compte") {
                if let displayName = authSession.user?.displayName, !displayName.isEmpty {
                    LabeledInfoRow(title: "Nom", value: displayName, icon: "person.fill")
                }
                if let email = authSession.user?.email, !email.isEmpty {
                    LabeledInfoRow(title: "Email", value: email, icon: "envelope.fill")
                }
                LabeledInfoRow(
                    title: "Identifiant",
                    value: shortUid,
                    icon: "key.fill"
                )
            }

            Section {
                SignOutButton(action: signOut)
            } footer: {
                if let error {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var shortUid: String {
        guard let uid = authSession.user?.uid else { return "—" }
        return uid.prefix(8) + "…"
    }

    private func signOut() {
        do {
            try authSession.signOut()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        ProfileSettingsView()
            .environment(AuthSession())
    }
}
