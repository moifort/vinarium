import SwiftUI

struct WineListPage: View {
    @Binding var mode: WineListMode
    @Binding var sort: WineSort
    @Binding var sortDescending: Bool
    @Binding var statusFilter: WineStatusFilter
    let isLoading: Bool
    let groups: [WineListContent.Group]
    var onWineTapped: (String) -> Void
    var onRefresh: () async -> Void

    var body: some View {
        WineListContent(
            mode: mode,
            isLoading: isLoading,
            groups: groups,
            onWineTapped: onWineTapped
        )
        .navigationTitle(mode.title)
        .navigationSubtitle(mode.subtitle)
        .navigationBarTitleDisplayMode(.large)
        .refreshable { await onRefresh() }
        .toolbar {
            ToolbarItemGroup {
                ForEach(WineListMode.allCases) { item in
                    Button {
                        mode = item
                    } label: {
                        Label(item.label, systemImage: item.icon)
                    }
                    .tint(mode == item ? .accentColor : .primary)
                    .accessibilityIdentifier("winelist-mode-\(item.rawValue)")
                }
            }
            ToolbarSpacer(.fixed)
            ToolbarItemGroup {
                Menu {
                    Picker("Tri", selection: $sort) {
                        ForEach(WineSort.allCases) { sort in
                            Label(sort.label, systemImage: sort.icon).tag(sort)
                        }
                    }
                    Toggle(sortDescending ? "Décroissant" : "Croissant", isOn: $sortDescending)

                    Divider()

                    Picker("Statut", selection: $statusFilter) {
                        ForEach(WineStatusFilter.allCases) { filter in
                            Label(filter.label, systemImage: filter.icon).tag(filter)
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                }
                .accessibilityIdentifier("winelist-sort-menu")
            }
        }
    }
}

#Preview("Avec vins") {
    @Previewable @State var mode: WineListMode = .all
    @Previewable @State var sort: WineSort = .updatedAt
    @Previewable @State var sortDesc = true
    @Previewable @State var filter: WineStatusFilter = .all
    NavigationStack {
        WineListPage(
            mode: $mode,
            sort: $sort,
            sortDescending: $sortDesc,
            statusFilter: $filter,
            isLoading: false,
            groups: [
                .init(label: "Mars 2026", items: [
                    .init(id: "1", color: .red, name: "Château Margaux", subtitle: "2018 • Bordeaux", rating: 5, isFavorite: true, isShortlist: false),
                    .init(id: "2", color: .white, name: "Pouilly-Fumé", subtitle: "2021 • Loire", rating: 4, isFavorite: false, isShortlist: false),
                ]),
            ],
            onWineTapped: { _ in },
            onRefresh: {}
        )
    }
}

#Preview("Vide") {
    @Previewable @State var mode: WineListMode = .favorites
    @Previewable @State var sort: WineSort = .updatedAt
    @Previewable @State var sortDesc = true
    @Previewable @State var filter: WineStatusFilter = .all
    NavigationStack {
        WineListPage(
            mode: $mode,
            sort: $sort,
            sortDescending: $sortDesc,
            statusFilter: $filter,
            isLoading: false,
            groups: [],
            onWineTapped: { _ in },
            onRefresh: {}
        )
    }
}
