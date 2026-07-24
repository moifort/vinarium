import SwiftUI

/// Phase « rien trouvé » de la sheet du flux : l'IA n'a rien reconnu sur la photo.
/// Rendue dans le `NavigationStack` de la sheet (pas de pile propre) ; fermer ou
/// réessayer retombe sur la caméra pour reprendre une photo.
struct ScanNoResultPage: View {
    let onClose: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Aucune étiquette détectée", systemImage: "text.magnifyingglass")
        } description: {
            Text("L'IA n'a rien trouvé à identifier ici. Réessaie avec une photo plus nette.")
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
