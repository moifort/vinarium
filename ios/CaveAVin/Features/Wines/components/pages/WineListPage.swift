import Sentry
import SentrySwiftUI
import SwiftUI

struct WineListPage: View {
    @Binding var showFavorites: Bool
    @Binding var showRecommended: Bool
    @State private var viewModel = WineListViewModel()
    @State private var selectedWineId: String?

    var body: some View {
        NavigationStack {
            Group {
                if !viewModel.hasWines && (viewModel.isLoading || viewModel.isDataStale) {
                    ProgressView("Chargement...")
                } else if viewModel.wines.isEmpty && !viewModel.hasWines {
                    ContentUnavailableView("Aucun vin", systemImage: "wineglass", description: Text("Ajoutez des vins en scannant une étiquette"))
                } else {
                    WineListContent(
                        mode: viewModel.mode,
                        isLoading: viewModel.isLoading || viewModel.isDataStale,
                        groups: viewModel.groupedWines.map { label, wines in
                            .init(label: label, items: wines.map { wine in
                                .init(
                                    id: wine.id,
                                    color: wine.color,
                                    name: wine.name,
                                    subtitle: wineSubtitle(wine),
                                    rating: wine.rating,
                                    isFavorite: wine.rating == 5
                                )
                            })
                        },
                        onWineTapped: { selectedWineId = $0 }
                    )
                }
            }
            .navigationTitle(viewModel.mode.title)
            .navigationSubtitle(viewModel.mode.subtitle)
            .navigationBarTitleDisplayMode(.large)
            .sentryTrace("Wine List", waitForFullDisplay: true)
            .refreshable { await viewModel.load() }
            .task(id: viewModel.filterKey) {
                await viewModel.load()
                SentrySDK.reportFullyDisplayed()
            }
            .toolbar {
                ToolbarItemGroup {
                    ForEach(WineListMode.allCases) { mode in
                        Button {
                            viewModel.mode = mode
                        } label: {
                            Label(mode.label, systemImage: mode.icon)
                        }
                        .tint(viewModel.mode == mode ? .accentColor : .primary)
                        .accessibilityIdentifier("winelist-mode-\(mode.rawValue)")
                    }
                }
                ToolbarSpacer(.fixed)
                ToolbarItemGroup {
                    Menu {
                        Picker("Tri", selection: $viewModel.sort) {
                            ForEach(WineSort.allCases) { sort in
                                Label(sort.label, systemImage: sort.icon).tag(sort)
                            }
                        }
                        Toggle(viewModel.sortDescending ? "D\u{00E9}croissant" : "Croissant", isOn: $viewModel.sortDescending)

                        Divider()

                        Picker("Statut", selection: $viewModel.statusFilter) {
                            ForEach(WineStatusFilter.allCases) { filter in
                                Label(filter.label, systemImage: filter.icon).tag(filter)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                    .accessibilityIdentifier("winelist-sort-menu")
                }
            }
            .sheet(item: Binding(
                get: { selectedWineId.map { WineIdWrapper(id: $0) } },
                set: { selectedWineId = $0?.id }
            )) { wrapper in
                WineDetailSheet(
                    wineId: wrapper.id,
                    onRemoved: { Task { await viewModel.load() } },
                    onUpdated: { Task { await viewModel.load() } }
                )
            }
            .onChange(of: showFavorites) {
                if showFavorites {
                    viewModel.mode = .favorites
                    showFavorites = false
                    Task { await viewModel.load() }
                }
            }
            .onChange(of: showRecommended) {
                if showRecommended {
                    viewModel.mode = .recommended
                    showRecommended = false
                    Task { await viewModel.load() }
                }
            }
        }
    }

    private func wineSubtitle(_ wine: Wine) -> String? {
        let parts: [String] = [
            wine.vintage.map { "\($0)" },
            wine.region,
            wine.purchasePrice.map { String(format: "%.0f \u{20AC}", $0) },
            wine.giftedTo.map { "Offert \u{00E0} \(abbreviatedName($0))" },
            wine.recommendedBy.map { "Conseill\u{00E9} par \(abbreviatedName($0))" },
        ].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " \u{2022} ")
    }

    private func abbreviatedName(_ fullName: String) -> String {
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
    WineListPage(showFavorites: $showFavorites, showRecommended: $showRecommended)
}
