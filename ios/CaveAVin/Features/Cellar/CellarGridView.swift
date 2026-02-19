import SwiftUI

struct CellarGridView: View {
    var refreshTrigger: UUID = UUID()

    @State private var viewModel = CellarGridViewModel()
    @State private var selectedWineId: String?
    @State private var wineForRemovalChoice: Wine?
    @State private var wineForConsumption: Wine?
    @State private var wineForGift: Wine?
    @State private var pendingRemoval: PendingRemoval?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Vue", selection: $viewModel.displayMode) {
                    ForEach(CellarDisplayMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .accessibilityIdentifier("cellar-segment")

                Group {
                    if viewModel.isLoading && viewModel.bottles.isEmpty {
                        ProgressView("Chargement...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = viewModel.error, viewModel.bottles.isEmpty {
                        ContentUnavailableView("Erreur", systemImage: "exclamationmark.triangle", description: Text(error))
                    } else {
                        switch viewModel.displayMode {
                        case .cave:
                            caveListContent
                        case .journal:
                            CellarJournalView(events: viewModel.history) { wineId in
                                selectedWineId = wineId
                            }
                        }
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
                ConsumptionSheet(wine: wine) { date, rating, notes in
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
                GiftSheet(wine: wine) { date, recipientName in
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

    @ViewBuilder
    private var caveListContent: some View {
        if viewModel.groupedRows.isEmpty {
            VStack(spacing: 16) {
                Spacer()
                Image("empty-no-cellar")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 240)
                    .clipShape(.rect(cornerRadius: 16))
                    .opacity(0.85)
                    .accessibilityHidden(true)
                Text("Cave vide")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Ajoutez des bouteilles via le scanner")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else {
            List {
                ForEach(viewModel.groupedRows) { group in
                    Section {
                        ForEach(group.items) { item in
                            Button {
                                selectedWineId = item.wine.id
                            } label: {
                                HStack {
                                    WineColorBadge(color: item.wine.color)
                                    VStack(alignment: .leading) {
                                        Text(item.wine.name)
                                            .font(.headline)
                                        if let vintage = item.wine.vintage {
                                            Text(verbatim: "\(vintage)")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Text(item.position)
                                        .font(.subheadline.monospaced())
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(.systemGray5))
                                        .clipShape(.rect(cornerRadius: 6))
                                }
                            }
                            .tint(.primary)
                            .swipeActions(edge: .trailing) {
                                Button {
                                    wineForRemovalChoice = item.wine
                                } label: {
                                    Label("Sortir", systemImage: "arrow.up.circle")
                                }
                                .tint(.red)
                            }
                        }
                    } header: {
                        Label("Rangée \(group.row)", systemImage: "cabinet")
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

private struct WineIdWrapper: Identifiable {
    let id: String
}

#Preview {
    CellarGridView()
}
