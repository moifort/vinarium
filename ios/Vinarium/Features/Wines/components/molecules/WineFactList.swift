import SwiftUI

/// What a wine is, as tiles two to a row in one frame, the way Shiori's book sheet
/// sets its facts: a small caption in capitals over the value, hairlines between the
/// tiles. The frame is glass rather than a grey card: the wine's colours show blurred
/// through a faint blue veil, lighter in the light appearance, a deep night blue in the
/// dark. A wide fact (the grape varieties), and a narrow one left alone on its row,
/// take the whole row, so the frame never ends on a hole. Only the facts given are
/// drawn. A long press copies a value.
struct WineFactList: View {
    let facts: [Fact]

    struct Fact: Identifiable {
        /// Already localised: the screen words it, the producer's title by beverage.
        let title: String
        let value: String
        var isWide = false
        let id: String
    }

    private static let cornerRadius: CGFloat = 14
    private static let veil = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            // The board's tints: the wine's colours behind carry the glass.
            ? UIColor(red: 10 / 255, green: 20 / 255, blue: 36 / 255, alpha: 0.34)
            : UIColor(red: 240 / 255, green: 247 / 255, blue: 1, alpha: 0.36)
    })
    private static let hairline = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.1)
            : UIColor(red: 60 / 255, green: 84 / 255, blue: 130 / 255, alpha: 0.14)
    })

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Self.cornerRadius)
        Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
            ForEach(rows.indices, id: \.self) { index in
                let row = rows[index]
                GridRow {
                    ForEach(row.indices, id: \.self) { column in
                        cell(row[column], below: index > 0, beside: column > 0)
                            .gridCellColumns(row.count == 1 ? 2 : 1)
                    }
                }
            }
        }
        .background {
            // The material at part strength: the colours behind read through, still
            // blurred.
            shape.fill(.ultraThinMaterial).opacity(0.7)
            shape.fill(Self.veil)
        }
        .clipShape(shape)
        .overlay { shape.strokeBorder(Self.hairline, lineWidth: 1) }
    }

    /// Two narrow facts to a row; a wide one alone.
    private var rows: [[Fact]] {
        var rows: [[Fact]] = []
        var pending: Fact?
        for fact in facts {
            if fact.isWide {
                if let held = pending { rows.append([held]); pending = nil }
                rows.append([fact])
            } else if let held = pending {
                rows.append([held, fact])
                pending = nil
            } else {
                pending = fact
            }
        }
        if let held = pending { rows.append([held]) }
        return rows
    }

    /// A tile, with a hairline above it under another row and before it beside another
    /// tile.
    private func cell(_ fact: Fact, below: Bool, beside: Bool) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(verbatim: fact.title)
                .font(.footnote)
                .textCase(.uppercase)
                .tracking(0.3)
                .foregroundStyle(.secondary)
            Text(verbatim: fact.value)
                .font(.body.weight(.semibold))
                .lineLimit(fact.isWide ? 3 : 1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .overlay(alignment: .top) {
            if below { Rectangle().fill(Self.hairline).frame(height: 1) }
        }
        .overlay(alignment: .leading) {
            if beside { Rectangle().fill(Self.hairline).frame(width: 1) }
        }
        .contentShape(.rect)
        .contextMenu {
            Button("Copier", systemImage: "doc.on.doc") {
                UIPasteboard.general.string = fact.value
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("wine-fact-\(fact.id)")
    }
}

#Preview {
    WineFactList(facts: [
        .init(title: "Domaine", value: "Château Margaux", id: "producer"),
        .init(title: "Cuvée", value: "Pavillon Rouge", id: "cuvee"),
        .init(title: "Millésime", value: "2015", id: "vintage"),
        .init(title: "Alcool", value: "13,5 % vol", id: "alcohol"),
        .init(title: "Appellation", value: "Margaux", id: "appellation"),
        .init(title: "Cépages", value: "Cabernet Sauvignon, Merlot", isWide: true, id: "grapes"),
        .init(title: "Pays", value: "France", id: "country"),
    ])
    .padding(20)
    .background(Color(.systemGroupedBackground))
}
