import SwiftUI

struct WineListContent: View {
    let mode: WineListMode
    let groups: [Group]
    var hasMore: Bool = false
    var isLoading: Bool = false
    var onWineTapped: (String) -> Void
    var onPrefetch: (String) -> Void = { _ in }
    var onLoadMore: () async -> Void = {}

    private var isEmpty: Bool { groups.allSatisfy { $0.items.isEmpty } }

    var body: some View {
        if isEmpty && isLoading {
            ProgressView("Chargement...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if isEmpty && !hasMore {
            emptyState
        } else {
            List {
                ForEach(groups) { group in
                    Section {
                        ForEach(group.items) { item in
                            Button {
                                onWineTapped(item.id)
                            } label: {
                                WineListRow(
                                    beverageType: item.beverageType,
                                    color: item.color,
                                    name: item.name,
                                    subtitle: item.subtitle,
                                    rating: item.rating,
                                    isFavorite: item.isFavorite
                                )
                            }
                            .tint(.primary)
                            .onAppear { onPrefetch(item.id) }
                        }
                    } header: {
                        Text(group.label)
                    }
                }

                if hasMore {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                    .task { await onLoadMore() }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        switch mode {
        case .favorites:
            ContentUnavailableView("Aucun favori", systemImage: "heart", description: Text("Ajoutez vos coups de c\u{0153}ur en favoris"))
                .frame(maxHeight: .infinity)
        case .gifted:
            ContentUnavailableView("Aucun vin offert", systemImage: "gift", description: Text("Les vins offerts appara\u{00EE}tront ici"))
                .frame(maxHeight: .infinity)
        case .recommended:
            ContentUnavailableView("Aucun vin conseillé", systemImage: "person.2.badge", description: Text("Les vins conseillés par vos amis apparaîtront ici"))
                .frame(maxHeight: .infinity)
        case .all:
            ContentUnavailableView("Aucun vin", systemImage: "wineglass", description: Text("Aucun vin ne correspond \u{00E0} ce filtre"))
                .frame(maxHeight: .infinity)
        }
    }
}

extension WineListContent {
    struct Group: Identifiable {
        let label: String
        let items: [Item]
        var id: String { label }
    }

    struct Item: Identifiable {
        let id: String
        var beverageType: BeverageType = .wine
        let color: WineColor?
        let name: String
        let subtitle: String?
        let rating: Int?
        let isFavorite: Bool
    }
}

#Preview("Avec vins") {
    WineListContent(
        mode: .all,
        groups: [
            .init(label: "2018", items: [
                .init(id: "1", color: .red, name: "Château La Sauvageonne Cuvée Les Oliviers", subtitle: "2018 \u{2022} Bordeaux", rating: 4, isFavorite: true),
                .init(id: "3", color: .red, name: "Chauteau Poupchette", subtitle: "2018 \u{2022} Poupchaux", rating: 4, isFavorite: false),
            ]),
            .init(label: "2021", items: [
                .init(id: "2", color: .white, name: "Pouilly-Fum\u{00E9}", subtitle: "2021", rating: 5, isFavorite: true),
            ]),
        ],
        onWineTapped: { _ in }
    )
}

#Preview("Vide - All") {
    WineListContent(
        mode: .all,
        groups: [],
        onWineTapped: { _ in }
    )
}

#Preview("Vide - Favoris") {
    WineListContent(
        mode: .favorites,
        groups: [],
        onWineTapped: { _ in }
    )
}

#Preview("Vide - Offerts") {
    WineListContent(
        mode: .gifted,
        groups: [],
        onWineTapped: { _ in }
    )
}

#Preview("Vide - Recommended") {
    WineListContent(
        mode: .recommended,
        groups: [],
        onWineTapped: { _ in }
    )
}
