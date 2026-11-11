import SwiftUI

/// A whole bottle drawn with its label written on it, in the house style of the
/// wine's family (see `BottleLabel.swift`): a framed château label on a Bordeaux
/// bottle, a domaine label on a Burgundy one, a shield on a Champagne, a veil on a
/// Provence flute. The glass and the capsule take the wine's tint. Drawn in a
/// 100 × 300 space scaled to `height`, so the label stays sharp at every size.
struct BottleArtwork: View {
    let style: Style
    let producer: String?
    let name: String
    let vintage: Int?
    var appellation: String? = nil
    var classification: String? = nil
    let height: CGFloat
    /// The label set large enough to read on a home vignette, where the bottle is
    /// cropped to its label; a whole bottle keeps the finer one, its name beside it.
    var legible = false

    var body: some View {
        let scale = height / 300
        Canvas { context, _ in
            context.scaleBy(x: scale, y: scale)
            draw(in: &context)
        }
        .frame(width: 100 * scale, height: height)
        // The glass sits on its background like an object, not a sticker.
        .shadow(color: .black.opacity(0.35), radius: 4 * max(scale, 0.5), y: 4 * max(scale, 0.5))
        .accessibilityHidden(true)
    }

    private func draw(in context: inout GraphicsContext) {
        let shape = style.shape
        let outline = shape.path
        context.fill(outline, with: .linearGradient(
            style.glass.gradient,
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 100, y: 0)
        ))

        var inside = context
        inside.clip(to: outline)
        if style.glass.isClear {
            inside.fill(Path(CGRect(x: 0, y: 0, width: 100, height: 300)), with: .color(.white.opacity(0.18)))
        }
        // The capsule over the neck, with the shadow line at its lip.
        inside.fill(Path(CGRect(x: 0, y: 0, width: 100, height: shape.capsuleHeight)), with: .linearGradient(
            style.capsule.gradient,
            startPoint: .zero,
            endPoint: CGPoint(x: 100, y: 0)
        ))
        inside.fill(
            Path(CGRect(x: 0, y: shape.capsuleHeight - 3, width: 100, height: 3)),
            with: .color(.black.opacity(0.2))
        )
        // The paper label, in the family's style.
        let text = LabelText(
            producer: producer, name: name, vintage: vintage,
            appellation: appellation, classification: classification, kind: style.kind
        )
        if legible {
            BottleArtwork.drawLegibleLabel(style.look, text: text, in: shape.label, context: inside)
        } else {
            BottleArtwork.drawLabel(style.look, text: text, in: shape.label, context: inside)
        }
        // Two reflections running down the glass, softened like light on curved
        // glass, and quieter on dark glass, where they would read as stripes.
        let shine = Gradient(stops: [
            .init(color: .white.opacity(0), location: 0),
            .init(color: .white.opacity(0.5), location: 0.25),
            .init(color: .white.opacity(0.22), location: 0.8),
            .init(color: .white.opacity(0), location: 1),
        ])
        let strength = style.glass.isClear ? 1 : 2 / 3.0
        for (rect, opacity) in [
            (CGRect(x: shape.shineX, y: shape.capsuleHeight + 8, width: 7, height: 288 - shape.capsuleHeight - 8), 0.9),
            (CGRect(x: shape.shineX + 11, y: shape.capsuleHeight + 30, width: 2.5, height: 250 - shape.capsuleHeight - 30), 0.5),
        ] {
            var reflection = inside
            reflection.opacity = opacity * strength
            reflection.addFilter(.blur(radius: 1.4))
            reflection.fill(
                Path(roundedRect: rect, cornerRadius: rect.width / 2),
                with: .linearGradient(shine, startPoint: CGPoint(x: 0, y: rect.minY), endPoint: CGPoint(x: 0, y: rect.maxY))
            )
        }
    }
}

// MARK: - Style

extension BottleArtwork {
    struct Style: Equatable {
        let shape: Shape
        let glass: Glass
        let capsule: Capsule
        let look: LabelLook
        /// What a drink that is not wine is, written on its label.
        var kind: String? = nil

        /// The bottle a wine is drawn in. The family picks the shape, the glass and
        /// the label's layout; the wine's id picks one of the family's nine looks,
        /// so a wine always wears the same label; a vintage twenty-five years old
        /// yellows the paper. Without a family from the API, the broad one is
        /// guessed from the type and the colour. A label read by the scan overrides
        /// the id: the closest look of the catalogue is drawn, in another family
        /// when the region's has nothing like it (`LabelTraits.closestLook`).
        static func of(
            id: String,
            beverageType: BeverageType,
            subtype: BeverageSubtype?,
            color: WineColor?,
            family: LabelFamily? = nil,
            traits: LabelTraits? = nil,
            vintage: Int? = nil,
            year: Int = Calendar.current.component(.year, from: .now)
        ) -> Style {
            let pick = abs(id.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) })
            let regional = family ?? .guess(beverageType: beverageType, subtype: subtype, color: color)
            let (family, index) = traits?.closestLook(regional: regional) ?? (regional, pick / 7)
            let looks = LabelLook.looks(of: family)
            var look = looks[index % looks.count]
            let aged = vintage.map { $0 <= year - 25 } ?? false
            look.aged = aged && [.chateau, .burgundy, .south, .sweet, .italy, .rhone, .spain, .portugal].contains(family)
            let kind: String? = beverageType == .wine ? nil : subtype.map { $0.label(for: beverageType) } ?? beverageType.label
            let (shape, glass): (Shape, Glass) = switch family {
            case .chateau: (.bordeaux, aged || pick % 4 == 0 ? .brown : .green)
            case .burgundy: (.burgundy, color == .white ? .olive : .green)
            case .champagne: (.champagne, .green)
            case .provence: (.provence, .pink)
            case .south: (.burgundy, .brown)
            case .alsace: (.flute, .green)
            case .sweet: (.bordeaux, .gold)
            case .natural: (.burgundy, .olive)
            case .italy: (.burgundy, .brown)
            case .spirit: (.whisky, .amber)
            case .loire: (.burgundy, color == .white ? .olive : .green)
            case .rhone: (.burgundy, .brown)
            case .spain: (.bordeaux, .brown)
            case .portugal: (.bordeaux, pick % 3 == 0 ? .green : .brown)
            case .germany: (.flute, pick % 2 == 0 ? .brown : .green)
            case .newWorld: (.bordeaux, color == .white ? .olive : .green)
            case .sparkling: (.champagne, .green)
            }
            return Style(shape: shape, glass: glass, capsule: look.capsule, look: look, kind: kind)
        }
    }

    enum Shape: Equatable {
        case bordeaux, burgundy, champagne, provence, flute, whisky

        var path: Path {
            switch self {
            case .bordeaux:
                Path { p in
                    p.move(to: CGPoint(x: 42, y: 8)); p.addLine(to: CGPoint(x: 58, y: 8)); p.addLine(to: CGPoint(x: 58, y: 92))
                    p.addCurve(to: CGPoint(x: 82, y: 128), control1: CGPoint(x: 58, y: 104), control2: CGPoint(x: 82, y: 108))
                    p.addLine(to: CGPoint(x: 82, y: 286)); p.addQuadCurve(to: CGPoint(x: 74, y: 294), control: CGPoint(x: 82, y: 294))
                    p.addLine(to: CGPoint(x: 26, y: 294)); p.addQuadCurve(to: CGPoint(x: 18, y: 286), control: CGPoint(x: 18, y: 294))
                    p.addLine(to: CGPoint(x: 18, y: 128))
                    p.addCurve(to: CGPoint(x: 42, y: 92), control1: CGPoint(x: 18, y: 108), control2: CGPoint(x: 42, y: 104))
                    p.closeSubpath()
                }
            case .burgundy:
                Path { p in
                    p.move(to: CGPoint(x: 43, y: 8)); p.addLine(to: CGPoint(x: 57, y: 8)); p.addLine(to: CGPoint(x: 57, y: 70))
                    p.addCurve(to: CGPoint(x: 84, y: 160), control1: CGPoint(x: 57, y: 110), control2: CGPoint(x: 84, y: 130))
                    p.addLine(to: CGPoint(x: 84, y: 286)); p.addQuadCurve(to: CGPoint(x: 76, y: 294), control: CGPoint(x: 84, y: 294))
                    p.addLine(to: CGPoint(x: 24, y: 294)); p.addQuadCurve(to: CGPoint(x: 16, y: 286), control: CGPoint(x: 16, y: 294))
                    p.addLine(to: CGPoint(x: 16, y: 160))
                    p.addCurve(to: CGPoint(x: 43, y: 70), control1: CGPoint(x: 16, y: 130), control2: CGPoint(x: 43, y: 110))
                    p.closeSubpath()
                }
            case .champagne:
                Path { p in
                    p.move(to: CGPoint(x: 40, y: 8)); p.addLine(to: CGPoint(x: 60, y: 8)); p.addLine(to: CGPoint(x: 60, y: 64))
                    p.addCurve(to: CGPoint(x: 86, y: 158), control1: CGPoint(x: 60, y: 108), control2: CGPoint(x: 86, y: 126))
                    p.addLine(to: CGPoint(x: 86, y: 284)); p.addQuadCurve(to: CGPoint(x: 76, y: 294), control: CGPoint(x: 86, y: 294))
                    p.addLine(to: CGPoint(x: 24, y: 294)); p.addQuadCurve(to: CGPoint(x: 14, y: 284), control: CGPoint(x: 14, y: 294))
                    p.addLine(to: CGPoint(x: 14, y: 158))
                    p.addCurve(to: CGPoint(x: 40, y: 64), control1: CGPoint(x: 14, y: 126), control2: CGPoint(x: 40, y: 108))
                    p.closeSubpath()
                }
            case .provence:
                // The waist sits above the label and the body runs straight under it,
                // so the paper is never cut by the glass.
                Path { p in
                    p.move(to: CGPoint(x: 43, y: 8)); p.addLine(to: CGPoint(x: 57, y: 8)); p.addLine(to: CGPoint(x: 57, y: 74))
                    p.addCurve(to: CGPoint(x: 79, y: 138), control1: CGPoint(x: 57, y: 94), control2: CGPoint(x: 79, y: 110))
                    p.addCurve(to: CGPoint(x: 73, y: 180), control1: CGPoint(x: 79, y: 160), control2: CGPoint(x: 73, y: 166))
                    p.addCurve(to: CGPoint(x: 82, y: 228), control1: CGPoint(x: 73, y: 196), control2: CGPoint(x: 82, y: 206))
                    p.addLine(to: CGPoint(x: 82, y: 282)); p.addQuadCurve(to: CGPoint(x: 70, y: 294), control: CGPoint(x: 82, y: 294))
                    p.addLine(to: CGPoint(x: 30, y: 294)); p.addQuadCurve(to: CGPoint(x: 18, y: 282), control: CGPoint(x: 18, y: 294))
                    p.addLine(to: CGPoint(x: 18, y: 228))
                    p.addCurve(to: CGPoint(x: 27, y: 180), control1: CGPoint(x: 18, y: 206), control2: CGPoint(x: 27, y: 196))
                    p.addCurve(to: CGPoint(x: 21, y: 138), control1: CGPoint(x: 27, y: 166), control2: CGPoint(x: 21, y: 160))
                    p.addCurve(to: CGPoint(x: 43, y: 74), control1: CGPoint(x: 21, y: 110), control2: CGPoint(x: 43, y: 94))
                    p.closeSubpath()
                }
            case .flute:
                Path { p in
                    p.move(to: CGPoint(x: 44, y: 8)); p.addLine(to: CGPoint(x: 56, y: 8)); p.addLine(to: CGPoint(x: 56, y: 78))
                    p.addCurve(to: CGPoint(x: 70, y: 175), control1: CGPoint(x: 56, y: 120), control2: CGPoint(x: 70, y: 140))
                    p.addLine(to: CGPoint(x: 70, y: 286)); p.addQuadCurve(to: CGPoint(x: 62, y: 294), control: CGPoint(x: 70, y: 294))
                    p.addLine(to: CGPoint(x: 38, y: 294)); p.addQuadCurve(to: CGPoint(x: 30, y: 286), control: CGPoint(x: 30, y: 294))
                    p.addLine(to: CGPoint(x: 30, y: 175))
                    p.addCurve(to: CGPoint(x: 44, y: 78), control1: CGPoint(x: 30, y: 140), control2: CGPoint(x: 44, y: 120))
                    p.closeSubpath()
                }
            case .whisky:
                Path { p in
                    p.move(to: CGPoint(x: 41, y: 8)); p.addLine(to: CGPoint(x: 59, y: 8)); p.addLine(to: CGPoint(x: 59, y: 62))
                    p.addCurve(to: CGPoint(x: 84, y: 102), control1: CGPoint(x: 59, y: 80), control2: CGPoint(x: 84, y: 82))
                    p.addLine(to: CGPoint(x: 84, y: 288)); p.addQuadCurve(to: CGPoint(x: 78, y: 294), control: CGPoint(x: 84, y: 294))
                    p.addLine(to: CGPoint(x: 22, y: 294)); p.addQuadCurve(to: CGPoint(x: 16, y: 288), control: CGPoint(x: 16, y: 294))
                    p.addLine(to: CGPoint(x: 16, y: 102))
                    p.addCurve(to: CGPoint(x: 41, y: 62), control1: CGPoint(x: 16, y: 82), control2: CGPoint(x: 41, y: 80))
                    p.closeSubpath()
                }
            }
        }

        var capsuleHeight: CGFloat {
            switch self {
            case .bordeaux: 58
            case .burgundy: 52
            case .champagne: 92
            case .provence: 56
            case .flute: 64
            case .whisky: 34
            }
        }

        /// Where the first reflection runs down the glass.
        var shineX: CGFloat { self == .flute ? 35 : 27 }

        /// Where the paper label sits, in the 100 × 300 drawing space.
        var label: CGRect {
            switch self {
            case .bordeaux: CGRect(x: 19, y: 148, width: 62, height: 110)
            case .burgundy: CGRect(x: 17, y: 166, width: 66, height: 100)
            case .champagne: CGRect(x: 15, y: 166, width: 70, height: 100)
            case .provence: CGRect(x: 24, y: 206, width: 52, height: 74)
            case .flute: CGRect(x: 30, y: 192, width: 40, height: 82)
            case .whisky: CGRect(x: 16, y: 138, width: 68, height: 116)
            }
        }
    }

    enum Glass: Equatable {
        case green, olive, brown, pink, gold, amber

        /// Clear glass shows the wine through it, lightened.
        var isClear: Bool { [.pink, .gold, .amber].contains(self) }

        var gradient: Gradient {
            let colors: [UInt32] = switch self {
            case .green: [0x0A140D, 0x182E1E, 0xA5B0A8, 0x1F3A26, 0x15281A, 0x09110B]
            case .olive: [0x19190A, 0x3B3B18, 0xB6B6A5, 0x4A4A1E, 0x333315, 0x161609]
            case .brown: [0x190E06, 0x3B210E, 0xB6A9A0, 0x4A2A12, 0x331D0C, 0x160C05]
            case .pink: [0x55393B, 0xC28287, 0xF7C3C7, 0xF3A3A9, 0xAA7276, 0x483032]
            case .gold: [0x4A300A, 0xB07A1E, 0xF3D58A, 0xE2A83E, 0x9A6516, 0x3E2808]
            case .amber: [0x3A1E06, 0x9A5414, 0xE9B97A, 0xC77A26, 0x80430C, 0x2E1704]
            }
            return Gradient(stops: zip(colors, [0, 0.16, 0.3, 0.42, 0.78, 1]).map {
                .init(color: Color(hex: $0), location: $1)
            })
        }
    }

    enum Capsule: Equatable {
        case black, bordeaux, cream, gold, white, bronze, champagne, pink, wood, navy, green, terracotta

        var gradient: Gradient {
            let colors: [UInt32] = switch self {
            case .black: [0x0D0D0D, 0x8E8E8F, 0x1D1D1F, 0x0B0B0C]
            case .bordeaux: [0x360B0F, 0xBC8C90, 0x7A1A22, 0x300A0D]
            case .cream: [0x615E58, 0xEBE9E1, 0xD8D3C4, 0x56544E]
            case .gold: [0x5A4923, 0xE4D1A6, 0xC9A34E, 0x50411F]
            case .white: [0x686660, 0xF3F1EA, 0xE8E4D6, 0x5C5B55]
            case .bronze: [0x4F3E1B, 0xD7C49D, 0xB08A3C, 0x463718]
            case .champagne: [0x605128, 0xEBD9AC, 0xD7B45A, 0x564824]
            case .pink: [0x614B48, 0xEBD3CF, 0xD8A7A0, 0x564240]
            case .wood: [0x2A1A0E, 0x9A7454, 0x5A3A22, 0x24160B]
            case .navy: [0x0B1020, 0x8A90A6, 0x1C2440, 0x090D1A]
            case .green: [0x0E2414, 0x7FA088, 0x24502E, 0x0B1D10]
            case .terracotta: [0x4A1A0E, 0xD99A80, 0xA8442A, 0x40160B]
            }
            return Gradient(stops: zip(colors, [0, 0.3, 0.55, 1]).map {
                .init(color: Color(hex: $0), location: $1)
            })
        }
    }
}

// MARK: - Backdrop

/// The dark tinted ground a bottle stands on, after the wine's colour: deep red, old
/// gold, faded pink, or amber for what is not wine.
struct BottleBackdrop: View {
    let beverageType: BeverageType
    let color: WineColor?

    var body: some View {
        let (center, edge) = Self.tones(beverageType: beverageType, color: color)
        EllipticalGradient(
            colors: [center, edge],
            center: UnitPoint(x: 0.5, y: 0.3),
            startRadiusFraction: 0,
            endRadiusFraction: 0.8
        )
    }

    static func tones(beverageType: BeverageType, color: WineColor?) -> (Color, Color) {
        guard beverageType == .wine else { return (Color(hex: 0x5A3A1E), Color(hex: 0x170D05)) }
        return switch color {
        case .white: (Color(hex: 0x6B5A24), Color(hex: 0x1C1606))
        case .rosé: (Color(hex: 0x6E3440), Color(hex: 0x1F0B10))
        case .red, nil: (Color(hex: 0x5A1622), Color(hex: 0x16060A))
        }
    }
}

#Preview("Families") {
    HStack(alignment: .bottom, spacing: 12) {
        BottleArtwork(style: .of(id: "1", beverageType: .wine, subtype: nil, color: .red), producer: "Château Margaux", name: "Pavillon Rouge", vintage: 2015, height: 250)
        BottleArtwork(style: .of(id: "2", beverageType: .wine, subtype: nil, color: .white), producer: "Domaine Roulot", name: "Meursault Les Charmes", vintage: 2020, height: 250)
        BottleArtwork(style: .of(id: "3", beverageType: .wine, subtype: .sparkling, color: .white), producer: "Pierre Péters", name: "Blanc de Blancs", vintage: 2017, height: 250)
        BottleArtwork(style: .of(id: "4", beverageType: .wine, subtype: nil, color: .rosé), producer: "Domaine Tempier", name: "Bandol", vintage: 2023, height: 250)
    }
    .padding()
    .background(BottleBackdrop(beverageType: .wine, color: .red))
}

extension Color {
    /// A colour written as `0xRRGGBB`, the way the board's artboards spell them.
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
