import SwiftUI

struct CellarPage: View {
    @Binding var displayMode: CellarDisplayMode
    /// The household's cellars: a picker shows once there are two.
    var cellars: [CellarSummary] = []
    /// The cellar whose bottles are listed; nil for the primary one.
    var selectedCellarId: Binding<String?> = .constant(nil)
    let groups: [CaveBottleList.Group]
    let events: [JournalEventList.Event]
    var bottlesHasMore: Bool = false
    var bottlesLoadMoreFailed: Bool = false
    var historyHasMore: Bool = false
    var historyLoadMoreFailed: Bool = false
    /// Refreshing the cellar on screen failed — a retry row leads it.
    var refreshFailed: Bool = false
    var onBottleTapped: (String) -> Void
    var onRemoveRequested: (String) -> Void
    var onEventTapped: (String) -> Void
    var onRefresh: () async -> Void
    var onBottlesPrefetch: (String) -> Void = { _ in }
    var onBottlesLoadMore: () async -> Void = {}
    var onHistoryPrefetch: (String) -> Void = { _ in }
    var onHistoryLoadMore: () async -> Void = {}
    var onRetryRefresh: () async -> Void = {}
    /// The "+" of a lone cellar, or the last entry of the cellar menu.
    var onAddCellar: () -> Void = {}

    var body: some View {
        Group {
            switch displayMode {
            case .cave:
                CaveBottleList(
                    groups: groups,
                    hasMore: bottlesHasMore,
                    loadMoreFailed: bottlesLoadMoreFailed,
                    refreshFailed: refreshFailed,
                    onBottleTapped: onBottleTapped,
                    onRemoveRequested: onRemoveRequested,
                    onPrefetch: onBottlesPrefetch,
                    onLoadMore: onBottlesLoadMore,
                    onRetryRefresh: onRetryRefresh
                )
            case .journal:
                JournalEventList(
                    events: events,
                    hasMore: historyHasMore,
                    loadMoreFailed: historyLoadMoreFailed,
                    refreshFailed: refreshFailed,
                    onEventTapped: onEventTapped,
                    onPrefetch: onHistoryPrefetch,
                    onLoadMore: onHistoryLoadMore,
                    onRetryRefresh: onRetryRefresh
                )
            }
        }
        .toolbar {
            // A single cellar gets a "+" so a second one is discoverable; from two on
            // the "+" becomes the list of cellars, which still ends on adding one.
            if displayMode == .cave {
                ToolbarItem {
                    if cellars.count > 1 {
                        Menu {
                            Picker("Cave", selection: selectedCellarId) {
                                ForEach(cellars) { cellar in
                                    Text(cellar.displayName)
                                        .tag(cellar.isPrimary ? String?.none : String?.some(cellar.id))
                                }
                            }
                            Divider()
                            Button("Ajouter une cave", systemImage: "plus", action: onAddCellar)
                                .accessibilityIdentifier("cellar-picker-add")
                        } label: {
                            Label("Changer de cave", systemImage: "square.stack.3d.up")
                        }
                        .accessibilityIdentifier("cellar-picker")
                    } else {
                        Button("Ajouter une cave", systemImage: "plus", action: onAddCellar)
                            .labelStyle(.iconOnly)
                            .accessibilityIdentifier("cellar-add")
                    }
                }
                ToolbarSpacer(.fixed)
            }
            ToolbarItemGroup {
                ForEach(CellarDisplayMode.allCases) { mode in
                    Button {
                        displayMode = mode
                    } label: {
                        Label(mode.label, systemImage: mode.icon)
                    }
                    .labelStyle(.iconOnly)
                    .tint(displayMode == mode ? .accentColor : .primary)
                    .accessibilityIdentifier("cellar-mode-\(mode.rawValue)")
                }
            }
            // Detaches the magnifier from the mode toggles into its own capsule.
            // The mode toggles keep the default placement so the magnifier, pinned to
            // the trailing edge, lands last — same order as the wine list.
            ToolbarSpacer(.fixed)
        }
        .searchToolbarButton()
        .navigationTitle(title)
        .navigationSubtitle(displayMode.subtitle)
        .navigationBarTitleDisplayMode(.large)
        .refreshable { await onRefresh() }
    }

    /// With several cellars, the cave reads as the one on screen; the journal spans
    /// them all.
    private var title: String {
        guard displayMode == .cave, cellars.count > 1 else { return displayMode.title }
        let selected = cellars.first { $0.id == selectedCellarId.wrappedValue && !$0.isPrimary }
            ?? cellars.first { $0.isPrimary }
        return selected?.displayName ?? displayMode.title
    }
}

#Preview("Cellar with bottles") {
    @Previewable @State var mode: CellarDisplayMode = .cave
    NavigationStack {
        CellarPage(
            displayMode: $mode,
            groups: [
                .init(label: "A", items: [
                    .init(id: "1", color: .red, title: "Château Margaux", subtitle: "2018", position: "A1"),
                    .init(id: "2", color: .white, title: "Pouilly-Fumé", subtitle: nil, position: "A2"),
                ]),
                .init(label: "B", items: [
                    .init(id: "3", color: .rosé, title: "Côtes de Provence", subtitle: "2022", position: "B1"),
                ]),
            ],
            events: [],
            onBottleTapped: { _ in },
            onRemoveRequested: { _ in },
            onEventTapped: { _ in },
            onRefresh: {}
        )
    }
}

#Preview("Journal") {
    @Previewable @State var mode: CellarDisplayMode = .journal
    NavigationStack {
        CellarPage(
            displayMode: $mode,
            groups: [],
            events: [
                .init(id: "1-in", date: .now, isEntry: true, wineId: "1", title: "Château Margaux 2018", position: "A1"),
                .init(id: "2-out", date: .now.addingTimeInterval(-86400), isEntry: false, wineId: "2", title: "Pouilly-Fumé 2021", position: "B3"),
            ],
            onBottleTapped: { _ in },
            onRemoveRequested: { _ in },
            onEventTapped: { _ in },
            onRefresh: {}
        )
    }
}

#Preview("Empty cellar") {
    @Previewable @State var mode: CellarDisplayMode = .cave
    NavigationStack {
        CellarPage(
            displayMode: $mode,
            groups: [],
            events: [],
            onBottleTapped: { _ in },
            onRemoveRequested: { _ in },
            onEventTapped: { _ in },
            onRefresh: {}
        )
    }
}
