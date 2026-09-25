import SwiftUI

struct WineListView: View {
    @Binding var showFavorites: Bool
    @Binding var showRecommended: Bool
    /// Bumped after joining a household so the list reloads and the newly shared
    /// cellar wines appear without a manual pull-to-refresh.
    var refreshTrigger: UUID = UUID()

    @State private var viewModel = WineListViewModel()
    @State private var selectedWineId: String?

    var body: some View {
        NavigationStack {
            // Always render the page (the pinned view/filter bar at the top); only the
            // list body switches to a loader on a view/sort/filter change.
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
                refreshFailed: viewModel.refreshFailed,
                loadMoreFailed: viewModel.loadMoreFailed,
                errorMessage: viewModel.error,
                onWineTapped: { selectedWineId = $0 },
                onRefresh: { await viewModel.load() },
                onPrefetch: { viewModel.prefetchIfNeeded(for: $0) },
                onLoadMore: { await viewModel.loadMore() },
                onRetryRefresh: { await viewModel.refresh() }
            )
            // Initial load — over the cached wines when the disk had them — plus a
            // reload whenever refreshTrigger changes (after joining a household);
            // view/sort/filter changes go through the ViewModel's didSet hooks
            // (scheduleReload).
            .task(id: refreshTrigger) {
                await viewModel.loadOnAppear()
            }
            .sheet(item: Binding(
                get: { selectedWineId.map { WineIdWrapper(id: $0) } },
                set: { selectedWineId = $0?.id }
            )) { wrapper in
                WineDetailView(
                    wineId: wrapper.id,
                    // Reloaded in place: the rows stay and move to their new spot
                    // instead of the list emptying behind a loader.
                    onRemoved: { viewModel.reloadInPlace() },
                    onUpdated: { viewModel.reloadInPlace() }
                )
            }
            // These triggers fire after a scan (a mutation): the refetch is needed to
            // see the freshly created wine, this is not a plain filter change.
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

    /// Switches to a view after a scan: changing `mode` reloads through its didSet;
    /// when already on it, refetch in place so the freshly created wine slides in.
    private func switchTo(_ mode: WineListMode) {
        if viewModel.mode == mode {
            viewModel.reloadInPlace()
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
                    isInCellar: wine.isInCellar,
                    ownerName: wine.ownerName
                )
            })
        }
    }
}

#Preview("Wine list") {
    @Previewable @State var showFavorites = false
    @Previewable @State var showRecommended = false
    WineListView(showFavorites: $showFavorites, showRecommended: $showRecommended)
}
