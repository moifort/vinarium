import SwiftUI

struct DashboardView: View {
    @Binding var selectedTab: TabSelection
    /// Opens the wine list on the favorites.
    var showFavorites: Binding<Bool> = .constant(false)

    @State private var viewModel = DashboardViewModel()
    /// The wine sheet on screen, and what it opens straight onto.
    @State private var openedWine: OpenedWine?
    @State private var showSettings = false
    @State private var showAdmin = false
    @Environment(\.isAdmin) private var isAdmin

    var body: some View {
        NavigationStack {
            Group {
                if let data = viewModel.data {
                    DashboardPage(
                        content: Self.map(data),
                        onFigureTapped: { figure in
                            switch figure {
                            case .bottles, .ready, .value: selectedTab = .cellar
                            case .favorites: openFavorites()
                            }
                        },
                        onWineTapped: { openedWine = OpenedWine(id: $0) },
                        onRemoveTapped: { openedWine = OpenedWine(id: $0, action: .remove) },
                        onFavoriteTapped: { openedWine = OpenedWine(id: $0, action: .favorite) },
                        onMoveTapped: { openedWine = OpenedWine(id: $0, action: .move) },
                        onRecentTapped: { selectedTab = .cellar },
                        onReadyTapped: { selectedTab = .cellar },
                        onFavoritesTapped: { openFavorites() },
                        onSettingsTapped: { showSettings = true },
                        onAdminTapped: isAdmin ? { showAdmin = true } : nil
                    )
                } else if viewModel.error != nil {
                    // Nothing from last time and the load failed: nothing shows, and a
                    // pull tries again.
                    PullToRefreshSpace()
                } else {
                    LoadingStateView()
                }
            }
            .refreshable { await viewModel.load() }
            // Over last session's snapshot when the disk had one: the page shows at
            // once and settles on the server's figures when they arrive.
            .task {
                await viewModel.load()
            }
            // The view stays alive inside the TabView: without this, coming back to the
            // home tab after a scan or a mutation would show stale stats.
            .onChange(of: selectedTab) {
                if selectedTab == .home {
                    Task { await viewModel.load() }
                }
            }
            .sheet(item: $openedWine) { opened in
                WineDetailView(
                    wineId: opened.id,
                    initialAction: opened.action,
                    onRemoved: { Task { await viewModel.load() } },
                    onUpdated: { Task { await viewModel.load() } }
                )
            }
            .sheet(isPresented: $showSettings) {
                SettingsHomeView()
            }
            .sheet(isPresented: $showAdmin) {
                NavigationStack {
                    AdminView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                ToolbarIconButton(title: "Fermer", systemImage: "xmark", role: .cancel) {
                                    showAdmin = false
                                }
                            }
                        }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .vinariumDataDidReload)) { _ in
                Task { await viewModel.load() }
            }
        }
    }

    private func openFavorites() {
        showFavorites.wrappedValue = true
        selectedTab = .wines
    }

    private struct OpenedWine: Identifiable {
        let id: String
        var action: WineDetailView.InitialAction?
    }

    private static func map(_ data: DashboardData) -> DashboardPage.Content {
        // The wines due soonest open the page in large; with none due, the first
        // ready one does. The rest stand on the shelf below.
        let urgent = data.readyToDrink.filter(\.urgent)
        let featured = urgent.isEmpty ? Array(data.readyToDrink.prefix(1)) : urgent
        let featuredIds = Set(featured.map(\.id))
        return .init(
            figures: .init(
                bottleCount: data.bottleCount,
                readyCount: data.readyToDrinkCount,
                favoriteCount: data.favoriteCount,
                totalValue: data.totalValue
            ),
            featured: featured.map { wine in
                .init(
                    id: wine.id,
                    beverageType: wine.beverageType,
                    subtype: wine.subtype,
                    color: wine.color,
                    producer: ProducerOverline.text(for: wine.producer, name: wine.name),
                    name: wine.name,
                    vintage: wine.vintage,
                    notes: wine.notes?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                    isFavorite: wine.isFavorite,
                    urgent: wine.urgent,
                    drinkUntil: wine.drinkUntil,
                    place: wine.cellarName.map { "\($0) · \(wine.position)" } ?? wine.position
                )
            },
            moves: data.history.map { event in
                .init(
                    id: event.id,
                    wineId: event.wineId,
                    isEntry: event.isEntry,
                    beverageType: event.wineBeverageType,
                    subtype: event.wineSubtype,
                    color: event.wineColor,
                    producer: ProducerOverline.text(for: event.producer, name: event.wineName),
                    name: event.wineName,
                    vintage: event.wineVintage,
                    position: event.position,
                    date: event.date,
                    memberName: event.memberName
                )
            },
            ready: data.readyToDrink.filter { !featuredIds.contains($0.id) }.map { wine in
                .init(
                    id: wine.id,
                    beverageType: wine.beverageType,
                    subtype: wine.subtype,
                    color: wine.color,
                    producer: ProducerOverline.text(for: wine.producer, name: wine.name),
                    name: wine.name,
                    vintage: wine.vintage,
                    caption: wine.position
                )
            },
            favorites: data.favorites.map { favorite in
                .init(
                    id: favorite.id,
                    beverageType: favorite.beverageType,
                    subtype: favorite.subtype,
                    color: favorite.color,
                    producer: ProducerOverline.text(for: favorite.producer, name: favorite.name),
                    name: favorite.name,
                    vintage: favorite.vintage,
                    caption: favorite.estimatedPrice.map { Money.formattedFromEur($0, fractionLength: 0) }
                )
            }
        )
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

#Preview {
    @Previewable @State var selectedTab: TabSelection = .home
    DashboardView(selectedTab: $selectedTab)
}
