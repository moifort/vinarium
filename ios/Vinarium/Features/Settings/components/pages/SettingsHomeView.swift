import SwiftUI

struct SettingsHomeView: View {
    @Environment(AuthSession.self) private var authSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        ProfileSettingsView()
                    } label: {
                        SettingsRow(
                            icon: "person.crop.circle.fill",
                            title: "Profil",
                            subtitle: profileSubtitle,
                            tint: .blue
                        )
                    }
                }

                Section("Application") {
                    NavigationLink {
                        ChangelogListView()
                    } label: {
                        SettingsRow(
                            icon: "doc.text.fill",
                            title: "Version & changelog",
                            subtitle: "v\(appVersion) (\(buildNumber))",
                            tint: .indigo
                        )
                    }
                }

                Section("Cave") {
                    NavigationLink {
                        CellarInfoSettingsView()
                    } label: {
                        SettingsRow(
                            icon: "square.grid.3x3.fill",
                            title: "Informations",
                            tint: .brown
                        )
                    }
                    NavigationLink {
                        SharingSettingsView()
                    } label: {
                        SettingsRow(
                            icon: "person.2.fill",
                            title: "Partage",
                            tint: .purple
                        )
                    }
                }

                Section("Données") {
                    NavigationLink {
                        ImportExportSettingsView()
                    } label: {
                        SettingsRow(
                            icon: "square.and.arrow.up.fill",
                            title: "Importer / Exporter",
                            tint: .teal
                        )
                    }
                }
            }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    ToolbarIconButton(title: "Fermer", systemImage: "xmark", role: .cancel) { dismiss() }
                }
            }
        }
    }

    private var profileSubtitle: String? {
        authSession.user?.displayName ?? authSession.user?.email
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }
}

#Preview {
    SettingsHomeView()
        .environment(AuthSession())
}
