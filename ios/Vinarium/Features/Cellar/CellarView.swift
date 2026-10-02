import SwiftUI

struct CellarView: View {
    var refreshTrigger: UUID = UUID()

    @Environment(SubscriptionStore.self) private var subscriptions
    @State private var viewModel = CellarGridViewModel()
    @State private var cellarCreationShown = false
    @State private var premiumShown = false
    @State private var selectedWineId: String?
    @State private var wineForConsumption: CellarRowItem?
    @State private var wineForGift: CellarRowItem?
    @State private var wineForRemovalChoice: CellarRowItem?
    @State private var sheetError = ErrorPresenter()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.bottles.isEmpty {
                    LoadingStateView()
                } else if viewModel.error != nil, viewModel.bottles.isEmpty {
                    // Nothing from last time and the load failed: nothing shows, and a
                    // pull tries again.
                    PullToRefreshSpace()
                        .refreshable { await viewModel.load() }
                } else {
                    CellarPage(
                        displayMode: $viewModel.displayMode,
                        cellars: viewModel.cellars,
                        selectedCellarId: $viewModel.selectedCellarId,
                        groups: mappedGroups,
                        events: mappedEvents,
                        bottlesHasMore: viewModel.bottlesHasMore,
                        bottlesLoadMoreFailed: viewModel.bottlesLoadMoreFailed,
                        historyHasMore: viewModel.historyHasMore,
                        historyLoadMoreFailed: viewModel.historyLoadMoreFailed,
                        onBottleTapped: { selectedWineId = $0 },
                        onRemoveRequested: { wineId in
                            wineForRemovalChoice = viewModel.groupedRows
                                .flatMap(\.items)
                                .first { $0.id == wineId }
                        },
                        onEventTapped: { selectedWineId = $0 },
                        onRefresh: { await viewModel.load() },
                        onBottlesPrefetch: { viewModel.prefetchBottlesIfNeeded(for: $0) },
                        onBottlesLoadMore: { await viewModel.loadMoreBottles() },
                        onHistoryPrefetch: { viewModel.prefetchHistoryIfNeeded(for: $0) },
                        onHistoryLoadMore: { await viewModel.loadMoreHistory() },
                        onAddCellar: {
                            // A second cellar is Premium: the others meet the offer.
                            if subscriptions.isPremium == true {
                                cellarCreationShown = true
                            } else {
                                premiumShown = true
                            }
                        }
                    )
                }
            }
            // Over last session's snapshot when the disk had one: the bottles show at
            // once and move into place when the server answers.
            .task(id: refreshTrigger) {
                await viewModel.load()
            }
            .sheet(isPresented: $cellarCreationShown) {
                NewCellarView(
                    // Opens on the new cellar; switching reloads the list of cellars.
                    onCreated: { viewModel.selectedCellarId = $0.id },
                    onPremiumRequired: {
                        cellarCreationShown = false
                        premiumShown = true
                    }
                )
            }
            .sheet(isPresented: $premiumShown) {
                PremiumSheet(trigger: .moreCellars)
            }
            // Choice raised by the "take out" swipe: drink it or give it away.
            .confirmationDialog(
                "Sortir de la cave",
                isPresented: Binding(
                    get: { wineForRemovalChoice != nil },
                    set: { if !$0 { wineForRemovalChoice = nil } }
                ),
                titleVisibility: .visible,
                presenting: wineForRemovalChoice
            ) { item in
                Button("Consommer") { wineForConsumption = item }
                    .accessibilityIdentifier("choice-consume")
                Button("Offrir") { wineForGift = item }
                    .accessibilityIdentifier("choice-gift")
            } message: { item in
                Text(item.name)
            }
            .sheet(item: Binding(
                get: { selectedWineId.map { WineIdWrapper(id: $0) } },
                set: { selectedWineId = $0?.id }
            )) { wrapper in
                WineDetailView(
                    wineId: wrapper.id,
                    onRemoved: { Task { await viewModel.load() } },
                    onUpdated: { Task { await viewModel.load() } }
                )
            }
            // Reload only after a successful mutation: cancelling a sheet must not
            // trigger a full refetch of the cellar.
            .sheet(item: $wineForConsumption) { item in
                ConsumptionSheet { date, rating, notes, contacts in
                    let formatter = ISO8601DateFormatter()
                    await sheetError.run {
                        _ = try await CellarAPI.remove(
                            wineId: item.id,
                            consumedDate: formatter.string(from: date),
                            rating: rating,
                            tastingNotes: notes,
                            contacts: contacts.isEmpty ? nil : contacts
                        )
                    } onSuccess: {
                        wineForConsumption = nil
                        Task { await viewModel.load() }
                    }
                }
                .errorAlert(sheetError)
            }
            .sheet(item: $wineForGift) { item in
                GiftSheet { date, recipientName in
                    let formatter = ISO8601DateFormatter()
                    await sheetError.run {
                        _ = try await CellarAPI.gift(
                            wineId: item.id,
                            giftedDate: formatter.string(from: date),
                            recipientName: recipientName
                        )
                    } onSuccess: {
                        wineForGift = nil
                        Task { await viewModel.load() }
                    }
                }
                .errorAlert(sheetError)
            }
        }
    }

    private var mappedGroups: [CaveBottleList.Group] {
        viewModel.groupedRows.map { group in
            .init(
                label: group.row,
                items: group.items.map { item in
                    .init(
                        id: item.id,
                        beverageType: item.beverageType,
                        color: item.color,
                        title: item.name,
                        subtitle: item.vintage.map { "\($0)" },
                        position: item.position,
                        ownerName: item.ownerName,
                        producer: item.producer
                    )
                }
            )
        }
    }

    private var mappedEvents: [JournalEventList.Event] {
        viewModel.history.map { event in
            .init(
                id: event.id,
                date: event.date,
                isEntry: event.type == .entry,
                wineId: event.wineId,
                title: event.wineName,
                position: event.position,
                memberName: event.memberName,
                producer: ProducerOverline.text(for: event.producer, name: event.wineName)
            )
        }
    }
}

#Preview {
    CellarView()
        .environment(SubscriptionStore())
}
