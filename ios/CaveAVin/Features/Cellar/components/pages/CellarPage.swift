import Sentry
import SentrySwiftUI
import SwiftUI

struct CellarPage: View {
    var refreshTrigger: UUID = UUID()

    @State private var viewModel = CellarGridViewModel()
    @State private var selectedWineId: String?
    @State private var wineForRemovalChoice: CellarRowItem?
    @State private var wineForConsumption: CellarRowItem?
    @State private var wineForGift: CellarRowItem?

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
                                            id: item.id,
                                            color: item.color,
                                            title: item.name,
                                            subtitle: item.vintage.map { "\($0)" },
                                            position: item.position
                                        )
                                    }
                                )
                            },
                            onBottleTapped: { wineId in selectedWineId = wineId },
                            onRemoveRequested: { wineId in
                                wineForRemovalChoice = viewModel.groupedRows
                                    .flatMap(\.items)
                                    .first { $0.id == wineId }
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
            .navigationTitle(viewModel.displayMode.title)
            .navigationSubtitle(viewModel.displayMode.subtitle)
            .navigationBarTitleDisplayMode(.large)
            .sentryTrace("Cellar", waitForFullDisplay: true)
            .refreshable {
                await viewModel.load()
            }
            .task(id: refreshTrigger) {
                await viewModel.load()
                SentrySDK.reportFullyDisplayed()
            }
            .sheet(item: Binding(
                get: { selectedWineId.map { WineIdWrapper(id: $0) } },
                set: { selectedWineId = $0?.id }
            )) { wrapper in
                WineDetailSheet(
                    wineId: wrapper.id,
                    onRemoved: { Task { await viewModel.load() } },
                    onUpdated: { Task { await viewModel.load() } }
                )
            }
            .sheet(item: $wineForConsumption, onDismiss: {
                Task { await viewModel.load() }
            }) { item in
                ConsumptionSheet { date, rating, notes, contacts in
                    let formatter = ISO8601DateFormatter()
                    Task {
                        _ = try? await CellarAPI.remove(
                            wineId: item.id,
                            consumedDate: formatter.string(from: date),
                            rating: rating,
                            tastingNotes: notes,
                            contacts: contacts.isEmpty ? nil : contacts
                        )
                        wineForConsumption = nil
                    }
                }
            }
            .sheet(item: $wineForGift, onDismiss: {
                Task { await viewModel.load() }
            }) { item in
                GiftSheet { date, recipientName in
                    let formatter = ISO8601DateFormatter()
                    Task {
                        _ = try? await CellarAPI.gift(
                            wineId: item.id,
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

#Preview {
    CellarPage()
}
