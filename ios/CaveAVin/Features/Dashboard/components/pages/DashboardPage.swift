import SwiftUI

struct DashboardPage: View {
    let content: Content
    var onStatsTapped: () -> Void
    var onWineTapped: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                DashboardStatsRow(stats: content.stats, onTapped: onStatsTapped)

                ReadyToDrinkSection(items: content.readyToDrink, onWineTapped: onWineTapped)

                FavoritesSection(items: content.favorites, onWineTapped: onWineTapped)

                ShortlistSection(items: content.shortlist, onWineTapped: onWineTapped)

                JournalSection(events: content.events, onEventTapped: onWineTapped)
            }
            .padding()
        }
        .navigationTitle("Accueil")
        .navigationBarTitleDisplayMode(.large)
    }
}

extension DashboardPage {
    struct Content {
        let stats: DashboardStatsRow.Stats
        let readyToDrink: [ReadyToDrinkSection.Item]
        let favorites: [FavoritesSection.Item]
        let shortlist: [ShortlistSection.Item]
        let events: [JournalSection.Event]
    }
}

#Preview("Avec données") {
    NavigationStack {
        DashboardPage(
            content: .init(
                stats: .init(bottleCount: 42, totalValue: 1850),
                readyToDrink: [
                    .init(id: "1", color: .red, name: "Château Margaux 2018", urgent: true, drinkUntil: 2026, position: "A3"),
                    .init(id: "2", color: .white, name: "Pouilly-Fumé 2021", urgent: false, drinkUntil: nil, position: "B1"),
                ],
                favorites: [
                    .init(id: "3", color: .red, name: "Romanée-Conti 2015", vintage: 2015, tastingDate: Date(), estimatedPrice: 3500),
                ],
                shortlist: [
                    .init(id: "4", color: .white, name: "Chablis Grand Cru", vintage: 2019, tastingDate: nil, rating: 4),
                ],
                events: [
                    .init(isEntry: true, wineName: "Pétrus 2012", position: "C2", wineId: "5", date: Date()),
                ]
            ),
            onStatsTapped: {},
            onWineTapped: { _ in }
        )
    }
}

#Preview("Vide") {
    NavigationStack {
        DashboardPage(
            content: .init(
                stats: .init(bottleCount: 0, totalValue: 0),
                readyToDrink: [],
                favorites: [],
                shortlist: [],
                events: []
            ),
            onStatsTapped: {},
            onWineTapped: { _ in }
        )
    }
}
