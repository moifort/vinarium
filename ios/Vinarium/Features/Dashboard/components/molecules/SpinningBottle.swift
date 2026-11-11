import SwiftUI

/// A bottle turning on itself, for the home of an empty cellar: a Grange des Pères
/// 1985 in green Bordeaux glass, its paper label wrapped round the glass. The glass,
/// its shading and its reflections stay still, as on a real bottle turned by hand;
/// only the label travels round, cut in thin strips laid on the cylinder, so it
/// narrows towards the edges and disappears behind. One turn every nine seconds,
/// held face on when Reduce Motion is on. Drawn in the 100 × 300 space of
/// `BottleArtwork`, scaled to `height`.
struct SpinningBottle: View {
    var height: CGFloat = 330
    /// The time of one whole turn.
    var period: TimeInterval = 9

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let shape = BottleArtwork.Shape.bordeaux
    /// The glass's edges and radius, where the label wraps.
    private let left: CGFloat = 18
    private let right: CGFloat = 82
    /// How many strips the label is cut in: enough that the bend never shows.
    private let strips = 48

    var body: some View {
        let scale = height / 300
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let angle = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: period) / period * 2 * .pi
            Canvas { context, _ in
                draw(in: context, scale: scale, angle: angle)
            } symbols: {
                SpinningBottleLabel(scale: scale)
                    .frame(width: labelLength * scale, height: shape.label.height * scale)
                    .tag(0)
            }
        }
        .frame(width: 100 * scale, height: height)
        .accessibilityHidden(true)
    }

    /// Half the glass's circumference: the label covers the front half of the bottle.
    private var labelLength: CGFloat { .pi * (right - left) / 2 }

    private func draw(in context: GraphicsContext, scale: CGFloat, angle: Double) {
        let outline = shape.path
        var glass = context
        glass.scaleBy(x: scale, y: scale)
        glass.fill(outline, with: .linearGradient(
            BottleArtwork.Glass.green.gradient,
            startPoint: .zero,
            endPoint: CGPoint(x: 100, y: 0)
        ))
        var inside = glass
        inside.clip(to: outline)
        inside.fill(Path(CGRect(x: 0, y: 0, width: 100, height: shape.capsuleHeight)), with: .linearGradient(
            BottleArtwork.Capsule.bordeaux.gradient,
            startPoint: .zero,
            endPoint: CGPoint(x: 100, y: 0)
        ))
        inside.fill(
            Path(CGRect(x: 0, y: shape.capsuleHeight - 3, width: 100, height: 3)),
            with: .color(.black.opacity(0.25))
        )

        // The label, strip by strip: each one lands where its angle on the cylinder
        // projects, and the strips facing away are not drawn.
        if let label = context.resolveSymbol(id: 0) {
            let radius = (right - left) / 2
            let center = (left + right) / 2
            let step = Double.pi / Double(strips)
            let width = labelLength / CGFloat(strips)
            var paper = context
            paper.clip(to: outline.applying(CGAffineTransform(scaleX: scale, y: scale)))
            for index in 0..<strips {
                let from = -Double.pi / 2 + Double(index) * step - angle
                let to = from + step
                guard cos((from + to) / 2) > 0 else { continue }
                let x0 = center + radius * CGFloat(sin(from))
                let x1 = center + radius * CGFloat(sin(to))
                guard x1 > x0 else { continue }
                // A hair of overlap, so the seams between strips never show.
                let strip = CGRect(
                    x: (x0 - 0.15) * scale, y: shape.label.minY * scale,
                    width: (x1 - x0 + 0.3) * scale, height: shape.label.height * scale
                )
                var slice = paper
                slice.clip(to: Path(strip))
                let stretch = (x1 - x0) / width
                slice.translateBy(x: (x0 - CGFloat(index) * width * stretch) * scale, y: shape.label.minY * scale)
                slice.scaleBy(x: stretch, y: 1)
                slice.draw(label, at: .zero, anchor: .topLeading)
            }
        }

        // The cylinder's shading, over glass and paper alike, then the two reflections
        // running down the glass, which do not turn with the label.
        let shade = Gradient(stops: [
            .init(color: .black.opacity(0.4), location: 0),
            .init(color: .black.opacity(0.1), location: 0.2),
            .init(color: .white.opacity(0.22), location: 0.32),
            .init(color: .white.opacity(0), location: 0.42),
            .init(color: .black.opacity(0.12), location: 0.75),
            .init(color: .black.opacity(0.45), location: 1),
        ])
        inside.fill(
            Path(CGRect(x: 0, y: shape.capsuleHeight + 2, width: 100, height: 300)),
            with: .linearGradient(shade, startPoint: CGPoint(x: left, y: 0), endPoint: CGPoint(x: right, y: 0))
        )
        let shine = Gradient(stops: [
            .init(color: .white.opacity(0), location: 0),
            .init(color: .white.opacity(0.5), location: 0.25),
            .init(color: .white.opacity(0.2), location: 0.8),
            .init(color: .white.opacity(0), location: 1),
        ])
        for (rect, opacity) in [
            (CGRect(x: shape.shineX, y: 66, width: 7, height: 222), 0.8),
            (CGRect(x: shape.shineX + 11, y: 88, width: 2.5, height: 162), 0.45),
        ] {
            var reflection = inside
            reflection.opacity = opacity
            reflection.addFilter(.blur(radius: 1.4))
            reflection.fill(
                Path(roundedRect: rect, cornerRadius: rect.width / 2),
                with: .linearGradient(shine, startPoint: CGPoint(x: 0, y: rect.minY), endPoint: CGPoint(x: 0, y: rect.maxY))
            )
        }
    }
}

/// The label of the turning bottle, laid flat: cream paper, a thin frame, the domaine
/// in italic serif and the vintage. Proper names, written as they are in every language.
private struct SpinningBottleLabel: View {
    let scale: CGFloat

    private let ink = Color(hex: 0x1D1916)
    private let faded = Color(hex: 0x3A332C)

    var body: some View {
        ZStack {
            Color(hex: 0xF3ECDC)
            VStack(spacing: 0) {
                Text(verbatim: "DOMAINE DE LA")
                    .font(.custom("Georgia", fixedSize: 4.5 * scale))
                    .tracking(1 * scale)
                    .foregroundStyle(faded)
                Text(verbatim: "Grange")
                    .font(.custom("Georgia-Italic", fixedSize: 12.7 * scale))
                    .foregroundStyle(ink)
                    .padding(.top, 4.5 * scale)
                Text(verbatim: "des Pères")
                    .font(.custom("Georgia-Italic", fixedSize: 10.5 * scale))
                    .foregroundStyle(ink)
                Rectangle()
                    .fill(Color(hex: 0x7A2A2A))
                    .frame(width: 20 * scale, height: 0.65 * scale)
                    .padding(.vertical, 5 * scale)
                Text(verbatim: "1985")
                    .font(.custom("Georgia", fixedSize: 9 * scale))
                    .foregroundStyle(ink)
                Text(verbatim: "LANGUEDOC · VIN ROUGE")
                    .font(.custom("Georgia", fixedSize: 3.3 * scale))
                    .tracking(0.4 * scale)
                    .foregroundStyle(faded)
                    .padding(.top, 7 * scale)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                Rectangle().strokeBorder(Color(hex: 0x2A2420), lineWidth: 0.55 * scale)
            }
            .padding(.horizontal, 5.5 * scale)
            .padding(.vertical, 3.6 * scale)
        }
    }
}

#Preview("Spinning bottle") {
    SpinningBottle()
        .padding()
}
