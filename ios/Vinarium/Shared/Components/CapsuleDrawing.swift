import SwiftUI

/// Palette sampled from the app icon (burgundy / rose / plum / gold / amber),
/// and the 3 x 3 arrangement that is the brand mark, in the icon's diagonal
/// rhythm: the middle row sits half a capsule to the right of the other two.
enum BrandPalette {
    static let burgundy = Color(red: 0.55, green: 0.07, blue: 0.16)
    static let rose = Color(red: 0.80, green: 0.20, blue: 0.25)
    static let plum = Color(red: 0.42, green: 0.13, blue: 0.24)
    static let gold = Color(red: 0.83, green: 0.68, blue: 0.35)
    static let amber = Color(red: 0.85, green: 0.55, blue: 0.15)

    static let all: [Color] = [burgundy, rose, plum, gold, amber]

    static let rows: [[Color]] = [
        [plum, rose, gold],
        [burgundy, gold, amber],
        [gold, rose, burgundy],
    ]

    /// The gap between two capsules, as a fraction of their diameter.
    static let spacingRatio: CGFloat = 0.28
}

/// One bottle capsule seen from above, the icon's screw cap: a disc lit from
/// the top left, a recessed metallic rim, a thin dark edge and a soft drop
/// shadow. Drawn into a `GraphicsContext`, so the login's mark, the opening's
/// field of capsules and the rendered launch image all come from one hand.
enum CapsuleDrawing {
    /// How far the shadow reaches past the disc, as a fraction of the diameter.
    static let shadowMargin: CGFloat = 0.14

    static func draw(_ ctx: GraphicsContext, at center: CGPoint, size: CGFloat, color: Color, opacity: Double = 1) {
        guard opacity > 0, size > 0 else { return }
        let radius = size / 2
        let disc = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: size, height: size))

        var flat = ctx
        flat.opacity = opacity

        // The drop shadow is a soft disc, not a shadow filter: a filter renders
        // the whole canvas offscreen for every capsule, and the opening draws a
        // hundred and fifty of them per frame.
        let shadowCenter = CGPoint(x: center.x, y: center.y + size * 0.05)
        let shadowReach = radius + size * shadowMargin
        flat.fill(
            Path(ellipseIn: CGRect(
                x: shadowCenter.x - shadowReach, y: shadowCenter.y - shadowReach,
                width: shadowReach * 2, height: shadowReach * 2
            )),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: .black.opacity(0.2), location: 0),
                    .init(color: .black.opacity(0.2), location: (radius - size * 0.04) / shadowReach),
                    .init(color: .black.opacity(0), location: 1),
                ]),
                center: shadowCenter,
                startRadius: 0,
                endRadius: shadowReach
            )
        )

        flat.fill(
            disc,
            with: .radialGradient(
                Gradient(colors: [color, color.opacity(0.82)]),
                center: CGPoint(x: center.x - radius + size * 0.38, y: center.y - radius + size * 0.32),
                startRadius: 0,
                endRadius: size * 0.75
            )
        )

        // Recessed rim, inset from the edge.
        let rimInset = size * 0.14 + size * 0.03
        flat.stroke(
            Path(ellipseIn: CGRect(
                x: center.x - radius + rimInset, y: center.y - radius + rimInset,
                width: size - rimInset * 2, height: size - rimInset * 2
            )),
            with: .color(.white.opacity(0.18)),
            lineWidth: size * 0.06
        )
        // Thin dark edge, drawn inside the disc.
        let edge = max(1, size * 0.03)
        flat.stroke(
            Path(ellipseIn: CGRect(
                x: center.x - radius + edge / 2, y: center.y - radius + edge / 2,
                width: size - edge, height: size - edge
            )),
            with: .color(.black.opacity(0.12)),
            lineWidth: edge
        )
    }
}
