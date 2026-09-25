import SwiftUI

/// The brand mark: a 3 x 3 mosaic of bottle capsules echoing the app icon, the
/// middle row shifted by half a capsule to keep the icon's diagonal rhythm. It
/// only lays the capsules out; callers dress each one through `capsule`, so the
/// login's entrance (`BrandLogo`) keeps its cascade while the geometry stays in
/// one place. The opening draws the same nine capsules, at the same rhythm, out
/// of its field: see `CapsuleField`.
struct BrandMark<Capsule: View>: View {
    var capsuleSize: CGFloat = 34
    @ViewBuilder var capsule: (BrandCapsuleSlot) -> Capsule

    init(capsuleSize: CGFloat = 34, @ViewBuilder capsule: @escaping (BrandCapsuleSlot) -> Capsule) {
        self.capsuleSize = capsuleSize
        self.capsule = capsule
    }

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(Array(BrandPalette.rows.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: spacing) {
                    ForEach(Array(row.enumerated()), id: \.offset) { columnIndex, color in
                        capsule(BrandCapsuleSlot(row: rowIndex, column: columnIndex, color: color, size: capsuleSize))
                    }
                }
                // The middle row's nudge is padding, not an offset, so the mark's
                // frame holds the whole drawing and what centres the view centres
                // the mosaic.
                .padding(.leading, rowIndex == 1 ? shift : 0)
                .padding(.trailing, rowIndex == 1 ? 0 : shift)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: "Vinarium"))
    }

    private var spacing: CGFloat { capsuleSize * BrandPalette.spacingRatio }
    private var shift: CGFloat { (capsuleSize + spacing) / 2 }
}

extension BrandMark where Capsule == BrandCapsule {
    /// The mark at rest, every capsule as drawn.
    init(capsuleSize: CGFloat = 34) {
        self.init(capsuleSize: capsuleSize) { BrandCapsule(slot: $0) }
    }
}

/// One capsule's place in the mosaic: which row and column it sits in, its
/// colour and its size. Handed to the `capsule` builder of `BrandMark`.
struct BrandCapsuleSlot {
    let row: Int
    let column: Int
    let color: Color
    let size: CGFloat
}

/// A single capsule as a view, `CapsuleDrawing` given a frame. The frame is the
/// disc alone; the shadow overflows it, like any SwiftUI shadow would.
struct BrandCapsule: View {
    let color: Color
    let size: CGFloat

    init(color: Color, size: CGFloat) {
        self.color = color
        self.size = size
    }

    init(slot: BrandCapsuleSlot) {
        self.init(color: slot.color, size: slot.size)
    }

    var body: some View {
        let margin = size * CapsuleDrawing.shadowMargin
        Color.clear
            .frame(width: size, height: size)
            .overlay {
                Canvas { ctx, canvasSize in
                    CapsuleDrawing.draw(
                        ctx,
                        at: CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2),
                        size: size,
                        color: color
                    )
                }
                .frame(width: size + margin * 2, height: size + margin * 2)
            }
    }
}

#Preview("Mark") {
    BrandMark()
        .padding(40)
}

#Preview("Mark on the icon's charcoal") {
    BrandMark()
        .padding(40)
        .background(Color("LaunchBackground"))
}

#Preview("Capsules") {
    HStack(spacing: 24) {
        BrandCapsule(color: Color(red: 0.5, green: 0.05, blue: 0.1), size: 40)
        BrandCapsule(color: Color(red: 0.72, green: 0.45, blue: 0.2), size: 64)
        BrandCapsule(color: Color(red: 0.93, green: 0.72, blue: 0.23), size: 96)
    }
    .padding(40)
}
