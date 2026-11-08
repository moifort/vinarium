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
                        emptySection("Récemment", message: "Aucun événement récent")
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
                            captionKind: .price,
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
        .background(Color(.systemBackground))
        .navigationTitle("Accueil")
        .toolbarTitleDisplayMode(.inlineLarge)
        .toolbar {
            if let onAdminTapped {
                ToolbarItem(placement: .topBarTrailing) {
                    ToolbarIconButton(title: "Admin", systemImage: "shield", action: onAdminTapped)
                        .accessibilityIdentifier("dashboard-admin-button")
                }
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
            }
            ToolbarItem(placement: .topBarTrailing) {
                ToolbarIconButton(title: "Réglages", systemImage: "gearshape", action: onSettingsTapped)
                    .accessibilityIdentifier("dashboard-settings-button")
            }
            // Two round buttons, not one bar: the settings, then the search.
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            ToolbarItem(placement: .topBarTrailing) { SearchToolbarButton() }
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
            .init(id: "f1", color: .rosé, producer: "Domaine Tempier", name: "Bandol Rosé", vintage: 2023, notes: "Un rosé de garde qui gagne à être servi à 12 °C, avec une cuisine provençale ou des grillades.", isFavorite: false, urgent: true, drinkUntil: 2027, place: "B4"),
        ],
        moves: [
            .init(id: "m1", wineId: "w1", isEntry: true, color: .red, producer: "Château Margaux", name: "Pavillon Rouge du Château Margaux", vintage: 2015, position: "A1", date: .now.addingTimeInterval(-3 * 86400)),
            .init(id: "m2", wineId: "w2", isEntry: false, color: .red, producer: "Château Latour", name: "Pauillac Les Forts de Latour", vintage: 2016, position: "E3", date: .now.addingTimeInterval(-9 * 86400)),
        ],
        ready: [
            .init(id: "r1", color: .white, producer: "Vacheron", name: "Sancerre Les Monts Damnés", vintage: 2022, caption: "B1"),
            .init(id: "r2", color: .white, producer: "Château des Rontets", name: "Pouilly-Fuissé Les Crays", vintage: 2021, caption: "C3"),
            .init(id: "r3", subtype: .sparkling, color: .white, producer: "Pierre Péters", name: "Champagne Blanc de Blancs", vintage: 2017, caption: "E1"),
            .init(id: "r4", color: .white, producer: "William Fèvre", name: "Chablis Grand Cru Les Clos", vintage: 2020, caption: "A3"),
        ],
        favorites: [
            .init(id: "v1", color: .red, producer: "La Rioja Alta", name: "Rioja Gran Reserva 904", vintage: 2011, caption: "62 €"),
            .init(id: "v2", color: .white, producer: "Domaine Roulot", name: "Meursault Les Charmes", vintage: 2020, caption: "240 €"),
            .init(id: "w1", color: .red, producer: "Château Margaux", name: "Pavillon Rouge du Château Margaux", vintage: 2015, caption: "250 €"),
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
