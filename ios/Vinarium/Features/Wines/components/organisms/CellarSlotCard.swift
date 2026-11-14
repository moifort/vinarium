import SwiftUI

/// Where the bottle stands, on glass: the cellar drawn as its grid of slots with the
/// bottle's one lit in the wine's colour, and the slot's name large under it. A
/// cellar bigger than the card shows the part of the grid around the slot.
struct CellarSlotCard: View {
    let position: String
    /// The cellar's name, once the household has several.
    var cellarName: String? = nil
    /// The cellar's size and the slot in it, 0-based; nil draws the name alone.
    var grid: Grid? = nil
    let accent: Color

    struct Grid: Equatable {
        let rows: Int
        let cols: Int
        let row: Int
        let col: Int
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(cellarName ?? String(localized: "Emplacement"))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            if let grid {
                SlotGrid(grid: grid, accent: accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                Spacer(minLength: 0)
            }
            Text(position)
                .font(.system(size: 34, weight: .bold, design: .monospaced))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .accessibilityIdentifier("wine-detail-position")
        }
        .padding(.horizontal, 16)
        .padding(.top, 15)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .glassEffect(.regular, in: .rect(cornerRadius: 26))
        .accessibilityElement(children: .combine)
    }
}

/// The slots, as rounded squares, at most eight across and six down: a larger
/// cellar shows the window around the bottle.
private struct SlotGrid: View {
    let grid: CellarSlotCard.Grid
    let accent: Color

    private static let maxCols = 8
    private static let maxRows = 6

    var body: some View {
        let cols = min(grid.cols, Self.maxCols)
        let rows = min(grid.rows, Self.maxRows)
        let firstCol = window(start: grid.col, count: cols, total: grid.cols)
        let firstRow = window(start: grid.row, count: rows, total: grid.rows)
        Canvas { context, size in
            let gap: CGFloat = 5
            let side = min(
                (size.width - gap * CGFloat(cols - 1)) / CGFloat(cols),
                (size.height - gap * CGFloat(rows - 1)) / CGFloat(rows)
            )
            guard side > 0 else { return }
            for r in 0..<rows {
                for c in 0..<cols {
                    let rect = CGRect(
                        x: CGFloat(c) * (side + gap),
                        y: CGFloat(r) * (side + gap),
                        width: side, height: side
                    )
                    let cell = Path(roundedRect: rect, cornerRadius: side * 0.28)
                    if firstRow + r == grid.row, firstCol + c == grid.col {
                        context.fill(
                            Path(roundedRect: rect.insetBy(dx: -3, dy: -3), cornerRadius: side * 0.36),
                            with: .color(accent.opacity(0.25))
                        )
                        context.fill(cell, with: .color(accent))
                    } else {
                        context.fill(cell, with: .color(Color(.systemFill)))
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }

    /// The first row or column shown, so the slot sits in the window.
    private func window(start: Int, count: Int, total: Int) -> Int {
        guard total > count else { return 0 }
        return min(max(start - count / 2, 0), total - count)
    }
}

#Preview("Slot") {
    HStack(spacing: 13) {
        CellarSlotCard(position: "A1", grid: .init(rows: 4, cols: 6, row: 0, col: 0), accent: WineSheetTone.red.accent)
        CellarSlotCard(position: "K14", cellarName: "Cave du garage", grid: .init(rows: 20, cols: 24, row: 10, col: 13), accent: WineSheetTone.white.accent)
    }
    .frame(height: 196)
    .padding(20)
    .background(WineSheetBackdrop(tone: .red))
}
