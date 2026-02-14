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
                } else {
                    CellarGridComponent(
                        grid: viewModel.grid,
                        onCellTap: { rowIdx, colIdx, cell in
                            if let wine = cell.wine {
                                selectedCell = CellSelection(row: rowIdx, col: colIdx, wine: wine)
                            }
                        }
                    )
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
