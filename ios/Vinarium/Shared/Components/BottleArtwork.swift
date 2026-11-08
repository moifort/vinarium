import SwiftUI

/// A whole bottle drawn with its label written on it: the producer in small capitals,
/// a rule, the name and the vintage. The shape follows the family (a Bordeaux for a
/// red, a Burgundy for a white, a Champagne for a sparkling wine, a Provence flute
/// for a rosé), the glass and the capsule take the wine's tint. Drawn in a 100 × 300
/// space scaled to `height`, so the label stays sharp at every size.
struct BottleArtwork: View {
    let style: Style
    let producer: String?
    let name: String
    let vintage: Int?
    let height: CGFloat

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
        // The paper label.
        let label = shape.label
        inside.fill(Path(label), with: .linearGradient(
            Gradient(stops: [
                .init(color: Color(hex: 0xB4B0A7), location: 0),
                .init(color: Color(hex: 0xF4EFE2), location: 0.22),
                .init(color: Color(hex: 0xF4EFE2), location: 0.72),
                .init(color: Color(hex: 0x9C9890), location: 1),
            ]),
            startPoint: CGPoint(x: label.minX, y: 0),
            endPoint: CGPoint(x: label.maxX, y: 0)
        ))
        writeLabel(in: label, context: &inside)
        // Two reflections running down the glass.
        let shine = Gradient(stops: [
            .init(color: .white.opacity(0), location: 0),
            .init(color: .white.opacity(0.5), location: 0.25),
            .init(color: .white.opacity(0.22), location: 0.8),
            .init(color: .white.opacity(0), location: 1),
        ])
        for (rect, opacity) in [
            (CGRect(x: 27, y: shape.capsuleHeight + 8, width: 7, height: 288 - shape.capsuleHeight - 8), 0.9),
            (CGRect(x: 38, y: shape.capsuleHeight + 30, width: 2.5, height: 250 - shape.capsuleHeight - 30), 0.5),
        ] {
            var reflection = inside
            reflection.opacity = opacity
            reflection.fill(
                Path(roundedRect: rect, cornerRadius: rect.width / 2),
                with: .linearGradient(shine, startPoint: CGPoint(x: 0, y: rect.minY), endPoint: CGPoint(x: 0, y: rect.maxY))
            )
        }
    }

    /// The producer, a rule, the name on up to three lines and the vintage, each line
    /// centred, the block centred in the label. A word too wide for the label, or a
    /// name too long for three lines, sets the name smaller.
    private func writeLabel(in label: CGRect, context: inout GraphicsContext) {
        let width = label.width - 8
        let ink = Color(hex: 0x2B2620)

        var producerLine: GraphicsContext.ResolvedText?
        if let producer {
            let base: CGFloat = label.width < 50 ? 3.4 : 4.6
            func resolved(_ size: CGFloat) -> GraphicsContext.ResolvedText {
                context.resolve(
                    Text(producer.uppercased())
                        .font(.system(size: size, weight: .semibold))
                        .tracking(size * 0.15)
                        .foregroundStyle(Color(hex: 0x6B6150))
                )
            }
            let natural = resolved(base).measure(in: .init(width: CGFloat.infinity, height: 20)).width
            producerLine = resolved(natural > width ? max(base * width / natural, 2.4) : base)
        }

        let (nameLines, nameSize) = wrappedName(width: width, context: context)
        let resolvedName = nameLines.map {
            context.resolve(Text(verbatim: $0).font(.system(size: nameSize, weight: .bold)).foregroundStyle(ink))
        }
        let nameLineHeight = nameSize * 1.2
        let vintageLine = vintage.map {
            context.resolve(Text(verbatim: String($0)).font(.system(size: 8.5, weight: .semibold)).foregroundStyle(ink))
        }

        let producerHeight: CGFloat = producerLine == nil ? 0 : (label.width < 50 ? 4 : 5.5) + 5.5 + 0.7 + 4.5
        let vintageHeight: CGFloat = vintageLine == nil ? 0 : 2 + 10
        let total = producerHeight + CGFloat(nameLines.count) * nameLineHeight + vintageHeight
        var y = label.midY - total / 2

        if let producerLine {
            context.draw(producerLine, at: CGPoint(x: label.midX, y: y), anchor: .top)
            y += (label.width < 50 ? 4 : 5.5) + 5.5
            let ruleWidth = min(label.width * 0.35, 23)
            context.fill(
                Path(CGRect(x: label.midX - ruleWidth / 2, y: y, width: ruleWidth, height: 0.7)),
                with: .color(Color(hex: 0x8A8070))
            )
            y += 0.7 + 4.5
        }
        for line in resolvedName {
            context.draw(line, at: CGPoint(x: label.midX, y: y), anchor: .top)
            y += nameLineHeight
        }
        if let vintageLine {
            context.draw(vintageLine, at: CGPoint(x: label.midX, y: y + 2), anchor: .top)
        }
    }

    /// The name broken into at most three lines at the largest size that holds it,
    /// the last line cut short when even the smallest does not.
    private func wrappedName(width: CGFloat, context: GraphicsContext) -> ([String], CGFloat) {
        let words = name.split(separator: " ").map(String.init)
        func measure(_ text: String, _ size: CGFloat) -> CGFloat {
            context.resolve(Text(verbatim: text).font(.system(size: size, weight: .bold)))
                .measure(in: .init(width: CGFloat.infinity, height: 40)).width
        }
        func wrap(_ size: CGFloat) -> [String]? {
            var lines: [String] = []
            var current = ""
            for word in words {
                guard measure(word, size) <= width else { return nil }
                let candidate = current.isEmpty ? word : current + " " + word
                if measure(candidate, size) <= width {
                    current = candidate
                } else {
                    lines.append(current)
                    current = word
                }
            }
            if !current.isEmpty { lines.append(current) }
            return lines
        }
        for size in stride(from: 8.2, through: 5.6, by: -0.65) {
            if let lines = wrap(size), lines.count <= 3 { return (lines, size) }
        }
        let size: CGFloat = 5.6
        var lines = wrap(size) ?? [name]
        if lines.count > 3 {
            lines = Array(lines.prefix(3))
            lines[2] += "…"
        }
        return (lines, size)
    }
}

// MARK: - Style

extension BottleArtwork {
    struct Style: Equatable {
        let shape: Shape
        let glass: Glass
        let capsule: Capsule

        /// The bottle a wine is drawn in. The capsule colour is picked from the
        /// wine's id, so a wine always wears the same one.
        static func of(
            id: String,
            beverageType: BeverageType,
            subtype: BeverageSubtype?,
            color: WineColor?
        ) -> Style {
            let pick = abs(id.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) })
            guard beverageType == .wine else {
                return Style(shape: .bordeaux, glass: .brown, capsule: [.black, .bronze][pick % 2])
            }
            if subtype == .sparkling {
                return Style(shape: .champagne, glass: .green, capsule: .champagne)
            }
            switch color {
            case .rosé:
                return Style(shape: .provence, glass: .pink, capsule: .pink)
            case .white:
                return Style(shape: .burgundy, glass: pick % 3 == 0 ? .green : .olive, capsule: [.gold, .cream, .white, .bronze][pick % 4])
            case .red, nil:
                return Style(shape: .bordeaux, glass: pick % 4 == 0 ? .brown : .green, capsule: [.black, .bordeaux][pick % 2])
            }
        }
    }

    enum Shape: Equatable {
        case bordeaux, burgundy, champagne, provence

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
                Path { p in
                    p.move(to: CGPoint(x: 43, y: 8)); p.addLine(to: CGPoint(x: 57, y: 8)); p.addLine(to: CGPoint(x: 57, y: 80))
                    p.addCurve(to: CGPoint(x: 80, y: 150), control1: CGPoint(x: 57, y: 100), control2: CGPoint(x: 80, y: 120))
                    p.addCurve(to: CGPoint(x: 72, y: 215), control1: CGPoint(x: 80, y: 175), control2: CGPoint(x: 70, y: 190))
                    p.addCurve(to: CGPoint(x: 82, y: 280), control1: CGPoint(x: 74, y: 240), control2: CGPoint(x: 82, y: 255))
                    p.addQuadCurve(to: CGPoint(x: 70, y: 294), control: CGPoint(x: 82, y: 294))
                    p.addLine(to: CGPoint(x: 30, y: 294)); p.addQuadCurve(to: CGPoint(x: 18, y: 280), control: CGPoint(x: 18, y: 294))
                    p.addCurve(to: CGPoint(x: 28, y: 215), control1: CGPoint(x: 18, y: 255), control2: CGPoint(x: 26, y: 240))
                    p.addCurve(to: CGPoint(x: 20, y: 150), control1: CGPoint(x: 30, y: 190), control2: CGPoint(x: 20, y: 175))
                    p.addCurve(to: CGPoint(x: 43, y: 80), control1: CGPoint(x: 20, y: 120), control2: CGPoint(x: 43, y: 100))
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
            }
        }

        /// Where the paper label sits, in the 100 × 300 drawing space.
        var label: CGRect {
            switch self {
            case .bordeaux: CGRect(x: 19, y: 150, width: 62, height: 106)
            case .burgundy: CGRect(x: 17, y: 166, width: 66, height: 98)
            case .champagne: CGRect(x: 15, y: 170, width: 70, height: 94)
            case .provence: CGRect(x: 27, y: 222, width: 46, height: 54)
            }
        }
    }

    enum Glass: Equatable {
        case green, olive, brown, pink

        /// Clear glass shows the wine through it, lightened.
        var isClear: Bool { self == .pink }

        var gradient: Gradient {
            let colors: [UInt32] = switch self {
            case .green: [0x0A140D, 0x182E1E, 0xA5B0A8, 0x1F3A26, 0x15281A, 0x09110B]
            case .olive: [0x19190A, 0x3B3B18, 0xB6B6A5, 0x4A4A1E, 0x333315, 0x161609]
            case .brown: [0x190E06, 0x3B210E, 0xB6A9A0, 0x4A2A12, 0x331D0C, 0x160C05]
            case .pink: [0x55393B, 0xC28287, 0xF7C3C7, 0xF3A3A9, 0xAA7276, 0x483032]
            }
            return Gradient(stops: zip(colors, [0, 0.16, 0.3, 0.42, 0.78, 1]).map {
                .init(color: Color(hex: $0), location: $1)
            })
        }
    }

    enum Capsule: Equatable {
        case black, bordeaux, cream, gold, white, bronze, champagne, pink

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

    /// The flat colour of a card carrying this wine, a shade of its backdrop.
    static func cardColor(beverageType: BeverageType, color: WineColor?) -> Color {
        guard beverageType == .wine else { return Color(hex: 0x2C1A12) }
        return switch color {
        case .white: Color(hex: 0x2E2810)
        case .rosé: Color(hex: 0x3D1A24)
        case .red, nil: Color(hex: 0x3B1220)
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
