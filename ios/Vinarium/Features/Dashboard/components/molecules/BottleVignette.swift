import SwiftUI

/// A portrait tile on a home shelf: the bottle drawn close enough to read its
/// label, and on its right, on the same plain ground as the bottle, a compact
/// column set at the bottom: the slot, the drinking limit, the stock and the
/// price, in that order, each line left out when there is nothing to show. The label names
/// the wine, so nothing is written under the tile.
struct BottleVignette: View {
    let style: BottleArtwork.Style
    let beverageType: BeverageType
    let color: WineColor?
    let producer: String?
    let name: String
    let vintage: Int?
    var appellation: String? = nil
    var classification: String? = nil
    let facts: Facts

    /// What the column on the right reads, top to bottom.
    struct Facts: Equatable {
        /// The slot in the cellar, nil when the wine is not stored.
        var place: String?
        /// The last year to open it.
        var drinkUntil: Int?
        /// How many identical bottles the cellars hold.
        var stock: Int?
        /// The estimated price of one bottle, in euros.
        var price: Double?
    }

    static let size = CGSize(width: 160, height: 210)
    /// The room on the left the bottle stands in, the column taking the rest.
    private static let artWidth: CGFloat = 84
    /// Every bottle is drawn this wide, whatever its shape, so the column always
    /// sits beside the glass and never over it.
    private static let bottleWidth: CGFloat = 80
    private static let columnWidth: CGFloat = size.width - artWidth
    /// How far the bottle's base sits below the tile's bottom edge.
    private static let baseDrop: CGFloat = 6
    private static let cornerRadius: CGFloat = 14

    var body: some View {
        ZStack {
            scene
            column
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .clipShape(.rect(cornerRadius: Self.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: Self.cornerRadius)
                .strokeBorder(.white.opacity(0.22), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.28), radius: 9, y: 6)
    }

    /// The tinted ground and the bottle, the same width for every shape and
    /// standing on the tile's bottom edge, its base just below it: the neck
    /// runs off the top.
    private var scene: some View {
        let outline = style.shape.path.boundingRect
        let scale = Self.bottleWidth / outline.width
        return BottleBackdrop(beverageType: beverageType, color: color)
            .frame(width: Self.size.width, height: Self.size.height)
            .overlay(alignment: .topLeading) {
                Color.clear
                    .frame(width: Self.artWidth, height: Self.size.height)
                    .overlay(alignment: .topLeading) {
                        BottleArtwork(
                            style: style, producer: producer, name: name, vintage: vintage,
                            appellation: appellation, classification: classification, height: 300 * scale,
                            legible: true
                        )
                        .offset(
                            x: Self.artWidth / 2 - outline.midX * scale,
                            y: Self.size.height + Self.baseDrop - outline.maxY * scale
                        )
                    }
                    .clipped()
            }
    }

    /// The lines worth showing: a wine not stored has no slot, an empty stock
    /// says nothing either.
    private var rows: [(value: String, label: LocalizedStringKey)] {
        var rows: [(value: String, label: LocalizedStringKey)] = []
        if let place = facts.place { rows.append((place, "cave")) }
        if let drinkUntil = facts.drinkUntil { rows.append((String(drinkUntil), "garde")) }
        if let stock = facts.stock, stock > 0 { rows.append((stock.formatted(), "stock")) }
        if let price = facts.price { rows.append((Money.formattedFromEur(price, fractionLength: 0), "prix")) }
        return rows
    }

    private var column: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                self.row(row.value, label: row.label, first: index == 0)
            }
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 6)
        .frame(width: Self.columnWidth)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
    }

    private func row(_ value: String, label: LocalizedStringKey, first: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .tracking(-0.2)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(height: 18)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.7)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .opacity(0.7)
                .frame(height: 11)
        }
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) {
            if !first {
                Rectangle().fill(.white.opacity(0.22)).frame(height: 1)
            }
        }
    }
}

#Preview("Ready and favorite") {
    HStack(spacing: 12) {
        BottleVignette(
            style: .of(id: "1", beverageType: .wine, subtype: nil, color: .white, family: .alsace, vintage: 2021),
            beverageType: .wine, color: .white,
            producer: "Weinbach", name: "Riesling Schlossberg", vintage: 2021,
            classification: "Grand Cru",
            facts: .init(place: "C3", drinkUntil: 2029, stock: 2, price: 54)
        )
        BottleVignette(
            style: .of(id: "2", beverageType: .wine, subtype: nil, color: .red, family: .chateau, vintage: 2016),
            beverageType: .wine, color: .red,
            producer: "Château Talbot", name: "Saint-Julien", vintage: 2016,
            facts: .init(place: nil, drinkUntil: nil, stock: 0, price: 68)
        )
    }
    .padding()
}
