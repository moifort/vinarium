import SwiftUI

/// A portrait tile on a home shelf: the bottle drawn close enough to read its
/// label, and on its right, over a blurred veil, a column that never changes
/// shape: the slot, the drinking limit, the stock and the price, in that order,
/// a dash for what is unknown. The label names the wine, so nothing is written
/// under the tile.
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

    static let size = CGSize(width: 198, height: 248)
    /// The room on the left the bottle stands in, the column taking the rest.
    private static let artWidth: CGFloat = 110
    /// Every bottle is drawn this wide, whatever its shape, so the column always
    /// sits beside the glass and never over it.
    private static let bottleWidth: CGFloat = 92
    private static let columnWidth: CGFloat = size.width - artWidth
    private static let veilWidth: CGFloat = 96
    private static let cornerRadius: CGFloat = 14

    var body: some View {
        ZStack {
            scene
            // The veil behind the column: the scene blurred and darkened, fading in
            // from the left.
            scene
                .blur(radius: 10, opaque: true)
                .overlay(Color.black.opacity(0.22))
                .mask(alignment: .trailing) {
                    LinearGradient(
                        stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.08)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: Self.veilWidth)
                }
            // Soft edges where the bottle runs off the top and the bottom.
            scene
                .blur(radius: 6, opaque: true)
                .mask(alignment: .top) {
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 30)
                }
            scene
                .blur(radius: 6, opaque: true)
                .mask(alignment: .bottom) {
                    LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                        .frame(height: 24)
                }
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
    /// centred on its label: the shoulder and the base run off the edges.
    private var scene: some View {
        let label = style.shape.label
        let scale = Self.bottleWidth / style.shape.path.boundingRect.width
        return BottleBackdrop(beverageType: beverageType, color: color)
            .frame(width: Self.size.width, height: Self.size.height)
            .overlay(alignment: .topLeading) {
                Color.clear
                    .frame(width: Self.artWidth, height: Self.size.height)
                    .overlay(alignment: .topLeading) {
                        BottleArtwork(
                            style: style, producer: producer, name: name, vintage: vintage,
                            appellation: appellation, classification: classification, height: 300 * scale
                        )
                        .offset(
                            x: Self.artWidth / 2 - label.midX * scale,
                            y: Self.size.height / 2 - label.midY * scale
                        )
                    }
                    .clipped()
            }
    }

    private var column: some View {
        VStack(spacing: 0) {
            row(facts.place, label: "cave", first: true)
            row(facts.drinkUntil.map { String($0) }, label: "garde")
            row(facts.stock.map { $0.formatted() }, label: "stock")
            row(facts.price.map { Money.formattedFromEur($0, fractionLength: 0) }, label: "prix")
        }
        .padding(.vertical, 12)
        .padding(.leading, 6)
        .padding(.trailing, 8)
        .frame(width: Self.columnWidth)
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
    }

    private func row(_ value: String?, label: LocalizedStringKey, first: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value ?? "—")
                .font(.system(size: 18, weight: .semibold))
                .tracking(-0.2)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.7)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .opacity(0.7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
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
