import SwiftUI

/// Recherche globale plein écran, présentée en overlay depuis la loupe de la
/// toolbar. « Annuler » referme l'overlay et ramène à la page d'origine.
struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SearchViewModel()
    @State private var selectedWineId: String?
    @State private var searchActive = false
    // Le champ se ferme uniquement après avoir été ouvert : évite un dismiss
    // prématuré au tout premier rendu avant l'activation.
    @State private var didActivate = false

    var body: some View {
        NavigationStack {
            SearchPage(
                filters: $viewModel.filters,
                sections: viewModel.sections,
                hasActiveSearch: viewModel.hasActiveSearch,
                isLoading: viewModel.isLoading,
                errorMessage: viewModel.error,
                onWineTapped: { selectedWineId = $0 }
            )
            .navigationTitle("Recherche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ToolbarIconButton(title: "Fermer", systemImage: "xmark", role: .cancel) {
                        dismiss()
                    }
                    .accessibilityIdentifier("search-close-button")
                }
                if viewModel.isLoading {
                    ToolbarItem(placement: .topBarTrailing) {
                        ProgressView()
                    }
                }
            }
            .searchable(
                text: $viewModel.query,
                isPresented: $searchActive,
                prompt: "Vin, producteur, personne…"
            )
            .sheet(item: Binding(
                get: { selectedWineId.map { WineIdWrapper(id: $0) } },
                set: { selectedWineId = $0?.id }
            )) { wrapper in
                WineDetailView(
                    wineId: wrapper.id,
                    // Après une mutation dans le détail, relancer la recherche pour
                    // refléter le changement (favori, cave, suppression).
                    onRemoved: { viewModel.scheduleSearch() },
                    onUpdated: { viewModel.scheduleSearch() }
                )
            }
        }
        .onAppear { searchActive = true }
        .onChange(of: searchActive) { _, active in
            if active {
                didActivate = true
            } else if didActivate && selectedWineId == nil {
                // Le champ se désactive sur « Cancel » natif → on ferme l'overlay.
                // Garde : ne pas fermer quand la désactivation vient de la
                // présentation de la fiche détail (retour à la recherche attendu).
                dismiss()
            }
        }
    }
}
