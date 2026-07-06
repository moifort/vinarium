import SwiftUI

struct WineListView: View {
    @Binding var showFavorites: Bool
    @Binding var showRecommended: Bool

    @State private var viewModel = WineListViewModel()
    @State private var selectedWineId: String?

    var body: some View {
        NavigationStack {
            // Toujours afficher la page (barre de vues/filtre en haut fixe) ; seul le
            // corps liste passe en loader lors d'un changement de vue/tri/filtre.
            WineListPage(
                mode: $viewModel.mode,
                sort: $viewModel.sort,
                sortDescending: $viewModel.sortDescending,
                statusFilter: $viewModel.statusFilter,
                colorFilter: $viewModel.colorFilter,
                beverageTypeFilter: $viewModel.beverageTypeFilter,
                groups: mappedGroups,
                hasMore: viewModel.hasMore,
                isLoading: viewModel.isLoading,
                loadMoreFailed: viewModel.loadMoreFailed,
                errorMessage: viewModel.error,
                onWineTapped: { selectedWineId = $0 },
                onRefresh: { await viewModel.load() },
                onPrefetch: { viewModel.prefetchIfNeeded(for: $0) },
                onLoadMore: { await viewModel.loadMore() }
            )
            // Chargement initial ; les changements de vue/tri/filtre passent par les
            // didSet du ViewModel (scheduleReload).
            .task {
                await viewModel.load()
            }
            .sheet(item: Binding(
                get: { selectedWineId.map { WineIdWrapper(id: $0) } },
                set: { selectedWineId = $0?.id }
            )) { wrapper in
                WineDetailView(
                    wineId: wrapper.id,
                    // scheduleReload (et non load) : invalide les loadMore en vol
                    // pour éviter d'append des données périmées après la mutation.
                    onRemoved: { viewModel.scheduleReload() },
                    onUpdated: { viewModel.scheduleReload() }
                )
            }
            // Ces triggers arrivent après un scan (mutation) : le refetch est
            // nécessaire pour voir le vin fraîchement créé, pas un simple
            // changement de filtre.
            .onChange(of: showFavorites) {
                if showFavorites {
                    switchTo(.favorites)
                    showFavorites = false
                }
            }
            .onChange(of: showRecommended) {
                if showRecommended {
                    switchTo(.recommended)
                    showRecommended = false
                }
            }
        }
    }

    /// Bascule vers une vue après un scan : changer `mode` recharge via son didSet ;
    /// si on y est déjà, forcer le refetch pour voir le vin fraîchement créé.
    private func switchTo(_ mode: WineListMode) {
        if viewModel.mode == mode {
            viewModel.scheduleReload()
        } else {
            viewModel.mode = mode
        }
    }

    private var mappedGroups: [WineListContent.Group] {
        viewModel.groupedWines.map { label, wines in
            .init(label: label, items: wines.map { wine in
                .init(
                    id: wine.id,
                    beverageType: wine.beverageType,
                    color: wine.color,
                    name: wine.name,
                    subtitle: wine.listSubtitle,
                    rating: wine.rating,
                    isFavorite: wine.isFavorite,
                    isInCellar: wine.isInCellar
                )
            })
        }
    }
}

#Preview("Liste de vins") {
    @Previewable @State var showFavorites = false
    @Previewable @State var showRecommended = false
    WineListView(showFavorites: $showFavorites, showRecommended: $showRecommended)
}
