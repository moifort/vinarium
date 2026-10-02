import SwiftUI

struct WineListContent: View {
    let mode: WineListMode
    let groups: [Group]
    var hasMore: Bool = false
    var isLoading: Bool = false
    var loadMoreFailed: Bool = false
    /// The first page failed: with nothing from last time, the list stays blank.
    var loadFailed: Bool = false
    var onWineTapped: (String) -> Void
    var onPrefetch: (String) -> Void = { _ in }
    var onLoadMore: () async -> Void = {}

    private var isEmpty: Bool { groups.allSatisfy { $0.items.isEmpty } }

    var body: some View {
        if isEmpty && isLoading {
            LoadingStateView()
        } else if isEmpty && loadFailed {
            // A network failure must not disguise itself as an empty list: nothing
            // shows, and a pull tries again.
            PullToRefreshSpace()
        } else if isEmpty && !hasMore {
            PullToRefreshSpace { emptyState }
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
                                    domain: item.domain,
                                    name: item.name,
                                    subtitle: item.subtitle,
                                    rating: item.rating,
                                    isFavorite: item.isFavorite,
                                    isInCellar: item.isInCellar,
                                    ownerName: item.ownerName
                                )
                            }
                            .tint(.primary)
                            .onAppear { onPrefetch(item.id) }
                        }
                    } header: {
                        Text(group.label)
                    }
                }

                if hasMore && !loadMoreFailed {
                    LoadMoreRow(
                        loadingLabel: "Chargement de plus de vins",
                        onLoadMore: onLoadMore
                    )
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
        case .gifted:
            ContentUnavailableView("Aucun vin offert", systemImage: "gift", description: Text("Les vins qu'on vous a offerts appara\u{00EE}tront ici"))
        case .recommended:
            ContentUnavailableView("Aucun vin conseillé", systemImage: "person.2.badge", description: Text("Les vins conseillés par vos amis apparaîtront ici"))
        case .all:
            ContentUnavailableView("Aucun vin", systemImage: "wineglass", description: Text("Aucun vin ne correspond \u{00E0} ce filtre"))
        }
    }
}

extension WineListContent {
    struct Group: Identifiable, Equatable {
        let label: String
        let items: [Item]
        var id: String { label }
    }

    struct Item: Identifiable, Equatable {
        let id: String
        var beverageType: BeverageType = .wine
        let color: WineColor?
        var domain: String? = nil
        let name: String
        let subtitle: String?
        let rating: Int?
        let isFavorite: Bool
        var isInCellar: Bool = false
        /// The household member this wine belongs to; nil for the viewer's own.
        var ownerName: String? = nil
    }
}

#Preview("With wines") {
    WineListContent(
        mode: .all,
        groups: [
            .init(label: "2018", items: [
                .init(id: "1", color: .red, name: "Château La Sauvageonne Cuvée Les Oliviers", subtitle: "2018 \u{2022} Bordeaux", rating: 4, isFavorite: true, isInCellar: true),
                .init(id: "3", color: .red, name: "Chauteau Poupchette", subtitle: "2018 \u{2022} Poupchaux", rating: 4, isFavorite: false),
            ]),
            .init(label: "2021", items: [
                .init(id: "2", color: .white, domain: "Didier Dagueneau", name: "Pouilly-Fum\u{00E9}", subtitle: "2021", rating: 5, isFavorite: true),
                .init(id: "4", color: .red, name: "Pauillac Grand Cru", subtitle: "2021 \u{2022} Bordeaux", rating: 4, isFavorite: false, isInCellar: true, ownerName: "Marie"),
            ]),
        ],
        onWineTapped: { _ in }
    )
}

#Preview("Load failed") {
    WineListContent(
        mode: .all,
        groups: [],
        loadFailed: true,
        onWineTapped: { _ in }
    )
}

#Preview("Empty - all") {
    WineListContent(
        mode: .all,
        groups: [],
        onWineTapped: { _ in }
    )
}

#Preview("Empty - favorites") {
    WineListContent(
        mode: .favorites,
        groups: [],
        onWineTapped: { _ in }
    )
}

#Preview("Empty - gifted") {
    WineListContent(
        mode: .gifted,
        groups: [],
        onWineTapped: { _ in }
    )
}

#Preview("Empty - recommended") {
    WineListContent(
        mode: .recommended,
        groups: [],
        onWineTapped: { _ in }
    )
}
