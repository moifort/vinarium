import SwiftUI

/// Sheet présentée quand l'IA n'a rien reconnu sur la photo. La caméra reste
/// visible derrière ; fermer ou réessayer ramène directement dessus.
struct ScanNoResultPage: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Aucune étiquette détectée", systemImage: "text.magnifyingglass")
            } description: {
                Text("L'IA n'a rien trouvé à identifier ici. Réessaie avec une photo plus nette.")
            } actions: {
                Button("Réessayer") { dismiss() }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .padding(.top, 44)
            }
            .navigationTitle("Analyse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer", systemImage: "xmark") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    Color.black
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            ScanNoResultPage()
        }
}
