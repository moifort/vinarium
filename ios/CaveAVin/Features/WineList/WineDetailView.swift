import SwiftUI

struct WineDetailView: View {
    let wineId: String

    @State private var wine: Wine?
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let wine {
                Text(wine.name)
            } else if let error {
                ContentUnavailableView("Erreur", systemImage: "exclamationmark.triangle", description: Text(error))
            }
        }
        .navigationTitle(wine?.name ?? "Détail")
        .task {
            do {
                wine = try await WineAPI.get(id: wineId)
                isLoading = false
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }
    }
}
