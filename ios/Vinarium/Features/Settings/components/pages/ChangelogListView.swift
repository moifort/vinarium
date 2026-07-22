import SwiftUI

struct ChangelogListView: View {
    @State private var entries: [ChangelogVersion] = []
    @State private var error: String?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                LoadingStateView()
            } else if let error {
                ContentUnavailableView(
                    "Erreur",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if entries.isEmpty {
                ContentUnavailableView("Aucune entrée", systemImage: "doc.text")
            } else {
                List(entries) { entry in
                    NavigationLink {
                        ChangelogDetailView(entry: entry)
                    } label: {
                        ChangelogEntryRow(
                            version: entry.version,
                            date: entry.date,
                            summary: entry.notes.first ?? ""
                        )
                    }
                }
            }
        }
        .navigationTitle("Version & changelog")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        do {
            entries = try await SettingsAPI.loadChangelog()
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        ChangelogListView()
    }
}
