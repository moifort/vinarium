import Sentry
import SentrySwiftUI
import SwiftUI

struct DashboardView: View {
    @Binding var selectedTab: TabSelection

    @State private var viewModel = DashboardViewModel()
    @State private var selectedWineId: String?

    var body: some View {
        NavigationStack {
            Group {
                if let data = viewModel.data {
                    DashboardPage(
                        content: Self.map(data),
                        onStatsTapped: { selectedTab = .cellar },
                        onWineTapped: { selectedWineId = $0 }
                    )
                } else if let error = viewModel.error {
                    ContentUnavailableView("Erreur", systemImage: "exclamationmark.triangle", description: Text(error))
                } else {
                    ProgressView("Chargement...")
                }
            }
            .sentryTrace("Dashboard", waitForFullDisplay: true)
            .refreshable { await viewModel.load() }
            .task {
                await viewModel.load()
                SentrySDK.reportFullyDisplayed()
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
        }
    }

    private static func map(_ data: DashboardData) -> DashboardPage.Content {
        .init(
            stats: .init(bottleCount: data.bottleCount, totalValue: data.totalValue),
            readyToDrink: data.readyToDrink.map { wine in
                .init(id: wine.id, color: wine.color, name: wine.name, urgent: wine.urgent, drinkUntil: wine.drinkUntil, position: wine.position)
            },
            favorites: data.favorites.map { favorite in
                .init(id: favorite.id, color: favorite.color, name: favorite.name, vintage: favorite.vintage, tastingDate: favorite.tastingDate, estimatedPrice: favorite.estimatedPrice)
            },
            shortlist: data.shortlist.map { entry in
                .init(id: entry.id, color: entry.color, name: entry.name, vintage: entry.vintage, tastingDate: entry.tastingDate, rating: entry.rating)
            },
            events: data.history.map { event in
                .init(isEntry: event.isEntry, wineName: event.wineName, position: event.position, wineId: event.wineId, date: event.date)
            }
        )
    }
}

#Preview {
    @Previewable @State var selectedTab: TabSelection = .home
    DashboardView(selectedTab: $selectedTab)
}
