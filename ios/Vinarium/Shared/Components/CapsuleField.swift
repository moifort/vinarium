import SwiftUI

/// The opening's picture: the whole screen paved with bottle capsules seen from
/// above, the app icon's pattern carried on to the edges, with the brand mark's
/// nine capsules sitting at the centre in their own colours. Given a time, it
/// also plays the clearing: every other capsule shrinks and fades where it
/// sits, the ones around the mark first and the far ones last, with a little
/// disorder so no row goes out in step, until only the mark is left. Then the
/// mark breathes, a ripple down its diagonal, for as long as it is asked to.
///
/// Pure geometry and drawing, no state: the launch image is rendered from it at
/// time zero by `scripts/generate-launch-image.swift`, and `LaunchCurtain`
/// draws it live from the first frame on, so the two pictures are one.
struct CapsuleField {
    /// One capsule of the field, in points from the centre of the screen.
    struct Capsule {
        let position: CGPoint
        let color: Color
        /// The mark's row and column when the capsule is one of its nine.
        let slot: (row: Int, column: Int)?
        /// How long after the clearing starts this capsule goes: by its
        /// distance from the mark, plus its share of disorder, in seconds.
        let delay: TimeInterval
    }

    /// The moment the field starts to clear, once the launch screen's still
    /// picture has been on for a beat.
    static let clearStart: TimeInterval = 0.4
    /// The far capsules go this long after the near ones. Unhurried on
    /// purpose: the clearing is meant to cover the launch query, not to race
    /// it, so a cold start over a slow network still opens on the animation
    /// rather than on a mark waiting alone.
    static let clearStagger: TimeInterval = 1.4
    /// The disorder added to each capsule's turn.
    static let clearJitter: TimeInterval = 0.3
    /// One capsule's fading.
    static let clearDuration: TimeInterval = 0.7
    /// When the last capsule has gone and only the mark remains.
    static var clearEnd: TimeInterval { clearStart + clearStagger + clearJitter + clearDuration }
    /// Seconds for one breath to travel the mark.
    static let breathPeriod: TimeInterval = 1.6

    let capsuleSize: CGFloat
    let capsules: [Capsule]

    /// Lays the field over a viewport of `size`, centred, in a grid whose pitch
    /// is the mark's: capsule plus gap, every other row shifted by half a pitch.
    /// The mark's colours go to the centre; the rest of the field takes the
    /// icon's palette in a fixed scatter.
    init(size: CGSize, capsuleSize: CGFloat) {
        self.capsuleSize = capsuleSize
        let pitch = capsuleSize * (1 + BrandPalette.spacingRatio)
        // The mark's middle row is the shifted one, so its visual centre sits a
        // quarter pitch right of the grid's; the whole field moves left by as
        // much to leave the mark centred on screen.
        let origin = CGPoint(x: -pitch / 4, y: 0)

        func position(row: Int, column: Int) -> CGPoint {
            CGPoint(
                x: origin.x + CGFloat(column) * pitch + (row.isMultiple(of: 2) ? pitch / 2 : 0),
                y: origin.y + CGFloat(row) * pitch
            )
        }

        let rows = Int((size.height / 2) / pitch) + 2
        let columns = Int((size.width / 2) / pitch) + 2
        let farthest = hypot(CGFloat(columns) * pitch, CGFloat(rows) * pitch)
        var capsules: [Capsule] = []
        for row in -rows...rows {
            for column in -columns...columns {
                let point = position(row: row, column: column)
                let isMark = abs(row) <= 1 && abs(column) <= 1
                let scatter = Self.scatter(row: row, column: column)
                let color = isMark
                    ? BrandPalette.rows[row + 1][column + 1]
                    : BrandPalette.all[scatter % BrandPalette.all.count]
                let distance = hypot(point.x - origin.x, point.y - origin.y) / farthest
                capsules.append(Capsule(
                    position: point,
                    color: color,
                    slot: isMark ? (row + 1, column + 1) : nil,
                    delay: Double(distance) * Self.clearStagger + Double(scatter % 100) / 100 * Self.clearJitter
                ))
            }
        }
        self.capsules = capsules
    }

    /// A fixed scatter of palette indices over the grid, the same on every
    /// platform: the launch image and the live field must agree.
    private static func scatter(row: Int, column: Int) -> Int {
        var h = UInt32(bitPattern: Int32(truncatingIfNeeded: row &* 73_856_093 ^ column &* 19_349_663))
        h ^= h >> 13
        h = h &* 0x5BD1_E995
        h ^= h >> 15
        return Int(h % 1000)
    }

    /// Draws the field at `time` seconds into the opening, centred in `size`.
    /// `motion` false keeps every capsule its size: the field simply fades to
    /// the mark.
    func draw(_ ctx: GraphicsContext, size: CGSize, time: TimeInterval, motion: Bool = true, breathing: Bool = true) {
        let centre = CGPoint(x: size.width / 2, y: size.height / 2)

        for capsule in capsules where capsule.slot == nil {
            let progress = min(max((time - Self.clearStart - capsule.delay) / Self.clearDuration, 0), 1)
            if progress >= 1 { continue }
            let gone = Self.smoothstep(progress)
            CapsuleDrawing.draw(
                ctx,
                at: CGPoint(x: centre.x + capsule.position.x, y: centre.y + capsule.position.y),
                size: capsuleSize * (motion ? 1 - gone : 1),
                color: capsule.color,
                opacity: 1 - gone
            )
        }

        for capsule in capsules {
            guard let slot = capsule.slot else { continue }
            var scale: CGFloat = 1
            if breathing, motion, time > Self.clearEnd {
                let phase = 2 * .pi * (time - Self.clearEnd) / Self.breathPeriod - Double(slot.row + slot.column) * 0.6
                scale = 1 + 0.08 * max(0, sin(phase))
            }
            CapsuleDrawing.draw(
                ctx,
                at: CGPoint(x: centre.x + capsule.position.x, y: centre.y + capsule.position.y),
                size: capsuleSize * scale,
                color: capsule.color
            )
        }
    }

    private static func smoothstep(_ t: Double) -> Double {
        let x = min(max(t, 0), 1)
        return x * x * (3 - 2 * x)
    }
}

/// The field as a view, filling whatever it is given.
struct CapsuleFieldView: View {
    var capsuleSize: CGFloat
    var time: TimeInterval
    var motion = true
    var breathing = true

    var body: some View {
        Canvas { ctx, size in
            CapsuleField(size: size, capsuleSize: capsuleSize)
                .draw(ctx, size: size, time: time, motion: motion, breathing: breathing)
        }
    }
}

#Preview("Still") {
    CapsuleFieldView(capsuleSize: 44, time: 0)
        .background(Color("LaunchBackground"))
        .ignoresSafeArea()
}

#Preview("Clearing") {
    TimelineView(.animation) { context in
        CapsuleFieldView(capsuleSize: 44, time: context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 4))
    }
    .background(Color("LaunchBackground"))
    .ignoresSafeArea()
}
