import SwiftUI

/// Coordinateur de l'écran Admin : possède (ou reçoit) le ViewModel, charge à
/// l'apparition et délègue tout le rendu à `AdminPage`. Le bandeau passe son
/// propre ViewModel pour que la feuille affiche les chiffres déjà chargés ;
/// la ligne des Réglages laisse le coordinateur créer le sien.
struct AdminView: View {
    @State private var viewModel: AdminViewModel

    init(viewModel: AdminViewModel = AdminViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        AdminPage(
            metrics: viewModel.metrics,
            isLoading: viewModel.isLoading,
            errorMessage: viewModel.errorMessage,
            onRetry: { await viewModel.load() }
        )
        .task {
            if viewModel.metrics == nil { await viewModel.load() }
        }
        .refreshable { await viewModel.load() }
    }
}

#Preview {
    NavigationStack {
        AdminView()
    }
}
