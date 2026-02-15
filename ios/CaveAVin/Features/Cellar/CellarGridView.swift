import SwiftUI

struct CellarGridView: View {
    @State private var viewModel = CellarGridViewModel()
    @State private var selectedCell: CellSelection?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.grid.isEmpty {
                    ProgressView("Chargement...")
                } else if let error = viewModel.error, viewModel.grid.isEmpty {
                    ContentUnavailableView("Erreur", systemImage: "exclamationmark.triangle", description: Text(error))
                } else if viewModel.groupedRows.isEmpty {
                    ContentUnavailableView("Cave vide", systemImage: "wineglass", description: Text("Ajoutez des bouteilles via le scanner"))
                } else {
                    List {
                        ForEach(viewModel.groupedRows) { group in
                            Section {
                                ForEach(group.items) { item in
                                    Button {
                                        selectedCell = CellSelection(row: item.rowIndex, col: item.colIndex, wine: item.wine)
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
                                            selectedCell = CellSelection(row: item.rowIndex, col: item.colIndex, wine: item.wine)
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
            .navigationTitle("Ma Cave")
            .refreshable {
                await viewModel.load()
            }
            .task {
                await viewModel.load()
            }
            .sheet(item: $selectedCell) { selection in
                CellDetailSheet(wine: selection.wine, row: selection.row, col: selection.col) {
                    selectedCell = nil
                    Task { await viewModel.load() }
                }
            }
        }
    }
}

private struct CellSelection: Identifiable {
    let row: Int
    let col: Int
    let wine: Wine
    var id: String { wine.id }
}
