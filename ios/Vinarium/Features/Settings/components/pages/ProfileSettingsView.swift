import SwiftUI

struct ProfileSettingsView: View {
    @Environment(AuthSession.self) private var authSession
    @State private var error: String?

    var body: some View {
        Form {
            Section("Compte") {
                if let firstName, !firstName.isEmpty {
                    LabeledInfoRow(title: "Prénom", value: firstName, icon: "person.fill")
                }
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

    private var firstName: String? {
        guard let displayName = authSession.user?.displayName else { return nil }
        return displayName.split(separator: " ").first.map(String.init)
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
