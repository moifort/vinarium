import SwiftUI

struct CellarGridComponent: View {
    let grid: [[GridCell]]
    var highlightedRow: String?
    var highlightedCol: Int?
    var onCellTap: ((Int, Int, GridCell) -> Void)?

    var body: some View {
        if grid.isEmpty {
            ContentUnavailableView("Cave vide", systemImage: "square.grid.3x3", description: Text("Aucune configuration de cave"))
        } else {
            ScrollView([.horizontal, .vertical]) {
                VStack(spacing: 2) {
                    ForEach(Array(grid.enumerated()), id: \.offset) { rowIdx, row in
                        HStack(spacing: 2) {
                            Text(String(UnicodeScalar(65 + rowIdx)!))
                                .font(.caption2)
                                .frame(width: 20)
                                .foregroundStyle(.secondary)

                            ForEach(Array(row.enumerated()), id: \.offset) { colIdx, cell in
                                let isHighlighted = highlightedRow == String(UnicodeScalar(65 + rowIdx)!) && highlightedCol == colIdx + 1
                                cellView(cell: cell, isHighlighted: isHighlighted)
                                    .onTapGesture {
                                        onCellTap?(rowIdx, colIdx, cell)
                                    }
                            }
                        }
                    }

                    // Column numbers
                    HStack(spacing: 2) {
                        Text("")
                            .frame(width: 20)
                        ForEach(0..<(grid.first?.count ?? 0), id: \.self) { colIdx in
                            Text("\(colIdx + 1)")
                                .font(.caption2)
                                .frame(width: 44, height: 20)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
            }
        }
    }

    @ViewBuilder
    private func cellView(cell: GridCell, isHighlighted: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(cellBackground(cell: cell, isHighlighted: isHighlighted))
                .frame(width: 44, height: 44)

            if isHighlighted {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(.green, lineWidth: 3)
                    .frame(width: 44, height: 44)
            }

            if let wine = cell.wine {
                VStack(spacing: 2) {
                    Circle()
                        .fill(wine.color.displayColor.color)
                        .frame(width: 10, height: 10)
                    Text(String(wine.name.prefix(4)))
                        .font(.system(size: 8))
                        .lineLimit(1)
                }
            }
        }
    }

    private func cellBackground(cell: GridCell, isHighlighted: Bool) -> Color {
        if isHighlighted {
            return .green.opacity(0.2)
        }
        if cell.wine != nil {
            return Color(.systemGray5)
        }
        return Color(.systemGray6)
    }
}
