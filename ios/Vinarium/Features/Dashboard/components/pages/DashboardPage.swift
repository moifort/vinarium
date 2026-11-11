import SwiftUI

/// The home tab, in the tone of a magazine rather than a form: no cards, a ground
/// tinted with wine at the top, the figures in a line, the wines to open first in
/// large, then shelves of whole bottles with their labels written on them. An empty
/// cellar shows none of it at zero: a bottle turning on a purple ground, and the scan.
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
    /// Opens the add flow, as the Scanner tab does: the empty cellar's one button.
    var onScanTapped: () -> Void = {}
    /// Admin only: opens the metrics sheet. Nil hides the button for every other account.
    var onAdminTapped: (() -> Void)?

    /// Shiori's bar: the page's name on the left and round buttons on the right, over the
    /// page with no ground of its own. Out of sight as the page opens, sent away while
    /// scrolling down, called back at the very top and by scrolling up below the figures.
    @State private var bar = ScrollBarState(isCalled: false)
    /// Where the page stands, set once to open it under the bar.
    @State private var position = ScrollPosition()
    @State private var openedUnderBar = false
    // Optional: absent from page previews, present in the app through ContentView.
    @Environment(SearchPresenter.self) private var searchPresenter: SearchPresenter?

    /// How far the page is scrolled as it opens: the bar's height, so the page starts just
    /// under the status bar with the bar out of sight, as Shiori's home opens. Scrolled back
    /// to the very top, the page leaves the bar its room.
    static let openingOffset: CGFloat = 50
    /// How far past that the page scrolls before scrolling up calls the bar: above it, the bar
    /// would land over the figures.
    private static let figuresClearance: CGFloat = 70

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if content.isEmptyCellar {
                    EmptyCellarWelcome(onScanTapped: onScanTapped)
                        .padding(.top, 44)
                } else {
                    filled
                }
            }
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(alignment: .top) {
                HomeAmbience(tone: content.isEmptyCellar ? .purple : .wine)
                    .frame(height: 760)
                    .padding(.horizontal, -60)
                    .offset(y: -280)
            }
        }
        .scrollPosition($position)
        .onAppear {
            guard !openedUnderBar else { return }
            openedUnderBar = true
            position.scrollTo(y: Self.openingOffset)
        }
        .onScrollGeometryChange(for: ScrollRoom.self) { geometry in
            ScrollRoom(
                offset: geometry.contentOffset.y + geometry.contentInsets.top,
                room: geometry.contentSize.height + geometry.contentInsets.top
                    + geometry.contentInsets.bottom - geometry.containerSize.height
            )
        } action: { old, new in
            // A page too short to open under the bar keeps it in sight.
            guard new.room > Self.openingOffset else { return bar.call(true) }
            bar.follow(
                from: old.offset,
                to: new.offset,
                callingBackPast: Self.openingOffset + Self.figuresClearance
            )
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

    /// The page of a cellar with wines in it: the figures, the wines to open first, the
    /// cellar's moves, then the shelves.
    @ViewBuilder
    private var filled: some View {
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

/// How far the page is scrolled, and how far it can be.
private struct ScrollRoom: Equatable {
    let offset: CGFloat
    let room: CGFloat
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
    /// Nothing in the cellar and nothing to show yet: no bottle, no move, no favorite.
    var isEmptyCellar: Bool {
        figures.bottleCount == 0 && featured.isEmpty && moves.isEmpty && ready.isEmpty && favorites.isEmpty
    }

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
