import SwiftUI

struct CaveBottleList: View {
    let groups: [Group]
    var onBottleTapped: (String) -> Void
    var onRemoveRequested: (String) -> Void

    var body: some View {
        if groups.isEmpty {
            ContentUnavailableView("Cave vide", systemImage: "cabinet.fill", description: Text("Ajoutez des bouteilles via le scanner"))
        } else {
            List {
                ForEach(groups) { group in
                    Section {
                        ForEach(group.items) { item in
                            Button {
                                onBottleTapped(item.id)
                            } label: {
                                BottleRow(color: item.color, position: item.position) {
                                    Text(item.title)
                                } subtitle: {
                                    if let subtitle = item.subtitle {
                                        Text(subtitle)
                                    }
                                }
                            }
                            .tint(.primary)
                            .swipeActions(edge: .trailing) {
                                Button {
                                    onRemoveRequested(item.id)
                                } label: {
                                    Label("Sortir", systemImage: "arrow.up.circle")
                                }
                                .tint(.red)
                            }
                        }
                    } header: {
                        Label("Rangée \(group.label)", systemImage: "cabinet")
                    }
                }
            }
        }
    }
}

extension CaveBottleList {
    struct Group: Identifiable {
        let label: String
        let items: [Item]
        var id: String { label }
    }

    struct Item: Identifiable {
        let id: String
        let color: WineColor
        let title: String
        let subtitle: String?
        let position: String
    }
}

#Preview("Avec bouteilles") {
    CaveBottleList(
        groups: [
            .init(label: "A", items: [
                .init(id: "1", color: .red, title: "Chateau Margaux", subtitle: "2018", position: "A1"),
                .init(id: "2", color: .white, title: "Pouilly-Fume", subtitle: nil, position: "A2"),
            ]),
            .init(label: "B", items: [
                .init(id: "3", color: .rosé, title: "Cotes de Provence", subtitle: "2022", position: "B1"),
            ]),
        ],
        onBottleTapped: { _ in },
        onRemoveRequested: { _ in }
    )
}

#Preview("Vide") {
    CaveBottleList(
        groups: [],
        onBottleTapped: { _ in },
        onRemoveRequested: { _ in }
    )
}
