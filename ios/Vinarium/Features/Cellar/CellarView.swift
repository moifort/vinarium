import Sentry
import SentrySwiftUI
import SwiftUI

struct CellarView: View {
    var refreshTrigger: UUID = UUID()

    @State private var viewModel = CellarGridViewModel()
    @State private var selectedWineId: String?
    @State private var wineForConsumption: CellarRowItem?
    @State private var wineForGift: CellarRowItem?
    @State private var wineForRemovalChoice: CellarRowItem?
    @State private var sheetError = ErrorPresenter()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.bottles.isEmpty {
                    ProgressView("Chargement...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.error, viewModel.bottles.isEmpty {
                    ContentUnavailableView("Erreur", systemImage: "exclamationmark.triangle", description: Text(error))
                } else {
                    CellarPage(
                        displayMode: $viewModel.displayMode,
                        groups: mappedGroups,
                        events: mappedEvents,
                        historyHasMore: viewModel.historyHasMore,
                        onBottleTapped: { selectedWineId = $0 },
                        onRemoveRequested: { wineId in
                            wineForRemovalChoice = viewModel.groupedRows
                                .flatMap(\.items)
                                .first { $0.id == wineId }
                        },
                        onEventTapped: { selectedWineId = $0 },
                        onRefresh: { await viewModel.load() },
                        onHistoryPrefetch: { viewModel.prefetchHistoryIfNeeded(for: $0) },
                        onHistoryLoadMore: { await viewModel.loadMoreHistory() }
                    )
                }
            }
            .sentryTrace("Cellar", waitForFullDisplay: true)
            .task(id: refreshTrigger) {
                await viewModel.load()
                SentrySDK.reportFullyDisplayed()
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
            .sheet(item: $wineForConsumption, onDismiss: {
                Task { await viewModel.load() }
            }) { item in
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
                    }
                }
                .errorAlert(sheetError)
            }
            .sheet(item: $wineForGift, onDismiss: {
                Task { await viewModel.load() }
            }) { item in
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
                        position: item.position
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
                position: event.position
            )
        }
    }
}

#Preview {
    CellarView()
}
