import SwiftUI

struct WineListContent: View {
    let mode: WineListMode
    let isLoading: Bool
    let groups: [Group]
    var onWineTapped: (String) -> Void

    var body: some View {
        if isLoading {
            ProgressView()
                .frame(maxHeight: .infinity)
        } else if groups.allSatisfy({ $0.items.isEmpty }) {
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
                                    color: item.color,
                                    name: item.name,
                                    subtitle: item.subtitle,
                                    rating: item.rating,
                                    isFavorite: item.isFavorite
                                )
                            }
                            .tint(.primary)
                        }
                    } header: {
                        Text(group.label)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        switch mode {
        case .favorites:
            ContentUnavailableView("Aucun favori", systemImage: "heart", description: Text("Ajoutez vos vins pr\u{00E9}f\u{00E9}r\u{00E9}s en favoris"))
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
        let color: WineColor
        let name: String
        let subtitle: String?
        let rating: Int?
        let isFavorite: Bool
    }
}

#Preview("Avec vins") {
    WineListContent(
        mode: .all,

        isLoading: false,
        groups: [
            .init(label: "2018", items: [
                .init(id: "1", color: .red, name: "Ch\u{00E2}teau Margaux", subtitle: "2018 \u{2022} Bordeaux", rating: 4, isFavorite: false),
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

        isLoading: false,
        groups: [],
        onWineTapped: { _ in }
    )
}

#Preview("Vide - Favoris") {
    WineListContent(
        mode: .favorites,

        isLoading: false,
        groups: [],
        onWineTapped: { _ in }
    )
}

#Preview("Vide - Offerts") {
    WineListContent(
        mode: .gifted,

        isLoading: false,
        groups: [],
        onWineTapped: { _ in }
    )
}

#Preview("Vide - Recommended") {
    WineListContent(
        mode: .recommended,

        isLoading: false,
        groups: [],
        onWineTapped: { _ in }
    )
}
