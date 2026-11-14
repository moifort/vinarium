import SwiftUI

/// What a wine is, as plain label over value pairs two to a row, each under a hairline,
/// as the TV app lists a film's details: no card around them, no icon beside them.
/// A wide fact (the grape varieties) takes the whole row. Only the facts given are
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

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 0) {
            ForEach(rows.indices, id: \.self) { index in
                let row = rows[index]
                GridRow {
                    ForEach(row) { fact in
                        cell(fact)
                            .gridCellColumns(fact.isWide ? 2 : 1)
                    }
                    if row.count == 1, !row[0].isWide {
                        Color.clear.frame(height: 1)
                    }
                }
            }
        }
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

    private func cell(_ fact: Fact) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(verbatim: fact.title)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(verbatim: fact.value)
                .font(.body.weight(.medium))
                .lineLimit(fact.isWide ? 3 : 1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 10)
        .padding(.bottom, 11)
        .overlay(alignment: .top) {
            Rectangle().fill(Color(.separator)).frame(height: 0.5)
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
}
