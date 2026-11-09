import SwiftUI

/// A bottle seen close, its shoulder and label filling a small portrait tile, with
/// one figure in the bottom-right corner (a slot, a price) over a blur that rises from
/// that corner, so it reads whatever the label behind it.
struct BottleVignette: View {
    let style: BottleArtwork.Style
    let beverageType: BeverageType
    let color: WineColor?
    let producer: String?
    let name: String
    let vintage: Int?
    /// The figure in the corner; none leaves the bottle bare.
    let caption: String?
    var captionKind: CaptionKind = .position
    var appellation: String? = nil
    var classification: String? = nil

    enum CaptionKind {
        /// A slot: a light blur, the text straight on it.
        case position
        /// A price: a heavier, darkened blur, wider across the corner.
        case price
    }

    static let size = CGSize(width: 108, height: 160)

    var body: some View {
        ZStack {
            artwork
            if let caption {
                artwork
                    .blur(radius: captionKind == .price ? 14 : 8)
                    .saturation(captionKind == .price ? 1.4 : 1)
                    .overlay {
                        if captionKind == .price { Color.black.opacity(0.4) }
                    }
                    .mask { cornerMask }
                Text(caption)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.5), radius: 2)
                    .padding(.trailing, 8)
                    .padding(.bottom, captionKind == .price ? 10 : 11)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .clipShape(.rect(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(.white.opacity(0.22), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.28), radius: 9, y: 6)
    }

    /// The bottle drawn large and cut at the tile's edges: its label sits in the
    /// middle, the neck runs off the top.
    private var artwork: some View {
        BottleBackdrop(beverageType: beverageType, color: color)
            .frame(width: Self.size.width, height: Self.size.height)
            .overlay(alignment: .topLeading) {
                BottleArtwork(
                    style: style, producer: producer, name: name, vintage: vintage,
                    appellation: appellation, classification: classification, height: 250
                )
                    .offset(x: -3, y: -97)
            }
    }

    /// An ellipse centred on the bottom-right corner, opaque at its heart and fading
    /// out, as the board draws it.
    private var cornerMask: some View {
        let isPrice = captionKind == .price
        let radii = isPrice
            ? CGSize(width: Self.size.width * 1.2, height: Self.size.height * 0.42)
            : CGSize(width: Self.size.width * 0.78, height: Self.size.height * 0.34)
        let stops: [Gradient.Stop] = isPrice
            ? [.init(color: .black, location: 0.3), .init(color: .black.opacity(0.78), location: 0.48),
               .init(color: .black.opacity(0.3), location: 0.66), .init(color: .clear, location: 0.84)]
            : [.init(color: .black, location: 0.2), .init(color: .black.opacity(0.78), location: 0.34),
               .init(color: .black.opacity(0.35), location: 0.48), .init(color: .clear, location: 0.66)]
        return EllipticalGradient(stops: stops, center: .center, startRadiusFraction: 0, endRadiusFraction: 0.5)
            .frame(width: radii.width * 2, height: radii.height * 2)
            .position(x: Self.size.width, y: Self.size.height)
            .frame(width: Self.size.width, height: Self.size.height)
    }
}

#Preview("Slot and price") {
    HStack(spacing: 12) {
        BottleVignette(
            style: .of(id: "1", beverageType: .wine, subtype: nil, color: .white),
            beverageType: .wine, color: .white,
            producer: "Vacheron", name: "Les Monts Damnés", vintage: 2022,
            caption: "B1"
        )
        BottleVignette(
            style: .of(id: "2", beverageType: .wine, subtype: nil, color: .red),
            beverageType: .wine, color: .red,
            producer: "La Rioja Alta", name: "Gran Reserva 904", vintage: 2011,
            caption: "62 €", captionKind: .price
        )
        BottleVignette(
            style: .of(id: "3", beverageType: .wine, subtype: .sparkling, color: .white),
            beverageType: .wine, color: .white,
            producer: "Pierre Péters", name: "Blanc de Blancs", vintage: 2017,
            caption: nil
        )
    }
    .padding()
}
