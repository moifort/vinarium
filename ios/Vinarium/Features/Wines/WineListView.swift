import Sentry
import SentrySwiftUI
import SwiftUI

struct WineListView: View {
    @Binding var showFavorites: Bool
    @Binding var showRecommended: Bool

    @State private var viewModel = WineListViewModel()
    @State private var selectedWineId: String?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.groupedWines.isEmpty {
                    ProgressView("Chargement...")
                } else if !viewModel.hasWines {
                    ContentUnavailableView(
                        "Aucun vin",
                        systemImage: "wineglass",
                        description: Text("Ajoutez des vins en scannant une étiquette")
                    )
                } else {
                    WineListPage(
                        mode: $viewModel.mode,
                        sort: $viewModel.sort,
                        sortDescending: $viewModel.sortDescending,
                        statusFilter: $viewModel.statusFilter,
                        colorFilter: $viewModel.colorFilter,
                        beverageTypeFilter: $viewModel.beverageTypeFilter,
                        groups: mappedGroups,
                        hasMore: viewModel.hasMore,
                        onWineTapped: { selectedWineId = $0 },
                        onRefresh: { await viewModel.load() },
                        onPrefetch: { viewModel.prefetchIfNeeded(for: $0) },
                        onLoadMore: { await viewModel.loadMore() }
                    )
                }
            }
            .sentryTrace("Wine List", waitForFullDisplay: true)
            // Chargement initial ; les changements de vue/tri/filtre passent par les
            // didSet du ViewModel (scheduleReload).
            .task {
                await viewModel.load()
                SentrySDK.reportFullyDisplayed()
            }
            .sheet(item: Binding(
                get: { selectedWineId.map { WineIdWrapper(id: $0) } },
                set: { selectedWineId = $0?.id }
            )) { wrapper in
                WineDetailView(
                    wineId: wrapper.id,
                    onRemoved: { Task { await viewModel.load() } },
                    onUpdated: { Task { await viewModel.load() } }
                )
            }
            // Ces triggers arrivent après un scan (mutation) : le refetch est
            // nécessaire pour voir le vin fraîchement créé, pas un simple
            // changement de filtre.
            .onChange(of: showFavorites) {
                if showFavorites {
                    viewModel.mode = .favorites
                    showFavorites = false
                    viewModel.scheduleReload()
                }
            }
            .onChange(of: showRecommended) {
                if showRecommended {
                    viewModel.mode = .recommended
                    showRecommended = false
                    viewModel.scheduleReload()
                }
            }
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
                    subtitle: Self.subtitle(for: wine),
                    rating: wine.rating,
                    isFavorite: wine.isFavorite
                )
            })
        }
    }

    private static func subtitle(for wine: Wine) -> String? {
        let parts: [String] = [
            wine.vintage.map { "\($0)" },
            wine.region,
            wine.purchasePrice.map { String(format: "%.0f €", $0) },
            wine.giftedBy.map { "Offert par \(abbreviated($0))" },
            wine.giftedTo.map { "Offert à \(abbreviated($0))" },
            wine.recommendedBy.map { "Conseillé par \(abbreviated($0))" },
        ].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " • ")
    }

    private static func abbreviated(_ fullName: String) -> String {
        let components = fullName.split(separator: " ")
        if components.count >= 2, let lastInitial = components.last?.first {
            return "\(components.first!) \(lastInitial)."
        }
        return fullName
    }
}

#Preview("Liste de vins") {
    @Previewable @State var showFavorites = false
    @Previewable @State var showRecommended = false
    WineListView(showFavorites: $showFavorites, showRecommended: $showRecommended)
}
