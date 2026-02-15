import Foundation

enum CellarDisplayMode: String, CaseIterable {
    case cave = "Cave"
    case journal = "Journal"
}

@MainActor @Observable
final class CellarGridViewModel {
    var grid: [[GridCell]] = []
    var history: [HistoryEvent] = []
    var displayMode: CellarDisplayMode = .cave
    var isLoading = false
    var error: String?

    var groupedRows: [CellarRowGroup] {
        grid.enumerated().compactMap { rowIdx, cells in
            let rowLetter = String(UnicodeScalar(65 + rowIdx)!)
            let occupiedCells = cells.enumerated().compactMap { colIdx, cell -> CellarRowItem? in
                guard let wine = cell.wine else { return nil }
                return CellarRowItem(
                    position: "\(rowLetter)\(colIdx + 1)",
                    wine: wine,
                    rowIndex: rowIdx,
                    colIndex: colIdx
                )
            }
            guard !occupiedCells.isEmpty else { return nil }
            return CellarRowGroup(row: rowLetter, items: occupiedCells)
        }
    }

    func load() async {
        isLoading = true
        error = nil
        do {
            async let gridData = CellarAPI.getGrid()
            async let historyData = CellarAPI.getHistory()
            let (g, h) = try await (gridData, historyData)
            grid = g
            history = h
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
