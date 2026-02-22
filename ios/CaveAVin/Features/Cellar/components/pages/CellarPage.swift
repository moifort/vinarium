import SwiftUI

struct CellarPage: View {
    var refreshTrigger: UUID = UUID()

    @State private var viewModel = CellarGridViewModel()
    @State private var selectedWineId: String?
    @State private var wineForRemovalChoice: Wine?
    @State private var wineForConsumption: Wine?
    @State private var wineForGift: Wine?
    @State private var pendingRemoval: PendingRemoval?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.bottles.isEmpty {
                    ProgressView("Chargement...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.error, viewModel.bottles.isEmpty {
                    ContentUnavailableView("Erreur", systemImage: "exclamationmark.triangle", description: Text(error))
                } else {
                    switch viewModel.displayMode {
                    case .cave:
                        CaveBottleList(
                            groups: viewModel.groupedRows.map { group in
                                .init(
                                    label: group.row,
                                    items: group.items.map { item in
                                        .init(
                                            id: item.wine.id,
                                            color: item.wine.color,
                                            title: item.wine.name,
                                            subtitle: item.wine.vintage.map { "\($0)" },
                                            position: item.position
                                        )
                                    }
                                )
                            },
                            onBottleTapped: { wineId in selectedWineId = wineId },
                            onRemoveRequested: { wineId in
                                wineForRemovalChoice = viewModel.groupedRows
                                    .flatMap(\.items)
                                    .first { $0.wine.id == wineId }?.wine
                            }
                        )
                    case .journal:
                        JournalEventList(
                            events: viewModel.history.map { event in
                                .init(
                                    id: event.id,
                                    date: event.date,
                                    isEntry: event.type == .entry,
                                    wineId: event.wineId,
                                    title: event.wineName,
                                    position: event.position
                                )
                            },
                            onEventTapped: { wineId in selectedWineId = wineId }
                        )
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup {
                    ForEach(CellarDisplayMode.allCases) { mode in
                        Button {
                            viewModel.displayMode = mode
                        } label: {
                            Label(mode.label, systemImage: mode.icon)
                        }
                        .tint(viewModel.displayMode == mode ? .accentColor : .primary)
                        .accessibilityIdentifier("cellar-mode-\(mode.rawValue)")
                    }
                }
            }
            .navigationTitle("Ma Cave")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.load()
            }
            .task(id: refreshTrigger) {
                await viewModel.load()
            }
            .sheet(item: Binding(
                get: { selectedWineId.map { WineIdWrapper(id: $0) } },
                set: { selectedWineId = $0?.id }
            )) { wrapper in
                WineDetailSheet(wineId: wrapper.id) {
                    Task { await viewModel.load() }
                }
            }
            .sheet(item: $wineForRemovalChoice, onDismiss: {
                switch pendingRemoval {
                case .consumption(let wine):
                    pendingRemoval = nil
                    wineForConsumption = wine
                case .gift(let wine):
                    pendingRemoval = nil
                    wineForGift = wine
                case nil:
                    break
                }
            }) { wine in
                RemovalChoiceSheet(
                    onConsume: {
                        pendingRemoval = .consumption(wine)
                        wineForRemovalChoice = nil
                    },
                    onGift: {
                        pendingRemoval = .gift(wine)
                        wineForRemovalChoice = nil
                    }
                )
                .presentationDetents([.height(260)])
            }
            .sheet(item: $wineForConsumption, onDismiss: {
                Task { await viewModel.load() }
            }) { wine in
                ConsumptionSheet { date, rating, notes in
                    let formatter = ISO8601DateFormatter()
                    Task {
                        _ = try? await CellarAPI.remove(
                            wineId: wine.id,
                            consumedDate: formatter.string(from: date),
                            rating: rating,
                            tastingNotes: notes
                        )
                        wineForConsumption = nil
                    }
                }
            }
            .sheet(item: $wineForGift, onDismiss: {
                Task { await viewModel.load() }
            }) { wine in
                GiftSheet { date, recipientName in
                    let formatter = ISO8601DateFormatter()
                    Task {
                        _ = try? await CellarAPI.gift(
                            wineId: wine.id,
                            giftedDate: formatter.string(from: date),
                            recipientName: recipientName
                        )
                        wineForGift = nil
                    }
                }
            }
        }
    }
}

private enum PendingRemoval {
    case consumption(Wine)
    case gift(Wine)
}

#Preview {
    CellarPage()
}
