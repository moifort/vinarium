import SwiftUI

/// A bottle turning on itself. On the home of an empty cellar, a Grange des Pères
/// 1985 in green Bordeaux glass; on a wine's sheet, that wine, in the bottle and the
/// label the home screen draws it with (`BottleArtwork`). The glass, its shading and
/// its reflections (`BottleGlass`) stay still, as on a real bottle turned by hand;
/// only the label travels round, cut in thin strips laid on the cylinder, so it
/// narrows towards the edges and disappears behind. One turn every nine seconds,
/// held face on when Reduce Motion is on. Drawn in the 100 × 300 space of
/// `BottleArtwork`, scaled to `height`.
struct SpinningBottle: View {
    /// The wine whose label turns; nil for the empty cellar's Grange des Pères.
    var wine: Wine? = nil
    var height: CGFloat = 330
    /// The time of one whole turn.
    var period: TimeInterval = 9

    /// A wine's bottle: its style and what its label says.
    struct Wine {
        let style: BottleArtwork.Style
        let text: BottleArtwork.LabelText
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shape: BottleArtwork.Shape { wine?.style.shape ?? .bordeaux }
    private var glassTint: BottleArtwork.Glass { wine?.style.glass ?? .green }
    private var capsule: BottleArtwork.Capsule { wine?.style.capsule ?? .bordeaux }
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
                label(scale: scale).tag(0)
            }
        }
        .frame(width: 100 * scale, height: height)
        .accessibilityHidden(true)
    }

    /// The label laid flat, as long as the arc it covers round the glass, in a frame
    /// as tall as the bottle with the paper at its height: what a family adds on the
    /// neck (a collar) falls outside the band the strips take and is left out.
    @ViewBuilder private func label(scale: CGFloat) -> some View {
        if let wine {
            let length = labelLength
            let band = shape.label
            Canvas { context, _ in
                context.scaleBy(x: scale, y: scale)
                BottleArtwork.drawLabel(
                    wine.style.look,
                    text: wine.text,
                    in: CGRect(x: 0, y: band.minY, width: length, height: band.height),
                    context: context
                )
            }
            .frame(width: length * scale, height: 300 * scale)
        } else {
            VStack(spacing: 0) {
                SpinningBottleLabel(scale: scale)
                    .frame(width: labelLength * scale, height: shape.label.height * scale)
                    .padding(.top, shape.label.minY * scale)
                Spacer(minLength: 0)
            }
            .frame(width: labelLength * scale, height: 300 * scale)
        }
    }

    /// The glass's radius at the label.
    private var radius: CGFloat { (shape.barrel.right - shape.barrel.left) / 2 }

    /// The arc the label covers round the glass. The empty cellar's paper wraps the
    /// front half; a wine's label covers the arc that, seen face on, is as wide as
    /// the flat label `BottleArtwork` draws, so the turning bottle stops on the same
    /// face as the still one.
    private var span: Double {
        guard wine != nil else { return .pi }
        return 2 * asin(min(Double(shape.label.width / (2 * radius)), 0.98))
    }

    /// The label's length laid flat: its arc's length round the glass.
    private var labelLength: CGFloat { radius * CGFloat(span) }

    private func draw(in context: GraphicsContext, scale: CGFloat, angle: Double) {
        let outline = shape.path
        var glass = context
        glass.scaleBy(x: scale, y: scale)
        BottleGlass.fill(glassTint.gradient, shape: shape, in: glass)
        var inside = glass
        inside.clip(to: outline)
        if glassTint.isClear {
            inside.fill(Path(CGRect(x: 0, y: 0, width: 100, height: 300)), with: .color(.white.opacity(0.18)))
        }
        BottleGlass.fill(capsule.gradient, shape: shape, to: shape.capsuleHeight, in: inside)
        inside.fill(
            Path(CGRect(x: 0, y: shape.capsuleHeight - 3, width: 100, height: 3)),
            with: .color(.black.opacity(0.25))
        )

        // The label, strip by strip: each one lands where its angle on the cylinder
        // projects, and the strips facing away are not drawn.
        if let label = context.resolveSymbol(id: 0) {
            let center = (shape.barrel.left + shape.barrel.right) / 2
            let step = span / Double(strips)
            let width = labelLength / CGFloat(strips)
            let band = shape.label
            var paper = context
            paper.clip(to: outline.applying(CGAffineTransform(scaleX: scale, y: scale)))
            for index in 0..<strips {
                let from = -span / 2 + Double(index) * step - angle
                let to = from + step
                guard cos((from + to) / 2) > 0 else { continue }
                let x0 = center + radius * CGFloat(sin(from))
                let x1 = center + radius * CGFloat(sin(to))
                guard x1 > x0 else { continue }
                // A hair of overlap, so the seams between strips never show.
                let strip = CGRect(
                    x: (x0 - 0.15) * scale, y: band.minY * scale,
                    width: (x1 - x0 + 0.3) * scale, height: band.height * scale
                )
                var slice = paper
                slice.clip(to: Path(strip))
                let stretch = (x1 - x0) / width
                slice.translateBy(x: (x0 - CGFloat(index) * width * stretch) * scale, y: 0)
                slice.scaleBy(x: stretch, y: 1)
                slice.draw(label, at: .zero, anchor: .topLeading)
            }
        }

        // The light of the round glass, over glass and paper alike: it does not
        // turn with the label.
        BottleGlass.light(shape: shape, clear: glassTint.isClear, in: glass)
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

#Preview("A wine's bottle") {
    HStack(alignment: .bottom, spacing: 16) {
        SpinningBottle(
            wine: .init(
                style: .of(id: "1", beverageType: .wine, subtype: nil, color: .red, family: .chateau, vintage: 2015),
                text: .init(
                    producer: "Château Margaux", name: "Pavillon Rouge", vintage: 2015,
                    appellation: "Margaux", classification: nil, kind: nil
                )
            ),
            height: 300
        )
        SpinningBottle(
            wine: .init(
                style: .of(id: "4", beverageType: .wine, subtype: nil, color: .rosé, family: .provence, vintage: 2023),
                text: .init(
                    producer: "Domaine Tempier", name: "Bandol", vintage: 2023,
                    appellation: "Bandol", classification: nil, kind: nil
                )
            ),
            height: 300
        )
    }
    .padding()
}
