import SwiftUI

struct DashboardView: View {
    @Binding var selectedTab: TabSelection

    @State private var viewModel = DashboardViewModel()
    @State private var selectedWineId: String?
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if let data = viewModel.data {
                    DashboardPage(
                        content: Self.map(data),
                        onStatsTapped: { selectedTab = .cellar },
                        onWineTapped: { selectedWineId = $0 },
                        onSettingsTapped: { showSettings = true }
                    )
                } else if let error = viewModel.error {
                    ContentUnavailableView("Erreur", systemImage: "exclamationmark.triangle", description: Text(error))
                } else {
                    // First-load screen: cold-started backend functions make this
                    // wait noticeable, so it gets the swirling-glass loader.
                    VStack(spacing: 20) {
                        WineGlassLoader()
                        Text("Chargement...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .refreshable { await viewModel.load() }
            .task {
                await viewModel.load()
            }
            // La vue reste vivante dans le TabView : sans ça, revenir sur Accueil
            // après un scan/une mutation montrerait des stats périmées.
            .onChange(of: selectedTab) {
                if selectedTab == .home {
                    Task { await viewModel.load() }
                }
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
            .sheet(isPresented: $showSettings) {
                SettingsHomeView()
            }
            .onReceive(NotificationCenter.default.publisher(for: .vinariumDataDidReload)) { _ in
                Task { await viewModel.load() }
            }
        }
    }

    private static func map(_ data: DashboardData) -> DashboardPage.Content {
        .init(
            stats: .init(bottleCount: data.bottleCount, capacity: data.capacity, totalValue: data.totalValue),
            readyToDrink: data.readyToDrink.map { wine in
                .init(id: wine.id, beverageType: wine.beverageType, color: wine.color, name: wine.name, urgent: wine.urgent, drinkUntil: wine.drinkUntil, position: wine.position)
            },
            favorites: data.favorites.map { favorite in
                .init(id: favorite.id, beverageType: favorite.beverageType, color: favorite.color, name: favorite.name, vintage: favorite.vintage, tastingDate: favorite.tastingDate, estimatedPrice: favorite.estimatedPrice, rating: favorite.rating)
            },
            events: data.history.map { event in
                .init(isEntry: event.isEntry, wineName: event.wineName, position: event.position, wineId: event.wineId, date: event.date, memberName: event.memberName)
            }
        )
    }
}

#Preview {
    @Previewable @State var selectedTab: TabSelection = .home
    DashboardView(selectedTab: $selectedTab)
}
