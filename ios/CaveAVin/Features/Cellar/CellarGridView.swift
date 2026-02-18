import SwiftUI

struct CellarGridView: View {
    var refreshTrigger: UUID = UUID()

    @State private var viewModel = CellarGridViewModel()
    @State private var selectedWineId: String?

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
                                            Text("\(vintage)")
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
                                Button(role: .destructive) {
                                    selectedWineId = item.wine.id
                                } label: {
                                    Label("Retirer", systemImage: "minus.circle")
                                }
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

private struct WineIdWrapper: Identifiable {
    let id: String
}
