import SwiftUI

/// The home tab, in the tone of a magazine rather than a form: no cards, a ground
/// tinted with wine at the top, the figures in a line, the wines to open first in
/// large, then shelves of whole bottles with their labels written on them.
struct DashboardPage: View {
    let content: Content
    var onFigureTapped: (HomeFigures.Figure) -> Void = { _ in }
    var onWineTapped: (String) -> Void = { _ in }
    var onRemoveTapped: (String) -> Void = { _ in }
    var onFavoriteTapped: (String) -> Void = { _ in }
    var onMoveTapped: (String) -> Void = { _ in }
    var onRecentTapped: (() -> Void)?
    var onReadyTapped: (() -> Void)?
    var onFavoritesTapped: (() -> Void)?
    var onSettingsTapped: () -> Void = {}
    /// Admin only: opens the metrics sheet. Nil hides the button for every other account.
    var onAdminTapped: (() -> Void)?

    /// Shiori's bar: the page's name on the left and round buttons on the right, over the
    /// page with no ground of its own, sent away while scrolling down and called back by
    /// scrolling up.
    @State private var bar = ScrollBarState()
    // Optional: absent from page previews, present in the app through ContentView.
    @Environment(SearchPresenter.self) private var searchPresenter: SearchPresenter?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HomeFigures(figures: content.figures, onTapped: onFigureTapped)
                    .padding(.top, 8)

                if !content.featured.isEmpty {
                    FeaturedWineCarousel(
                        items: content.featured,
                        onOpen: onWineTapped,
                        onRemove: onRemoveTapped,
                        onFavorite: onFavoriteTapped,
                        onMove: onMoveTapped
                    )
                    .padding(.top, 26)
                }

                section {
                    if content.moves.isEmpty {
                        emptySection("Activité de la cave", message: "Aucun événement récent")
                    } else {
                        RecentMovesSection(
                            moves: content.moves,
                            onSeeAll: onRecentTapped,
                            onOpen: onWineTapped,
                            onMove: onMoveTapped
                        )
                    }
                }

                section {
                    if content.ready.isEmpty {
                        if content.featured.isEmpty {
                            emptySection("Prêt à déguster", message: "Aucun vin prêt à déguster")
                        }
                    } else {
                        BottleShelfSection(
                            title: "Prêt à déguster",
                            items: content.ready,
                            onSeeAll: onReadyTapped,
                            onWineTapped: onWineTapped
                        )
                    }
                }

                section {
                    if content.favorites.isEmpty {
                        emptySection("Mes favoris", message: "Aucun favori")
                    } else {
                        BottleShelfSection(
                            title: "Mes favoris",
                            items: content.favorites,
                            onSeeAll: onFavoritesTapped,
                            onWineTapped: onWineTapped
                        )
                        .accessibilityIdentifier("dashboard-favorites-section")
                    }
                }
            }
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(alignment: .top) {
                HomeAmbience()
                    .frame(height: 760)
                    .padding(.horizontal, -60)
                    .offset(y: -280)
            }
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        } action: { old, offset in
            bar.follow(from: old, to: offset)
        }
        .background(Color(.systemBackground))
        // The bar keeps the title for VoiceOver and the Back button, and draws its own on
        // the left, in Shiori's size.
        .navigationTitle("Accueil")
        .navigationBarTitleDisplayMode(.inline)
        // The bar stays clear over the page, as Shiori's does, the buttons on their own glass.
        .scrollEdgeEffectHidden(true, for: .top)
        .toolbar {
            ToolbarItem(placement: .principal) { Text(verbatim: "").accessibilityHidden(true) }
            ToolbarItem(placement: .topBarLeading) {
                ScrollBarItem(bar: bar) { ScrollBarTitle(title: "Accueil") }
            }
            .sharedBackgroundVisibility(.hidden)
            if let onAdminTapped {
                ToolbarItem(placement: .topBarTrailing) {
                    ScrollBarItem(bar: bar) {
                        ScrollBarButton(title: "Admin", systemImage: "shield", action: onAdminTapped)
                            .accessibilityIdentifier("dashboard-admin-button")
                    }
                }
                .sharedBackgroundVisibility(.hidden)
            }
            // Round buttons, each on its own glass: the settings, then the search.
            ToolbarItem(placement: .topBarTrailing) {
                ScrollBarItem(bar: bar) {
                    ScrollBarButton(title: "Réglages", systemImage: "gearshape", action: onSettingsTapped)
                        .accessibilityIdentifier("dashboard-settings-button")
                }
            }
            .sharedBackgroundVisibility(.hidden)
            ToolbarItem(placement: .topBarTrailing) {
                ScrollBarItem(bar: bar) {
                    ScrollBarButton(title: "Rechercher", systemImage: "magnifyingglass") {
                        searchPresenter?.present()
                    }
                    .accessibilityIdentifier("search-button")
                }
            }
            .sharedBackgroundVisibility(.hidden)
        }
    }

    private func section<Body: View>(@ViewBuilder _ body: () -> Body) -> some View {
        body().padding(.top, 34)
    }

    private func emptySection(_ title: LocalizedStringKey, message: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HomeSectionHeader(title: title)
            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
        }
    }
}

extension DashboardPage {
    struct Content: Equatable {
        let figures: HomeFigures.Figures
        /// The wines to open first, in large.
        let featured: [FeaturedWineCarousel.Item]
        let moves: [RecentMovesSection.Move]
        /// The other ready wines, on their shelf.
        let ready: [BottleShelfSection.Item]
        let favorites: [BottleShelfSection.Item]
    }
}

extension DashboardPage.Content {
    /// The board's home screen, for the previews and the debug gallery.
    static let sample = DashboardPage.Content(
        figures: .init(bottleCount: 18, readyCount: 5, favoriteCount: 3, totalValue: 2434),
        featured: [
            .init(id: "f1", color: .rosé, producer: "Domaine Tempier", name: "Bandol Rosé", vintage: 2023, domain: "Domaine Tempier", isFavorite: false, urgent: true, drinkFrom: 2024, drinkUntil: 2027, position: "B4", cellarName: "Entrée", stock: 3, price: 42, labelFamily: .provence, appellation: "Bandol"),
        ],
        moves: [
            .init(id: "m1", wineId: "w1", isEntry: true, color: .red, producer: "Château Margaux", name: "Pavillon Rouge du Château Margaux", vintage: 2015, position: "A1", date: .now.addingTimeInterval(-3 * 86400), domain: "Château Margaux", price: 250),
            .init(id: "m2", wineId: "w2", isEntry: false, color: .red, producer: "Château Latour", name: "Pauillac Les Forts de Latour", vintage: 2016, position: "E3", date: .now.addingTimeInterval(-9 * 86400), domain: "Château Latour", price: 120),
        ],
        ready: [
            .init(id: "r1", color: .white, producer: "Weinbach", name: "Riesling Schlossberg", vintage: 2021, facts: .init(place: "C3", drinkUntil: 2029, stock: 2, price: 54), labelFamily: .alsace, classification: "Grand Cru"),
            .init(id: "r2", color: .white, producer: "Vacheron", name: "Sancerre Les Romains", vintage: 2022, facts: .init(place: "B4", drinkUntil: 2027, stock: 3, price: 42), labelFamily: .loire, appellation: "Sancerre"),
            .init(id: "r3", color: .red, producer: "E. Guigal", name: "Côte-Rôtie Brune et Blonde", vintage: 2019, facts: .init(place: "A2", drinkUntil: 2030, stock: 6, price: 38), labelFamily: .rhone, appellation: "Côte-Rôtie"),
        ],
        favorites: [
            .init(id: "v1", color: .red, producer: "Château Talbot", name: "Château Talbot", vintage: 2016, facts: .init(place: "C2", drinkUntil: 2036, stock: 2, price: 68), labelFamily: .chateau, appellation: "Saint-Julien", classification: "Grand Cru Classé"),
            .init(id: "v2", color: .white, producer: "Domaine Roulot", name: "Meursault Les Charmes", vintage: 2020, facts: .init(place: nil, drinkUntil: 2030, stock: 0, price: 240), labelFamily: .burgundy, appellation: "Meursault"),
            .init(id: "w1", color: .red, producer: "Château Margaux", name: "Pavillon Rouge du Château Margaux", vintage: 2015, facts: .init(place: "D1", drinkUntil: 2040, stock: 3, price: 95), labelFamily: .chateau, appellation: "Margaux"),
        ]
    )

    /// A cellar with nothing in it yet.
    static let empty = DashboardPage.Content(
        figures: .init(bottleCount: 0, readyCount: 0, favoriteCount: 0, totalValue: 0),
        featured: [],
        moves: [],
        ready: [],
        favorites: []
    )
}

#Preview("With data") {
    NavigationStack {
        DashboardPage(content: .sample, onAdminTapped: {})
    }
}

#Preview("Empty") {
    NavigationStack {
        DashboardPage(content: .empty)
    }
}
