import SwiftUI

struct BottleMoveView: View {
    let wineId: String
    let wineName: String
    var wineBeverageType: BeverageType = .wine
    let wineColor: WineColor?
    let wineVintage: Int?
    let currentRow: String
    let currentCol: Int
    /// The cellar the bottle stands in.
    var currentCellarId: String? = nil
    var onCancel: () -> Void = {}
    /// Called with the slot the bottle now occupies: row label, column label.
    let onMoved: (String, Int) -> Void

    @State private var bottles: [CellarBottle] = []
    @State private var rows = 6
    @State private var cols = 8
    @State private var isLoading = true
    @State private var error: String?
    @State private var isMoving = false
    @State private var cellars: [CellarSummary] = []
    /// The cellar whose grid is shown, nil for the primary one. Opens on the
    /// bottle's own; another one moves the bottle across.
    @State private var cellarId: String?
    @State private var cellarResolved = false

    private var currentPosition: String { "\(currentRow)\(currentCol)" }

    /// The bottle's own slot is only "here" in its own cellar.
    private var showsOwnCellar: Bool {
        let shown = cellarId ?? cellars.first(where: \.isPrimary)?.id
        return currentCellarId == nil || shown == currentCellarId
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    LoadingStateView(label: "Chargement de la cave...")
                } else if let error {
                    ContentUnavailableView("Erreur", systemImage: "exclamationmark.triangle", description: Text(error))
                } else {
                    BottleMovePage(
                        wineName: wineName,
                        wineBeverageType: wineBeverageType,
                        wineColor: wineColor,
                        wineVintage: wineVintage,
                        currentPosition: showsOwnCellar ? currentPosition : "",
                        groups: mappedGroups,
                        isMoving: isMoving,
                        cellars: cellars,
                        selectedCellarId: $cellarId,
                        onCancel: onCancel,
                        onMoveConfirmed: { row, col in moveBottle(row: row, col: col) }
                    )
                }
            }
            .task(id: cellarId) {
                await loadData()
            }
        }
    }

    private var mappedGroups: [BottleMovePage.Group] {
        let occupantByPosition = Dictionary(uniqueKeysWithValues: bottles.map { ($0.position, $0) })
        return (0..<rows).map { rowIdx in
            let rowLetter = String(UnicodeScalar(65 + rowIdx)!)
            let cells: [BottleMovePage.Cell] = (1...cols).map { col in
                let label = "\(rowLetter)\(col)"
                if showsOwnCellar, label == currentPosition {
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
            // The grid is drawn at its configured size, not a fixed 6x8: a resized
            // cellar would otherwise hide the slots outside that default.
            let grid = try await CellarAPI.grid(withSuggestion: false, cellarId: cellarId)
            // The first load reads the primary cellar; a bottle standing in another
            // one switches the grid to it, which reloads.
            if !cellarResolved {
                cellarResolved = true
                if let own = grid.cellars.first(where: { $0.id == currentCellarId }), !own.isPrimary {
                    cellars = grid.cellars
                    cellarId = own.id
                    return
                }
            }
            cellars = grid.cellars
            bottles = grid.bottles
            rows = grid.rows
            cols = grid.cols
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
                try await CellarAPI.move(
                    wineId: wineId,
                    rowLabel: row,
                    colLabel: col,
                    cellarId: cellarId ?? cellars.first(where: \.isPrimary)?.id
                )
                onMoved(row, col)
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
        onMoved: { _, _ in }
    )
}
