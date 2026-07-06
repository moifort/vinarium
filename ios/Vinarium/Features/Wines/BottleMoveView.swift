import SwiftUI

struct BottleMoveView: View {
    let wineId: String
    let wineName: String
    var wineBeverageType: BeverageType = .wine
    let wineColor: WineColor?
    let wineVintage: Int?
    let currentRow: String
    let currentCol: Int
    var onCancel: () -> Void = {}
    let onMoved: () -> Void

    @State private var bottles: [CellarBottle] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var isMoving = false

    private var currentPosition: String { "\(currentRow)\(currentCol)" }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Chargement de la cave...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error {
                    ContentUnavailableView("Erreur", systemImage: "exclamationmark.triangle", description: Text(error))
                } else {
                    BottleMovePage(
                        wineName: wineName,
                        wineBeverageType: wineBeverageType,
                        wineColor: wineColor,
                        wineVintage: wineVintage,
                        currentPosition: currentPosition,
                        groups: mappedGroups,
                        isMoving: isMoving,
                        onCancel: onCancel,
                        onMoveConfirmed: { row, col in moveBottle(row: row, col: col) }
                    )
                }
            }
            .task {
                await loadData()
            }
        }
    }

    private var mappedGroups: [BottleMovePage.Group] {
        let occupantByPosition = Dictionary(uniqueKeysWithValues: bottles.map { ($0.position, $0) })
        return (0..<6).map { rowIdx in
            let rowLetter = String(UnicodeScalar(65 + rowIdx)!)
            let cells: [BottleMovePage.Cell] = (1...8).map { col in
                let label = "\(rowLetter)\(col)"
                if label == currentPosition {
                    return .init(row: rowLetter, col: col, label: label, state: .current)
                }
                if let occupant = occupantByPosition[label] {
                    return .init(
                        row: rowLetter, col: col, label: label,
                        state: .occupied(
                            name: occupant.wine.name,
                            beverageType: occupant.wine.beverageType,
                            color: occupant.wine.color
                        )
                    )
                }
                return .init(row: rowLetter, col: col, label: label, state: .empty)
            }
            return .init(row: rowLetter, cells: cells)
        }
    }

    private func loadData() async {
        do {
            bottles = try await CellarAPI.getAllBottles()
            isLoading = false
        } catch {
            self.error = reportError(error)
            isLoading = false
        }
    }

    private func moveBottle(row: String, col: Int) {
        isMoving = true
        Task {
            do {
                try await CellarAPI.move(wineId: wineId, row: row, col: col)
                onMoved()
            } catch {
                self.error = reportError(error)
            }
            isMoving = false
        }
    }
}

#Preview {
    BottleMoveView(
        wineId: "preview",
        wineName: "Château Margaux",
        wineColor: .red,
        wineVintage: 2018,
        currentRow: "A",
        currentCol: 1,
        onMoved: {}
    )
}
