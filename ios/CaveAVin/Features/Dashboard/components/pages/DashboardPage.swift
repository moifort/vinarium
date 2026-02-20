import SwiftUI

struct DashboardPage: View {
    @Binding var selectedTab: TabSelection

    @State private var viewModel = DashboardViewModel()
    @State private var selectedWineId: String?

    var body: some View {
        NavigationStack {
            Group {
                if let data = viewModel.data {
                    ScrollView {
                        VStack(spacing: 20) {
                            DashboardStatsRow(
                                stats: .init(bottleCount: data.bottleCount, totalValue: data.totalValue),
                                onTapped: { selectedTab = .cellar }
                            )

                            ReadyToDrinkSection(
                                items: data.readyToDrink.map { wine in
                                    .init(id: wine.id, color: wine.color, name: wine.name, urgent: wine.urgent, drinkUntil: wine.drinkUntil, position: wine.position)
                                },
                                onWineTapped: { selectedWineId = $0 }
                            )

                            FavoritesSection(
                                items: data.favorites.map { favorite in
                                    .init(id: favorite.id, color: favorite.color, name: favorite.name, vintage: favorite.vintage, tastingDate: favorite.tastingDate, estimatedPrice: favorite.estimatedPrice)
                                },
                                onWineTapped: { selectedWineId = $0 }
                            )

                            JournalSection(
                                events: data.history.map { event in
                                    .init(isEntry: event.isEntry, wineName: event.wineName, position: event.position, wineId: event.wineId)
                                },
                                onEventTapped: { selectedWineId = $0 }
                            )
                        }
                        .padding()
                    }
                } else if let error = viewModel.error {
                    ContentUnavailableView("Erreur", systemImage: "exclamationmark.triangle", description: Text(error))
                } else {
                    ProgressView("Chargement...")
                }
            }
            .navigationTitle("Accueil")
            .navigationBarTitleDisplayMode(.large)
            .refreshable { await viewModel.load() }
            .task { await viewModel.load() }
            .sheet(item: Binding(
                get: { selectedWineId.map { WineIdWrapper(id: $0) } },
                set: { selectedWineId = $0?.id }
            )) { wrapper in
                WineDetailSheet(wineId: wrapper.id)
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedTab: TabSelection = .home
    DashboardPage(selectedTab: $selectedTab)
}
