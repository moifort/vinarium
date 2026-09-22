import SwiftUI

/// The "nothing found" phase of the flow sheet: the AI recognized nothing on the
/// photo, or in the typed description. Rendered inside the sheet's `NavigationStack`
/// (no stack of its own); closing or retrying falls back to the camera to take
/// another photo, or back to the app when the scan started from text.
struct ScanNoResultPage: View {
    var fromDescription = false
    let onClose: () -> Void

    var body: some View {
        ContentUnavailableView {
            if fromDescription {
                Label("Aucune bouteille reconnue", systemImage: "text.magnifyingglass")
            } else {
                Label("Aucune étiquette détectée", systemImage: "text.magnifyingglass")
            }
        } description: {
            if fromDescription {
                Text("L'IA n'a reconnu aucune bouteille dans ce texte. Un domaine, une cuvée ou un millésime l'aident à la trouver.")
            } else {
                Text("L'IA n'a rien trouvé à identifier ici. Réessaie avec une photo plus nette.")
            }
        } actions: {
            Button("Réessayer") { onClose() }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .padding(.top, 44)
        }
        .navigationTitle("Analyse")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Fermer", systemImage: "xmark") { onClose() }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ScanNoResultPage(onClose: {})
    }
}
