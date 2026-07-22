import SwiftUI

/// A glass of red wine being swirled to aerate it, drawn and animated in a
/// `Canvas`. The glass sweeps a small ellipse (the swirl gesture) and leans into
/// it, pivoting around its foot, while the liquid tilts against the motion with
/// a lag and a travelling ripple runs across its surface, so it reads as wine
/// climbing the walls of the bowl. Meant as the branded replacement for a bare
/// spinner on long cold-start loads. Respects Reduce Motion by holding a single
/// static frame (glass at rest, surface level). Purely presentational.
struct WineGlassLoader: View {
    /// Layout width in points; the height follows the glass proportions.
    var size: CGFloat = 110

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Anchor for elapsed time so the swirl starts from the same pose on appear.
    @State private var start = Date()

    /// Seconds for one full swirl revolution.
    private let period: TimeInterval = 1.4

    // Design space: the glass is drawn in a fixed 100 x 125 coordinate box,
    // then scaled to fit the canvas.
    private static let designWidth: CGFloat = 100
    private static let designHeight: CGFloat = 125
    private static let cx: CGFloat = 50
    private static let rimY: CGFloat = 8
    private static let rimHalfWidth: CGFloat = 27
    private static let bowlBottomY: CGFloat = 78
    private static let stemBottomY: CGFloat = 107
    private static let footY: CGFloat = 110
    private static let wineLevelY: CGFloat = 48

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            let time = reduceMotion ? 0 : context.date.timeIntervalSince(start)
            Canvas { ctx, canvasSize in
                draw(&ctx, canvasSize: canvasSize, time: time, motion: reduceMotion ? 0 : 1)
            }
        }
        .frame(width: size, height: size * Self.designHeight / Self.designWidth)
        .accessibilityHidden(true)
    }

    private func draw(_ ctx: inout GraphicsContext, canvasSize: CGSize, time: TimeInterval, motion: Double) {
        let scale = min(canvasSize.width / Self.designWidth, canvasSize.height / Self.designHeight)
        ctx.translateBy(
            x: (canvasSize.width - Self.designWidth * scale) / 2,
            y: (canvasSize.height - Self.designHeight * scale) / 2
        )
        ctx.scaleBy(x: scale, y: scale)

        let phase = 2 * .pi * time / period

        // The hand gesture: a small elliptical sweep with a lean, pivoting
        // around the foot as if the glass were held by the stem.
        let sweepX = 4.5 * sin(phase) * motion
        let sweepY = 1.6 * cos(phase) * motion
        let lean = Angle.degrees(4 * sin(phase + 0.5) * motion)
        ctx.translateBy(x: sweepX, y: sweepY)
        ctx.translateBy(x: Self.cx, y: Self.footY)
        ctx.rotate(by: lean)
        ctx.translateBy(x: -Self.cx, y: -Self.footY)

        drawWine(ctx, phase: phase, motion: motion)
        drawGlass(ctx)
    }

    private func drawWine(_ ctx: GraphicsContext, phase: Double, motion: Double) {
        var wine = ctx
        wine.clip(to: bowlInterior())

        // Liquid inertia: the surface tilts against the sweep with a lag, and a
        // travelling ripple runs along it.
        let tilt = 0.26 * sin(phase + 2.6) * motion
        func surfaceY(_ x: CGFloat) -> CGFloat {
            Self.wineLevelY + tilt * (x - Self.cx) + 1.1 * motion * sin(x * 0.16 + phase * 2)
        }

        var liquid = Path()
        liquid.move(to: CGPoint(x: Self.cx - 40, y: surfaceY(Self.cx - 40)))
        for step in 1...20 {
            let x = Self.cx - 40 + CGFloat(step) * 4
            liquid.addLine(to: CGPoint(x: x, y: surfaceY(x)))
        }
        liquid.addLine(to: CGPoint(x: Self.cx + 40, y: 95))
        liquid.addLine(to: CGPoint(x: Self.cx - 40, y: 95))
        liquid.closeSubpath()

        wine.fill(
            liquid,
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.62, green: 0.11, blue: 0.20),
                    Color(red: 0.33, green: 0.04, blue: 0.12),
                ]),
                startPoint: CGPoint(x: Self.cx, y: Self.wineLevelY - 8),
                endPoint: CGPoint(x: Self.cx, y: Self.bowlBottomY)
            )
        )

        // Elliptical sheen on the surface, rotated with the tilt: sells the
        // slightly-from-above perspective of a glass being swirled.
        let sheen = Path(ellipseIn: CGRect(x: Self.cx - 26, y: Self.wineLevelY - 3, width: 52, height: 6))
        let rotation = CGAffineTransform(translationX: Self.cx, y: Self.wineLevelY)
            .rotated(by: atan(tilt))
            .translatedBy(x: -Self.cx, y: -Self.wineLevelY)
        wine.fill(
            sheen.applying(rotation),
            with: .color(Color(red: 0.82, green: 0.33, blue: 0.40).opacity(0.5))
        )
    }

    /// The inside of the bowl, inset from the walls by the glass thickness;
    /// the wine is clipped to it.
    private func bowlInterior() -> Path {
        var path = Path()
        path.move(to: CGPoint(x: Self.cx - 25, y: Self.rimY + 1))
        path.addCurve(
            to: CGPoint(x: Self.cx, y: Self.bowlBottomY - 2.5),
            control1: CGPoint(x: Self.cx - 33, y: 30),
            control2: CGPoint(x: Self.cx - 31, y: 60)
        )
        path.addCurve(
            to: CGPoint(x: Self.cx + 25, y: Self.rimY + 1),
            control1: CGPoint(x: Self.cx + 31, y: 60),
            control2: CGPoint(x: Self.cx + 33, y: 30)
        )
        path.closeSubpath()
        return path
    }

    private func drawGlass(_ ctx: GraphicsContext) {
        let glass = Color.primary.opacity(0.3)

        // Bowl walls, rim to rim through the bottom of the cup.
        var bowl = Path()
        bowl.move(to: CGPoint(x: Self.cx - Self.rimHalfWidth, y: Self.rimY))
        bowl.addCurve(
            to: CGPoint(x: Self.cx, y: Self.bowlBottomY),
            control1: CGPoint(x: Self.cx - 36, y: 30),
            control2: CGPoint(x: Self.cx - 34, y: 63)
        )
        bowl.addCurve(
            to: CGPoint(x: Self.cx + Self.rimHalfWidth, y: Self.rimY),
            control1: CGPoint(x: Self.cx + 34, y: 63),
            control2: CGPoint(x: Self.cx + 36, y: 30)
        )
        ctx.stroke(bowl, with: .color(glass), style: StrokeStyle(lineWidth: 2, lineCap: .round))

        // Rim opening, hinted as a flat ellipse.
        ctx.stroke(
            Path(ellipseIn: CGRect(
                x: Self.cx - Self.rimHalfWidth, y: Self.rimY - 4,
                width: Self.rimHalfWidth * 2, height: 8
            )),
            with: .color(glass.opacity(0.55)),
            lineWidth: 1
        )

        // Stem and foot.
        var stem = Path()
        stem.move(to: CGPoint(x: Self.cx, y: Self.bowlBottomY))
        stem.addLine(to: CGPoint(x: Self.cx, y: Self.stemBottomY))
        ctx.stroke(stem, with: .color(glass), style: StrokeStyle(lineWidth: 3, lineCap: .round))

        ctx.stroke(
            Path(ellipseIn: CGRect(x: Self.cx - 22, y: Self.footY - 4.5, width: 44, height: 9)),
            with: .color(glass),
            lineWidth: 2
        )

        // Light catch on the left wall, above the wine line.
        var shine = Path()
        shine.move(to: CGPoint(x: Self.cx - 26, y: 22))
        shine.addQuadCurve(
            to: CGPoint(x: Self.cx - 27.5, y: 44),
            control: CGPoint(x: Self.cx - 29, y: 33)
        )
        ctx.stroke(shine, with: .color(.white.opacity(0.35)), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
    }
}

#Preview("Wine glass loader") {
    WineGlassLoader()
}

#Preview("Wine glass loader, dark") {
    ZStack {
        Color.black.ignoresSafeArea()
        WineGlassLoader()
    }
}
