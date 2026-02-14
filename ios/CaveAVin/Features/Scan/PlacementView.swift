import SwiftUI

struct PlacementView: View {
    let wine: Wine
    let onPlaced: (String) -> Void

    @State private var grid: [[GridCell]] = []
    @State private var suggestedRow: String?
    @State private var suggestedCol: Int?
    @State private var selectedRow: String?
    @State private var selectedCol: Int?
    @State private var isLoading = true
    @State private var error: String?
    @State private var isPlacing = false

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Chargement de la cave...")
            } else if let error {
                ContentUnavailableView("Erreur", systemImage: "exclamationmark.triangle", description: Text(error))
            } else {
                VStack(spacing: 16) {
                    Text("Où placer \(wine.name) ?")
                        .font(.headline)

                    if let row = suggestedRow, let col = suggestedCol {
                        Text("Position suggérée : \(row)\(col)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    CellarGridComponent(
                        grid: grid,
                        highlightedRow: selectedRow ?? suggestedRow,
                        highlightedCol: selectedCol ?? suggestedCol,
                        onCellTap: { rowIdx, colIdx, cell in
                            if cell.wine == nil {
                                selectedRow = String(UnicodeScalar(65 + rowIdx)!)
                                selectedCol = colIdx + 1
                            }
                        }
                    )

                    Button {
                        placeWine()
                    } label: {
                        if isPlacing {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            let row = selectedRow ?? suggestedRow ?? "?"
                            let col = selectedCol ?? suggestedCol ?? 0
                            Text("Placer en \(row)\(col)")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isPlacing || (selectedRow == nil && suggestedRow == nil))
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Placement")
        .task {
            await loadData()
        }
    }

    private func loadData() async {
        do {
            async let gridData = CellarAPI.getGrid()
            async let suggestion = CellarAPI.suggest(wineId: wine.id)
            let (g, s) = try await (gridData, suggestion)
            grid = g
            suggestedRow = s.row
            suggestedCol = s.col
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    private func placeWine() {
        let row = selectedRow ?? suggestedRow ?? ""
        let col = selectedCol ?? suggestedCol ?? 0
        isPlacing = true

        Task {
            do {
                _ = try await CellarAPI.place(wineId: wine.id, row: row, col: col)
                onPlaced("\(row)\(col)")
            } catch {
                self.error = error.localizedDescription
            }
            isPlacing = false
        }
    }
}
