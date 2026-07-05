import SwiftUI

/// Pilote l'ouverture de la recherche globale. Partagé via l'environnement pour
/// que la loupe de n'importe quelle page présente le même overlay au niveau racine.
@MainActor @Observable
final class SearchPresenter {
    var isPresented = false

    func present() { isPresented = true }
}

private struct SearchToolbarButton: View {
    // Optionnel : absent des previews de page, présent dans l'app via ContentView.
    @Environment(SearchPresenter.self) private var presenter: SearchPresenter?

    var body: some View {
        Button { presenter?.present() } label: {
            Image(systemName: "magnifyingglass")
        }
        .accessibilityIdentifier("search-button")
        .accessibilityLabel("Rechercher")
    }
}

extension View {
    /// Ajoute la loupe de recherche globale en tête de barre. À poser sur la page
    /// racine de chaque onglet qui doit y donner accès.
    func searchToolbarButton() -> some View {
        toolbar {
            ToolbarItem(placement: .topBarTrailing) { SearchToolbarButton() }
        }
    }
}
