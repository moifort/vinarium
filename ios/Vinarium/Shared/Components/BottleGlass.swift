import SwiftUI

/// The round glass of a drawn bottle, shared by `BottleArtwork` and the turning
/// bottle of an empty cellar. A bottle is a cylinder that narrows at the shoulder:
/// the glass and the capsule are shaded slice by slice across their own width, so
/// the neck and the shoulder turn as the body does; the reflection is a narrow band
/// that follows the silhouette, wider where the shoulder faces the light, and the
/// sides darken along the outline. The board draws the same light.
enum BottleGlass {
    /// Fills the outline from `top` to `bottom` with a gradient that runs across
    /// the glass's width at each height, not across the whole drawing.
    static func fill(
        _ gradient: Gradient,
        shape: BottleArtwork.Shape,
        from top: CGFloat = 0,
        to bottom: CGFloat = 300,
        in context: GraphicsContext
    ) {
        var context = context
        context.clip(to: shape.path)
        for slice in shape.profile.slices(from: top, to: bottom) {
            context.fill(Path(slice), with: .linearGradient(
                gradient,
                startPoint: CGPoint(x: slice.minX, y: 0),
                endPoint: CGPoint(x: slice.maxX, y: 0)
            ))
        }
    }

    /// The light over the glass, label included: the sides in shadow, a narrow
    /// reflection, a finer one beside it and a glint along the far edge. Quieter on
    /// dark glass, where it would read as stripes, and less shadow on clear glass.
    static func light(shape: BottleArtwork.Shape, clear: Bool, in context: GraphicsContext) {
        let profile = shape.profile
        var inside = context
        inside.clip(to: shape.path)

        let shadow: CGFloat = clear ? 0.5 : 1
        for (side, opacity, width) in [(Side.left, 0.5, 8.0), (Side.right, 0.65, 11.0)] {
            var edge = inside
            edge.addFilter(.blur(radius: 2.5))
            edge.stroke(
                profile.edge(side),
                with: .color(.black.opacity(opacity * shadow)),
                lineWidth: width
            )
        }

        let strength = clear ? 1 : 2 / 3.0
        let shine = Gradient(stops: [
            .init(color: .white.opacity(0.55 * strength), location: 0),
            .init(color: .white.opacity(0.7 * strength), location: 0.45),
            .init(color: .white.opacity(0.4 * strength), location: 0.85),
            .init(color: .white.opacity(0), location: 1),
        ])
        let top = profile.top, bottom = profile.bottom
        let bands: [(Path, Double)] = [
            (profile.band(from: 0.2, to: 0.3, top: top + 2, bottom: bottom - 4, widen: 0.1), 1),
            (profile.band(from: 0.37, to: 0.395, top: top + 8, bottom: bottom - 30), 0.45),
            (profile.band(from: 0.84, to: 0.88, top: top + 6, bottom: bottom - 8), 0.28),
        ]
        for (band, opacity) in bands {
            var reflection = inside
            reflection.opacity = opacity
            reflection.addFilter(.blur(radius: 0.9))
            reflection.fill(band, with: .linearGradient(
                shine,
                startPoint: CGPoint(x: 0, y: top),
                endPoint: CGPoint(x: 0, y: bottom)
            ))
        }
    }

    enum Side { case left, right }

    /// The glass's edges at every half unit of height, read from the outline.
    struct Profile: Sendable {
        let top: CGFloat
        let bottom: CGFloat
        /// Left and right edges, one row per half unit from `top`.
        private let rows: [(left: CGFloat, right: CGFloat)]
        /// How fast the glass widens at each row, 0…1: the shoulder faces the light.
        private let lit: [CGFloat]

        init(path: Path) {
            let polygon = Profile.flatten(path)
            top = polygon.map(\.y).min() ?? 0
            bottom = polygon.map(\.y).max() ?? 300
            var rows: [(CGFloat, CGFloat)] = []
            var y = top
            while y <= bottom {
                rows.append(Profile.span(of: polygon, at: min(y, bottom - 0.01)) ?? rows.last ?? (50, 50))
                y += 0.5
            }
            self.rows = rows
            // Widening per unit of height; the heel, rounding off at the bottom, is
            // not a shoulder.
            let widths = rows.map { $0.1 - $0.0 }
            var slopes = zip(widths, widths.dropFirst()).map { abs($1 - $0) / 0.5 }
            slopes.append(0)
            let heel = rows.count - 40
            for index in slopes.indices where index >= heel { slopes[index] = 0 }
            let steepest = slopes.max() ?? 1
            lit = slopes.map { steepest > 0 ? min(1, $0 / steepest) : 0 }
        }

        private func index(_ y: CGFloat) -> Int {
            min(max(Int(((y - top) / 0.5).rounded()), 0), rows.count - 1)
        }

        func edges(at y: CGFloat) -> (left: CGFloat, right: CGFloat) { rows[index(y)] }

        /// Rects covering `top`…`bottom`, each as wide as the glass at its height;
        /// rows of nearly the same width share one rect. Each overlaps the next a
        /// little, so no seam shows between them.
        func slices(from top: CGFloat, to bottom: CGFloat) -> [CGRect] {
            var result: [CGRect] = []
            var y = max(top, self.top)
            let end = min(bottom, self.bottom)
            while y < end - 0.01 {
                let (left, right) = edges(at: y + 0.25)
                var height: CGFloat = 0.5
                while y + height < end - 0.01 {
                    let (l, r) = edges(at: y + height + 0.25)
                    if abs((r - l) - (right - left)) > 1.2 { break }
                    height += 0.5
                }
                height = min(height, end - y)
                let overlap: CGFloat = y + height < end - 0.01 ? 0.6 : 0
                result.append(CGRect(x: left, y: y, width: right - left, height: height + overlap))
                y += height
            }
            return result
        }

        /// The band between fractions `a` and `b` of the glass's width, following
        /// the silhouette; `widen` opens it where the shoulder is lit.
        func band(from a: CGFloat, to b: CGFloat, top: CGFloat, bottom: CGFloat, widen: CGFloat = 0) -> Path {
            var leading: [CGPoint] = [], trailing: [CGPoint] = []
            var y = top
            while y <= bottom {
                let (left, right) = edges(at: y)
                let width = right - left
                let open = lit[index(y)] * widen
                leading.append(CGPoint(x: left + (a - open) * width, y: y))
                trailing.append(CGPoint(x: left + (b + open * 0.6) * width, y: y))
                y += 1
            }
            var path = Path()
            path.addLines(leading + trailing.reversed())
            path.closeSubpath()
            return path
        }

        /// One side of the glass, from the top of the neck to the base.
        func edge(_ side: Side) -> Path {
            var points: [CGPoint] = []
            var y = top
            while y <= bottom {
                let (left, right) = edges(at: y)
                points.append(CGPoint(x: side == .left ? left : right, y: y))
                y += 1
            }
            var path = Path()
            path.addLines(points)
            return path
        }

        private static func flatten(_ path: Path) -> [CGPoint] {
            var points: [CGPoint] = []
            var current = CGPoint.zero, start = CGPoint.zero
            let steps = 24
            path.forEach { element in
                switch element {
                case let .move(to: p):
                    current = p; start = p; points.append(p)
                case let .line(to: p):
                    current = p; points.append(p)
                case let .quadCurve(to: p, control: c):
                    for k in 1...steps {
                        let t = CGFloat(k) / CGFloat(steps), u = 1 - t
                        points.append(CGPoint(
                            x: u * u * current.x + 2 * u * t * c.x + t * t * p.x,
                            y: u * u * current.y + 2 * u * t * c.y + t * t * p.y
                        ))
                    }
                    current = p
                case let .curve(to: p, control1: c1, control2: c2):
                    for k in 1...steps {
                        let t = CGFloat(k) / CGFloat(steps), u = 1 - t
                        let a = u * u * u, b = 3 * u * u * t, c = 3 * u * t * t, d = t * t * t
                        points.append(CGPoint(
                            x: a * current.x + b * c1.x + c * c2.x + d * p.x,
                            y: a * current.y + b * c1.y + c * c2.y + d * p.y
                        ))
                    }
                    current = p
                case .closeSubpath:
                    points.append(start); current = start
                }
            }
            return points
        }

        private static func span(of polygon: [CGPoint], at y: CGFloat) -> (CGFloat, CGFloat)? {
            var xs: [CGFloat] = []
            for (p, q) in zip(polygon, polygon.dropFirst()) where (p.y <= y && y < q.y) || (q.y <= y && y < p.y) {
                xs.append(p.x + (y - p.y) * (q.x - p.x) / (q.y - p.y))
            }
            guard xs.count >= 2, let low = xs.min(), let high = xs.max() else { return nil }
            return (low, high)
        }
    }
}

extension BottleArtwork.Shape: CaseIterable {
    static let allCases: [BottleArtwork.Shape] = [.bordeaux, .burgundy, .champagne, .provence, .flute, .whisky]

    private static let profiles: [BottleArtwork.Shape: BottleGlass.Profile] = Dictionary(
        uniqueKeysWithValues: allCases.map { ($0, BottleGlass.Profile(path: $0.path)) }
    )

    /// The glass's edges at every height, worked out once per shape.
    var profile: BottleGlass.Profile { Self.profiles[self]! }
}
