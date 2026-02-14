import SwiftUI

struct CellarGridView: View {
    @State private var viewModel = CellarGridViewModel()
    @State private var selectedWine: Wine?

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
                        onCellTap: { _, _, cell in
                            if let wine = cell.wine {
                                selectedWine = wine
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
        }
    }
}
