import SwiftUI

// The paper label of a drawn bottle, in the house style of the wine's family: a
// framed château label for a Bordeaux, a sober domaine label for a Burgundy, a
// shield for a Champagne, and so on, as validated on the board ("Étiquettes de la
// bouteille"). Each family comes in six looks, picked from the wine's id, so a
// wine always wears the same label and two neighbours rarely match. Everything is
// drawn in the 100 × 300 space of `BottleArtwork`, in label units: the fine
// mentions only read at large sizes, the layout and type carry the rest.

extension BottleArtwork {
    /// The house style a label is drawn in, as the API names it.
    enum LabelFamily: String, Codable, CaseIterable, Sendable {
        case chateau, burgundy, champagne, provence, south, alsace, sweet, natural, italy, spirit

        /// The family when the API sent none, as a dashboard cached before it did:
        /// what the wine says of itself here is enough for the broad strokes.
        static func guess(beverageType: BeverageType, subtype: BeverageSubtype?, color: WineColor?) -> LabelFamily {
            guard beverageType == .wine else { return .spirit }
            switch subtype {
            case .sparkling: return .champagne
            case .sweet, .lateHarvest, .porto, .fortified: return .sweet
            default: break
            }
            return switch color {
            case .rosé: .provence
            case .white: .burgundy
            case .red, nil: .chateau
            }
        }
    }

    /// One look of a family: the paper, the ink, the accent, a fourth colour the
    /// family uses its own way (the sun, the band, the stamp, the disc, the neck
    /// band), and for the château its emblem and frame.
    struct LabelLook: Equatable {
        enum Emblem: Equatable { case castle, crest, none }

        let family: LabelFamily
        let paper: UInt32
        let ink: UInt32
        let accent: UInt32
        let mark: UInt32
        let capsule: Capsule
        var emblem: Emblem = .none
        var framed = true
        var banded = false
        /// An old vintage: the paper yellowed and foxed.
        var aged = false

        /// The six looks of each family, in the order the wine's id picks them.
        static func looks(of family: LabelFamily) -> [LabelLook] {
            func look(_ paper: UInt32, _ ink: UInt32, _ accent: UInt32, _ mark: UInt32, _ capsule: Capsule) -> LabelLook {
                LabelLook(family: family, paper: paper, ink: ink, accent: accent, mark: mark, capsule: capsule)
            }
            switch family {
            case .chateau:
                return [
                    LabelLook(family: family, paper: 0xF3EAD6, ink: 0x3A2C1C, accent: 0xB08A3C, mark: 0, capsule: .bordeaux, emblem: .castle),
                    LabelLook(family: family, paper: 0xFBFAF6, ink: 0x111111, accent: 0x8E8E93, mark: 0, capsule: .black, emblem: .crest),
                    LabelLook(family: family, paper: 0xEDE3CC, ink: 0x5A1620, accent: 0x8A6A30, mark: 0, capsule: .bordeaux, emblem: .castle),
                    LabelLook(family: family, paper: 0x1A1A1C, ink: 0xD7B45A, accent: 0xD7B45A, mark: 0, capsule: .black),
                    LabelLook(family: family, paper: 0xF2ECDF, ink: 0x1C2440, accent: 0x1C2440, mark: 0, capsule: .navy, emblem: .crest, framed: false),
                    LabelLook(family: family, paper: 0xFBFAF6, ink: 0x1A1A1A, accent: 0x9A1B24, mark: 0, capsule: .bordeaux, emblem: .castle, banded: true),
                ]
            case .burgundy:
                return [
                    look(0xF8F5EE, 0x1C1A17, 0x8C1C22, 0, .gold),
                    look(0xFFFFFF, 0x111111, 0x6B6B6B, 0, .white),
                    look(0xF4EEDF, 0x2B2620, 0x7A5A1E, 0, .bronze),
                    look(0xF6F1E4, 0x1C2440, 0x1C2440, 0, .navy),
                    look(0xEFE6D2, 0x3A2C1C, 0x8C1C22, 0, .bordeaux),
                    look(0xFAF7F0, 0x0F3A2A, 0x0F3A2A, 0, .green),
                ]
            case .champagne:
                return [
                    look(0x16181F, 0xD7B45A, 0xD7B45A, 0, .champagne),
                    look(0xF6F1E4, 0x1C1A17, 0x1C1A17, 0, .gold),
                    look(0x0E2A20, 0xD7B45A, 0xD7B45A, 0, .green),
                    look(0xFFFFFF, 0x0B1020, 0x0B1020, 0, .navy),
                    look(0x5A0E18, 0xE8D3A0, 0xE8D3A0, 0, .bordeaux),
                    look(0x1A1A1A, 0xF2F2F2, 0xF2F2F2, 0, .black),
                ]
            case .provence:
                return [
                    look(0xFBF6F0, 0x5A3A36, 0x5A3A36, 0xE9967A, .pink),
                    look(0xFFFFFF, 0x2F4A5A, 0x2F4A5A, 0x9CC3D5, .white),
                    look(0xF7F0E6, 0x6A4A2E, 0x6A4A2E, 0xE8B04A, .cream),
                    look(0xFDF3F1, 0x7A2E3A, 0x7A2E3A, 0xD9677A, .pink),
                    look(0xF4F6F1, 0x3E5A3A, 0x3E5A3A, 0xA8C49A, .cream),
                    look(0xFFFBF5, 0x5A3A36, 0x5A3A36, 0xF2C28A, .gold),
                ]
            case .south:
                return [
                    look(0xD6BC94, 0x241C14, 0x8C2A1E, 0x8C2A1E, .black),
                    look(0xE8DCC4, 0x2B2620, 0x5A1622, 0x5A1622, .bordeaux),
                    look(0xC9B08A, 0x1E1A14, 0x2F3A5A, 0x2F3A5A, .navy),
                    look(0xEFE6D2, 0x3A2C1C, 0xA8442A, 0xA8442A, .terracotta),
                    look(0xDCCDB0, 0x1C2440, 0x8C2A1E, 0x8C2A1E, .black),
                    look(0xE4D2A8, 0x2B2016, 0x4A5A2A, 0x4A5A2A, .green),
                ]
            case .alsace:
                return [
                    look(0xF7F4EC, 0x1C1A17, 0x2F5D3A, 0x2F5D3A, .green),
                    look(0xFFFFFF, 0x111111, 0x1C2440, 0x1C2440, .navy),
                    look(0xF4EEDF, 0x2B2620, 0x8C1C22, 0x8C1C22, .bordeaux),
                    look(0xF7F4EC, 0x1C1A17, 0xB08A3C, 0xB08A3C, .gold),
                    look(0xFAF7F0, 0x2B2620, 0x2B2620, 0x2B2620, .black),
                    look(0xF2F0E8, 0x1C2440, 0x3E6A8A, 0x3E6A8A, .white),
                ]
            case .sweet:
                return [
                    look(0xF1E6C4, 0x3A2C14, 0xA07A24, 0, .gold),
                    look(0xFBF6E8, 0x2B2016, 0xB08A3C, 0, .bronze),
                    look(0x1A1A1C, 0xD7B45A, 0xD7B45A, 0, .gold),
                    look(0xF4EAD2, 0x5A1620, 0xA07A24, 0, .bordeaux),
                    look(0xFFFDF6, 0x1C2440, 0xB08A3C, 0, .cream),
                    look(0xEADBB4, 0x3A2C14, 0x8A6A30, 0, .champagne),
                ]
            case .natural:
                return [
                    look(0xC4532F, 0xFFF6EA, 0xFFF6EA, 0xF0C27A, .terracotta),
                    look(0x2F5D3A, 0xF6F1E4, 0xF6F1E4, 0xF2D27A, .green),
                    look(0xF2D27A, 0x1C1A17, 0x1C1A17, 0xC4532F, .gold),
                    look(0x1C2440, 0xF6F1E4, 0xF6F1E4, 0xE9967A, .navy),
                    look(0xE9E1D0, 0x1C1A17, 0x1C1A17, 0x2F5D3A, .cream),
                    look(0x8C1C22, 0xFFF6EA, 0xFFF6EA, 0xF2C2B0, .bordeaux),
                ]
            case .italy:
                return [
                    look(0xF6F3EC, 0x1F1A17, 0x7A1A22, 0xC9A7C7, .bordeaux),
                    look(0xFFFFFF, 0x111111, 0x2F5D3A, 0x8FB89A, .black),
                    look(0xF1E8D6, 0x2B2016, 0x8C6A2A, 0xC9A7C7, .bronze),
                    look(0x1A1A1C, 0xE8D3A0, 0xE8D3A0, 0x8FB89A, .black),
                    look(0xF4EEDF, 0x1C2440, 0x1C2440, 0xC9A7C7, .navy),
                    look(0xFBF8F0, 0x3A2C1C, 0x9A1B24, 0xD9C27A, .gold),
                ]
            case .spirit:
                return [
                    look(0x141414, 0xD7B45A, 0xD7B45A, 0, .wood),
                    look(0xF2ECDF, 0x1C1A17, 0x1C1A17, 0, .black),
                    look(0x0B1020, 0xE8D3A0, 0xE8D3A0, 0, .navy),
                    look(0x2A1A0E, 0xE9C98A, 0xE9C98A, 0, .wood),
                    look(0xFFFFFF, 0x111111, 0x111111, 0, .black),
                    look(0x0E2414, 0xD7B45A, 0xD7B45A, 0, .green),
                ]
            }
        }
    }

    /// What is written on the label, as the wine gives it.
    struct LabelText {
        let producer: String?
        let name: String
        let vintage: Int?
        let appellation: String?
        let classification: String?
        /// The kind of a spirit or other drink ("Whisky", "Bière"), in its title.
        let kind: String?
    }
}

// MARK: - Drawing

extension BottleArtwork {
    /// Draws the label of `look` in `rect`, then what the family adds on the neck.
    static func drawLabel(_ look: LabelLook, text: LabelText, in rect: CGRect, context: GraphicsContext) {
        let pen = LabelPen(context: context)
        switch look.family {
        case .chateau: chateau(look, text, rect, pen)
        case .burgundy: burgundy(look, text, rect, pen)
        case .champagne: champagne(look, text, rect, pen)
        case .provence: provence(look, text, rect, pen)
        case .south: south(look, text, rect, pen)
        case .alsace: alsace(look, text, rect, pen)
        case .sweet: sweet(look, text, rect, pen)
        case .natural: natural(look, text, rect, pen)
        case .italy: italy(look, text, rect, pen)
        case .spirit: spirit(look, text, rect, pen)
        }
    }

    // MARK: Families

    private static func chateau(_ v: LabelLook, _ t: LabelText, _ r: CGRect, _ pen: LabelPen) {
        let cx = r.midX, ink = Color(hex: v.ink), accent = Color(hex: v.accent)
        pen.paper(r, v)
        if v.framed {
            pen.stroke(Path(r.insetBy(dx: 3, dy: 3)), accent, 0.7)
            pen.stroke(Path(r.insetBy(dx: 4.6, dy: 4.6)), accent, 0.3)
        }
        if v.banded { pen.fill(Path(CGRect(x: r.minX, y: r.maxY - 16, width: r.width, height: 9)), accent) }
        switch v.emblem {
        case .castle: pen.castle(cx: cx, y: r.minY + 12, ink: ink, paper: Color(hex: v.paper))
        case .crest: pen.crest(cx: cx, y: r.minY + 11, ink: ink, scale: 1.1)
        case .none: break
        }
        let (kicker, title) = chateauTitle(t)
        var y = v.emblem == .none ? r.minY + 22 : r.minY + 38
        if let kicker {
            pen.write(kicker.uppercased(), .copperplateBold, 3.4, ink, tracking: 0.9, x: cx, y: y, maxWidth: r.width - 12)
        }
        y += 11
        let (lines, size) = pen.wrap(title, .didotBold, from: 10, to: 6, width: r.width - 12, lines: 2)
        for (i, line) in lines.enumerated() {
            pen.write(line, .didotBold, size, ink, x: cx, y: y + CGFloat(i) * size * 1.02, maxWidth: r.width - 12)
        }
        y += CGFloat(lines.count - 1) * size * 1.02
        if let classification = t.classification {
            pen.write(classification, .baskervilleItalic, 3.1, accent, x: cx, y: y + 7, maxWidth: r.width - 14)
            y += 3
        }
        pen.fill(Path(CGRect(x: cx - 9, y: y + 7.5, width: 18, height: 0.5)), accent)
        if let appellation = t.appellation {
            pen.write(appellation.uppercased(), .copperplateBold, 2.9, ink, tracking: 0.5, x: cx, y: y + 14, maxWidth: r.width - 14)
        }
        if let vintage = t.vintage {
            pen.write(String(vintage), .didotBold, 7, ink, x: cx, y: r.maxY - (v.banded ? 20 : 13))
        }
    }

    /// A château's name set the way its label sets it: "CHÂTEAU" in small capitals
    /// over "Talbot", or the producer over the cuvée when they differ.
    static func chateauTitle(_ t: LabelText) -> (kicker: String?, title: String) {
        if let producer = t.producer { return (producer, t.name) }
        for prefix in ["Château ", "Chateau ", "Castello ", "Castillo "]
        where t.name.lowercased().hasPrefix(prefix.lowercased()) && t.name.count > prefix.count {
            return (String(t.name.prefix(prefix.count - 1)), String(t.name.dropFirst(prefix.count)))
        }
        return (nil, t.name)
    }

    private static func burgundy(_ v: LabelLook, _ t: LabelText, _ r: CGRect, _ pen: LabelPen) {
        let cx = r.midX, ink = Color(hex: v.ink), accent = Color(hex: v.accent)
        pen.paper(r, v)
        if let producer = t.producer {
            pen.write(producer.uppercased(), .systemSemibold, 3, ink, tracking: 0.8, x: cx, y: r.minY + 11, maxWidth: r.width - 14)
        }
        pen.fill(Path(CGRect(x: r.minX + 8, y: r.minY + 15, width: r.width - 16, height: 0.4)), ink.opacity(0.6))
        // The appellation in title and the climat under it in italics, when the name
        // starts with the appellation ("Meursault" / "1er Cru Les Charmes").
        var title = t.name
        var climat = t.appellation.flatMap { t.name.localizedStandardContains($0) ? nil : $0 }
        if let appellation = t.appellation, t.name.lowercased().hasPrefix(appellation.lowercased()) {
            let rest = t.name.dropFirst(appellation.count).trimmingCharacters(in: .whitespaces)
            title = appellation
            climat = rest.isEmpty ? nil : rest
        }
        let (lines, size) = pen.wrap(title.uppercased(), .baskervilleBold, from: 7.6, to: 4.4, width: r.width - 12, lines: 3)
        let lineHeight = size * 1.15
        let block = CGFloat(lines.count) * lineHeight + (climat == nil ? 0 : 8)
        var y = r.minY + 15 + (r.height - 36 - block) / 2 + size
        for line in lines {
            pen.write(line, .baskervilleBold, size, ink, tracking: 0.3, x: cx, y: y, maxWidth: r.width - 12)
            y += lineHeight
        }
        if let climat {
            pen.write(climat, .baskervilleItalic, 5.2, accent, x: cx, y: y + 3, maxWidth: r.width - 12)
        }
        pen.fill(Path(CGRect(x: r.minX + 8, y: r.maxY - 21, width: r.width - 16, height: 0.4)), ink.opacity(0.6))
        if let vintage = t.vintage {
            pen.write(String(vintage), .baskervilleBold, 6, ink, x: r.minX + 8, y: r.maxY - 10, align: .leading)
        }
        if let classification = t.classification {
            pen.write(classification.uppercased(), .systemSemibold, 2.2, accent, tracking: 0.5, x: r.maxX - 8, y: r.maxY - 10.5, align: .trailing, maxWidth: r.width / 2 - 6)
        }
    }

    private static func champagne(_ v: LabelLook, _ t: LabelText, _ r: CGRect, _ pen: LabelPen) {
        let cx = r.midX, ink = Color(hex: v.ink)
        let shield = Path { p in
            p.move(to: CGPoint(x: r.minX + 7, y: r.minY + 4))
            p.addLine(to: CGPoint(x: r.maxX - 7, y: r.minY + 4))
            p.addLine(to: CGPoint(x: r.maxX - 7, y: r.maxY - 30))
            p.addQuadCurve(to: CGPoint(x: cx, y: r.maxY - 3), control: CGPoint(x: r.maxX - 7, y: r.maxY - 10))
            p.addQuadCurve(to: CGPoint(x: r.minX + 7, y: r.maxY - 30), control: CGPoint(x: r.minX + 7, y: r.maxY - 10))
            p.closeSubpath()
        }
        pen.paper(shield, bounds: r, v)
        pen.stroke(shield, ink, 0.8)
        let inner = shield.applying(
            CGAffineTransform(translationX: cx, y: r.midY).scaledBy(x: 0.9, y: 0.9).translatedBy(x: -cx, y: -r.midY)
        )
        pen.stroke(inner, ink, 0.3)
        if let appellation = t.appellation {
            pen.write(appellation.uppercased(), .copperplateBold, 2.6, ink, tracking: 1.1, x: cx, y: r.minY + 17, maxWidth: r.width - 24)
        }
        pen.diamond(cx, r.minY + 21.5, 1, ink)
        let (kicker, title) = t.producer.map { ($0, t.name) } ?? (t.name, nil)
        pen.write(kicker.uppercased(), .copperplateBold, 4.4, ink, tracking: 0.4, x: cx, y: r.minY + 33, maxWidth: r.width - 20)
        if let title {
            let (lines, size) = pen.wrap(title, .didotItalic, from: 6, to: 4.2, width: r.width - 22, lines: 2)
            for (i, line) in lines.enumerated() {
                pen.write(line, .didotItalic, size, ink, x: cx, y: r.minY + 45 + CGFloat(i) * size * 1.1, maxWidth: r.width - 22)
            }
        }
        if let classification = t.classification {
            pen.write(classification, .baskervilleItalic, 2.6, ink.opacity(0.85), x: cx, y: r.minY + 62, maxWidth: r.width - 26)
        }
        // The collar on the neck carries the vintage, or a diamond for a non-vintage.
        let collar = CGRect(x: 0, y: 94, width: 100, height: 15)
        pen.paper(Path(collar), bounds: collar, v)
        pen.fill(Path(CGRect(x: 0, y: 95.5, width: 100, height: 0.4)), ink)
        pen.fill(Path(CGRect(x: 0, y: 107.1, width: 100, height: 0.4)), ink)
        if let vintage = t.vintage {
            pen.write(String(vintage), .didotBold, 5, ink, tracking: 0.4, x: 50, y: 104)
        } else {
            pen.diamond(50, 101.5, 1.6, ink)
        }
    }

    private static func provence(_ v: LabelLook, _ t: LabelText, _ r: CGRect, _ pen: LabelPen) {
        let cx = r.midX, ink = Color(hex: v.ink)
        pen.fill(Path(r), Color(hex: v.paper).opacity(0.82))
        pen.stroke(Path(r.insetBy(dx: 2, dy: 2)), ink.opacity(0.5), 0.3)
        pen.fill(Path(ellipseIn: CGRect(x: cx - 8, y: r.minY + 8, width: 16, height: 16)), Color(hex: v.mark))
        pen.fill(Path(CGRect(x: r.minX + 4, y: r.minY + 22, width: r.width - 8, height: 0.4)), ink.opacity(0.5))
        if let producer = t.producer {
            pen.write(producer.uppercased(), .futuraMedium, 2.5, ink, tracking: 0.9, x: cx, y: r.minY + 32, maxWidth: r.width - 8)
        }
        let (lines, size) = pen.wrap(t.name, .futuraMedium, from: 7.5, to: 4.6, width: r.width - 8, lines: 2)
        for (i, line) in lines.enumerated() {
            pen.write(line, .futuraMedium, size, ink, tracking: 0.2, x: cx, y: r.minY + 43 + CGFloat(i) * size * 1.1, maxWidth: r.width - 8)
        }
        if let appellation = t.appellation, !t.name.localizedStandardContains(appellation) {
            pen.write(appellation, .snellRoundhand, 5.6, ink, x: cx, y: r.minY + 53 + CGFloat(lines.count - 1) * size, maxWidth: r.width - 8)
        }
        if let vintage = t.vintage {
            pen.write(String(vintage), .futuraMedium, 3.4, ink, tracking: 0.6, x: cx, y: r.maxY - 6)
        }
    }

    private static func south(_ v: LabelLook, _ t: LabelText, _ r: CGRect, _ pen: LabelPen) {
        let cx = r.midX, ink = Color(hex: v.ink), stamp = Color(hex: v.mark)
        pen.paper(r, v)
        for i in 0..<14 {
            pen.fill(Path(CGRect(x: r.minX, y: r.minY + 4 + CGFloat(i) * 7, width: r.width, height: 0.25)), ink.opacity(0.06))
        }
        if let producer = t.producer {
            pen.write(producer, .baskervilleItalic, 3.8, ink, x: cx, y: r.minY + 13, maxWidth: r.width - 10)
        }
        pen.diamond(cx - 10, r.minY + 19, 0.9, ink)
        pen.diamond(cx, r.minY + 19, 1.2, ink)
        pen.diamond(cx + 10, r.minY + 19, 0.9, ink)
        let (lines, size) = pen.wrap(t.name.uppercased(), .copperplateBold, from: 8.2, to: 4.6, width: r.width - 10, lines: 3)
        var y = r.minY + 36 - CGFloat(lines.count - 1) * size * 0.5
        for line in lines {
            pen.write(line, .copperplateBold, size, ink, tracking: 0.2, x: cx, y: y, maxWidth: r.width - 10)
            y += size * 1.05
        }
        if let appellation = t.appellation, !t.name.localizedStandardContains(appellation) {
            pen.write(appellation.uppercased(), .systemSemibold, 2, ink.opacity(0.75), tracking: 0.4, x: cx, y: y + 2, maxWidth: r.width - 12)
        }
        let center = CGPoint(x: cx + 14, y: r.maxY - 20)
        pen.stroke(Path(ellipseIn: CGRect(x: center.x - 10, y: center.y - 10, width: 20, height: 20)), stamp, 0.9)
        pen.stroke(Path(ellipseIn: CGRect(x: center.x - 8.2, y: center.y - 8.2, width: 16.4, height: 16.4)), stamp, 0.35)
        if let vintage = t.vintage {
            pen.write(String(vintage), .copperplateBold, 5.4, stamp, x: center.x, y: center.y + 2.2, maxWidth: 15)
        } else {
            pen.diamond(center.x, center.y, 1.6, stamp)
        }
        if let classification = t.classification {
            pen.write(classification, .baskervilleItalic, 2.6, ink.opacity(0.8), x: r.minX + 8, y: r.maxY - 14.5, align: .leading, maxWidth: 24)
        }
    }

    private static func alsace(_ v: LabelLook, _ t: LabelText, _ r: CGRect, _ pen: LabelPen) {
        let cx = r.midX, ink = Color(hex: v.ink), band = Color(hex: v.mark)
        pen.paper(r, v)
        pen.fill(Path(CGRect(x: r.minX, y: r.minY, width: r.width, height: 11)), band)
        if let producer = t.producer {
            pen.write(producer.uppercased(), .systemBold, 2.4, .white, tracking: 0.6, x: cx, y: r.minY + 7.2, maxWidth: r.width - 6)
        }
        if let appellation = t.appellation {
            pen.write(appellation.uppercased(), .copperplateBold, 2.6, band, tracking: 1, x: cx, y: r.minY + 20, maxWidth: r.width - 6)
        }
        let (lines, size) = pen.wrap(t.name, .didotBoldItalic, from: 7.4, to: 4.2, width: r.width - 6, lines: 3)
        var y = r.minY + 36 - CGFloat(lines.count - 1) * size * 0.55
        for line in lines {
            pen.write(line, .didotBoldItalic, size, ink, x: cx, y: y, maxWidth: r.width - 6)
            y += size * 1.1
        }
        if let classification = t.classification {
            pen.write(classification.uppercased(), .systemBold, 2.4, band, tracking: 0.8, x: cx, y: y + 3, maxWidth: r.width - 6)
        }
        pen.fill(Path(CGRect(x: cx - 6, y: r.maxY - 19, width: 12, height: 0.4)), band)
        if let vintage = t.vintage {
            pen.write(String(vintage), .didotBold, 5, ink, x: cx, y: r.maxY - 9)
        }
    }

    private static func sweet(_ v: LabelLook, _ t: LabelText, _ r: CGRect, _ pen: LabelPen) {
        let cx = r.midX, ink = Color(hex: v.ink), accent = Color(hex: v.accent)
        pen.paper(r, v)
        pen.stroke(Path(roundedRect: r.insetBy(dx: 3, dy: 3), cornerRadius: 3), accent, 0.6)
        for corner in [CGPoint(x: r.minX + 3, y: r.minY + 3), CGPoint(x: r.maxX - 3, y: r.minY + 3),
                       CGPoint(x: r.minX + 3, y: r.maxY - 3), CGPoint(x: r.maxX - 3, y: r.maxY - 3)] {
            pen.fill(Path(ellipseIn: CGRect(x: corner.x - 1.6, y: corner.y - 1.6, width: 3.2, height: 3.2)), accent)
        }
        let (kicker, title) = chateauTitle(t)
        if let kicker {
            pen.write(kicker.uppercased(), .copperplateBold, 3.2, ink, tracking: 1, x: cx, y: r.minY + 22, maxWidth: r.width - 12)
        }
        let (lines, size) = pen.wrap(title, .snellRoundhand, from: 12, to: 7, width: r.width - 10, lines: 2)
        var y = r.minY + 43 - CGFloat(lines.count - 1) * size * 0.45
        for line in lines {
            pen.write(line, .snellRoundhand, size, ink, x: cx, y: y, maxWidth: r.width - 10)
            y += size * 0.9
        }
        pen.fill(Path(CGRect(x: cx - 10, y: r.minY + 50, width: 20, height: 0.5)), accent)
        if let appellation = t.appellation {
            pen.write(appellation.uppercased(), .copperplateBold, 3.6, accent, tracking: 0.8, x: cx, y: r.minY + 59, maxWidth: r.width - 12)
        }
        if let classification = t.classification {
            pen.write(classification, .baskervilleItalic, 2.7, ink.opacity(0.8), x: cx, y: r.minY + 65, maxWidth: r.width - 12)
        }
        if let vintage = t.vintage {
            pen.write(String(vintage), .didotBold, 7, ink, x: cx, y: r.maxY - 14)
        }
    }

    private static func natural(_ v: LabelLook, _ t: LabelText, _ r: CGRect, _ pen: LabelPen) {
        let ink = Color(hex: v.ink)
        pen.paper(r, v)
        var inside = pen
        inside.context.clip(to: Path(r))
        inside.fill(Path(ellipseIn: CGRect(x: r.maxX - 28, y: r.minY + 6, width: 40, height: 40)), Color(hex: v.mark))
        if let producer = t.producer {
            pen.write(producer.lowercased(), .futuraMedium, 3, ink, x: r.minX + 7, y: r.minY + 12, align: .leading, maxWidth: r.width - 30)
        }
        let (lines, size) = pen.wrap(t.name, .futuraHeavy, from: 11, to: 6, width: r.width - 12, lines: 3)
        var y = r.minY + 58 - CGFloat(lines.count - 1) * size * 0.95
        for line in lines {
            pen.write(line, .futuraHeavy, size, ink, tracking: -0.4, x: r.minX + 6, y: y, align: .leading, maxWidth: r.width - 12)
            y += size * 0.95
        }
        if let appellation = t.appellation {
            pen.write(appellation.lowercased(), .futuraMedium, 2.6, ink, tracking: 0.3, x: r.minX + 7, y: r.maxY - 9, align: .leading, maxWidth: r.width - 28)
        }
        if let vintage = t.vintage {
            pen.write(String(vintage), .futuraBold, 3.6, ink, x: r.maxX - 7, y: r.maxY - 9, align: .trailing)
        }
    }

    private static func italy(_ v: LabelLook, _ t: LabelText, _ r: CGRect, _ pen: LabelPen) {
        let cx = r.midX, ink = Color(hex: v.ink), accent = Color(hex: v.accent)
        pen.paper(r, v)
        pen.crest(cx: cx, y: r.minY + 8, ink: accent, scale: 1.1)
        let (lines, size) = pen.wrap(t.name.uppercased(), .didotBold, from: 9, to: 4.6, width: r.width - 10, lines: 2)
        var y = r.minY + 36 - CGFloat(lines.count - 1) * size * 0.6
        for line in lines {
            pen.write(line, .didotBold, size, ink, tracking: 0.6, x: cx, y: y, maxWidth: r.width - 10)
            y += size * 1.1
        }
        if let appellation = t.appellation, !t.name.localizedStandardContains(appellation) {
            pen.write(appellation.uppercased(), .systemRegular, 1.8, ink.opacity(0.75), tracking: 0.3, x: cx, y: r.minY + 43, maxWidth: r.width - 10)
        } else if let classification = t.classification {
            pen.write(classification.uppercased(), .systemRegular, 1.8, ink.opacity(0.75), tracking: 0.3, x: cx, y: r.minY + 43, maxWidth: r.width - 10)
        }
        pen.fill(Path(CGRect(x: cx - 12, y: r.minY + 47, width: 24, height: 0.4)), accent)
        if let producer = t.producer {
            pen.write(producer, .baskervilleItalic, 4, ink, x: cx, y: r.minY + 56, maxWidth: r.width - 10)
        }
        if let vintage = t.vintage {
            pen.write(String(vintage), .didotBold, 5.4, accent, x: cx, y: r.maxY - 11)
        }
        // The band over the capsule, the way a DOCG seals the neck.
        let band = CGRect(x: 46.5, y: 30, width: 7, height: 26)
        pen.fill(Path(band), Color(hex: v.mark))
        pen.stroke(Path(band), .black.opacity(0.15), 0.3)
    }

    private static func spirit(_ v: LabelLook, _ t: LabelText, _ r: CGRect, _ pen: LabelPen) {
        let cx = r.midX, ink = Color(hex: v.ink)
        pen.paper(r, v)
        pen.stroke(Path(r.insetBy(dx: 4, dy: 4)), ink, 0.5)
        if let kind = t.kind {
            pen.write(kind.uppercased(), .copperplateBold, 3, ink, tracking: 1.2, x: cx, y: r.minY + 18, maxWidth: r.width - 14)
        }
        pen.fill(Path(CGRect(x: cx - 14, y: r.minY + 22, width: 28, height: 0.4)), ink)
        let (title, subtitle) = t.producer.map { ($0, Optional(t.name)) } ?? (t.name, nil)
        let (lines, size) = pen.wrap(title.uppercased(), .didotBold, from: 8, to: 4.8, width: r.width - 14, lines: 2)
        var y = r.minY + 42 - CGFloat(lines.count - 1) * size * 0.6
        for line in lines {
            pen.write(line, .didotBold, size, ink, tracking: 0.4, x: cx, y: y, maxWidth: r.width - 14)
            y += size * 1.1
        }
        if let subtitle {
            let (sub, subSize) = pen.wrap(subtitle, .baskervilleItalic, from: 3.6, to: 2.6, width: r.width - 14, lines: 2)
            for (i, line) in sub.enumerated() {
                pen.write(line, .baskervilleItalic, subSize, ink, x: cx, y: y + 2.5 + CGFloat(i) * subSize * 1.2, maxWidth: r.width - 14)
            }
        }
        let center = CGPoint(x: cx, y: r.minY + 80)
        pen.stroke(Path(ellipseIn: CGRect(x: center.x - 11, y: center.y - 11, width: 22, height: 22)), ink, 0.6)
        if let vintage = t.vintage {
            pen.write(String(vintage), .didotBold, 5.6, ink, x: center.x, y: center.y + 2, maxWidth: 19)
        } else {
            pen.diamond(center.x, center.y, 2, ink)
        }
    }
}

// MARK: - Pen

/// The drawing tools the label families share, on a context in label units.
struct LabelPen {
    var context: GraphicsContext

    enum Face {
        case didotBold, didotItalic, didotBoldItalic, baskervilleBold, baskervilleItalic, snellRoundhand
        case copperplateBold, futuraMedium, futuraBold, futuraHeavy
        case systemRegular, systemSemibold, systemBold

        func font(_ size: CGFloat) -> Font {
            switch self {
            case .didotBold: .custom("Didot-Bold", fixedSize: size)
            case .didotItalic: .custom("Didot-Italic", fixedSize: size)
            case .didotBoldItalic: .custom("Didot-Bold", fixedSize: size).italic()
            case .baskervilleBold: .custom("Baskerville-Bold", fixedSize: size)
            case .baskervilleItalic: .custom("Baskerville-Italic", fixedSize: size)
            case .snellRoundhand: .custom("SnellRoundhand", fixedSize: size)
            case .copperplateBold: .custom("Copperplate-Bold", fixedSize: size)
            case .futuraMedium: .custom("Futura-Medium", fixedSize: size)
            case .futuraBold: .custom("Futura-Bold", fixedSize: size)
            case .futuraHeavy: .custom("Futura-CondensedExtraBold", fixedSize: size)
            case .systemRegular: .system(size: size)
            case .systemSemibold: .system(size: size, weight: .semibold)
            case .systemBold: .system(size: size, weight: .bold)
            }
        }
    }

    enum Align { case leading, center, trailing }

    func fill(_ path: Path, _ color: Color) {
        context.fill(path, with: .color(color))
    }

    func stroke(_ path: Path, _ color: Color, _ width: CGFloat) {
        context.stroke(path, with: .color(color), lineWidth: width)
    }

    /// Paper over `rect`, darker at both edges so it wraps around the glass; an
    /// old vintage yellows and foxes it.
    func paper(_ rect: CGRect, _ look: BottleArtwork.LabelLook) {
        paper(Path(rect), bounds: rect, look)
    }

    func paper(_ path: Path, bounds: CGRect, _ look: BottleArtwork.LabelLook) {
        let mid = look.paper
        context.fill(path, with: .linearGradient(
            Gradient(stops: [
                .init(color: Color(hex: Self.shade(mid, 0.72)), location: 0),
                .init(color: Color(hex: mid), location: 0.22),
                .init(color: Color(hex: mid), location: 0.72),
                .init(color: Color(hex: Self.shade(mid, 0.62)), location: 1),
            ]),
            startPoint: CGPoint(x: bounds.minX, y: 0),
            endPoint: CGPoint(x: bounds.maxX, y: 0)
        ))
        guard look.aged else { return }
        var foxed = context
        foxed.clip(to: path)
        for (dx, dy, radius) in [(8.0, 14.0, 2.4), (50, 22, 1.6), (12, 90, 3), (46, 84, 2), (30, 100, 1.4), (54, 60, 1.2)] {
            let spot = CGRect(x: bounds.minX + dx - radius, y: bounds.minY + dy - radius, width: radius * 2, height: radius * 2)
            foxed.fill(Path(ellipseIn: spot), with: .color(Color(hex: 0x8A6A30).opacity(0.16)))
        }
        foxed.fill(path, with: .color(Color(hex: 0xA07A30).opacity(0.08)))
    }

    /// `text` on the baseline `y`, the way the board's SVG sets it, shrunk to
    /// `maxWidth` when it is wider.
    func write(
        _ text: String, _ face: Face, _ size: CGFloat, _ color: Color, tracking: CGFloat = 0,
        x: CGFloat, y: CGFloat, align: Align = .center, maxWidth: CGFloat? = nil
    ) {
        var resolved = resolve(text, face, size, color, tracking: tracking)
        var bounds = resolved.measure(in: CGSize(width: CGFloat.infinity, height: .infinity))
        if let maxWidth, bounds.width > maxWidth, bounds.width > 0 {
            let ratio = maxWidth / bounds.width
            resolved = resolve(text, face, size * ratio, color, tracking: tracking * ratio)
            bounds = resolved.measure(in: CGSize(width: CGFloat.infinity, height: .infinity))
        }
        guard bounds.height > 0 else { return }
        let baseline = resolved.firstBaseline(in: bounds)
        let anchorX: CGFloat = switch align {
        case .leading: 0
        case .center: 0.5
        case .trailing: 1
        }
        context.draw(resolved, at: CGPoint(x: x, y: y), anchor: UnitPoint(x: anchorX, y: baseline / bounds.height))
    }

    /// `text` broken into at most `lines` lines at the largest size between `from`
    /// and `to` that holds it; past the smallest, the last line takes the rest and
    /// `write` shrinks it to fit.
    func wrap(_ text: String, _ face: Face, from: CGFloat, to: CGFloat, width: CGFloat, lines maxLines: Int) -> ([String], CGFloat) {
        let words = text.split(separator: " ").map(String.init)
        func measure(_ string: String, _ size: CGFloat) -> CGFloat {
            resolve(string, face, size, .black, tracking: 0).measure(in: CGSize(width: CGFloat.infinity, height: .infinity)).width
        }
        func split(_ size: CGFloat) -> [String] {
            var lines: [String] = []
            var current = ""
            for word in words {
                let candidate = current.isEmpty ? word : current + " " + word
                if current.isEmpty || measure(candidate, size) <= width {
                    current = candidate
                } else {
                    lines.append(current)
                    current = word
                }
            }
            if !current.isEmpty { lines.append(current) }
            return lines
        }
        var size = from
        while size >= to {
            let lines = split(size)
            if lines.count <= maxLines, lines.allSatisfy({ measure($0, size) <= width }) { return (lines, size) }
            size -= max((from - to) / 6, 0.2)
        }
        var lines = split(to)
        if lines.count > maxLines {
            lines = Array(lines.prefix(maxLines - 1)) + [lines.dropFirst(maxLines - 1).joined(separator: " ")]
        }
        return (lines, to)
    }

    func diamond(_ x: CGFloat, _ y: CGFloat, _ radius: CGFloat, _ color: Color) {
        fill(Path { p in
            p.move(to: CGPoint(x: x, y: y - radius))
            p.addLine(to: CGPoint(x: x + radius, y: y))
            p.addLine(to: CGPoint(x: x, y: y + radius))
            p.addLine(to: CGPoint(x: x - radius, y: y))
            p.closeSubpath()
        }, color)
    }

    /// The château drawn at the head of a Bordeaux label: a keep between two towers.
    func castle(cx: CGFloat, y: CGFloat, ink: Color, paper: Color) {
        var c = context
        c.translateBy(x: cx - 13, y: y)
        c.opacity = 0.8
        let rects = [CGRect(x: 3, y: 8, width: 20, height: 6), CGRect(x: 10, y: 3, width: 6, height: 11),
                     CGRect(x: 3, y: 5, width: 3.5, height: 9), CGRect(x: 19.5, y: 5, width: 3.5, height: 9),
                     CGRect(x: 0, y: 14, width: 26, height: 0.5)]
        for rect in rects { c.fill(Path(rect), with: .color(ink)) }
        for (left, top, right) in [((9.5, 3.2), (13.0, 0.0), (16.5, 3.2)), ((2.6, 5.2), (4.75, 2.2), (6.9, 5.2)),
                                   ((19.1, 5.2), (21.25, 2.2), (23.4, 5.2))] {
            c.fill(Path { p in
                p.move(to: CGPoint(x: left.0, y: left.1))
                p.addLine(to: CGPoint(x: top.0, y: top.1))
                p.addLine(to: CGPoint(x: right.0, y: right.1))
                p.closeSubpath()
            }, with: .color(ink))
        }
        c.fill(Path(CGRect(x: 12.2, y: 9, width: 1.6, height: 5)), with: .color(paper.opacity(0.7)))
    }

    /// A crowned shield with a chevron.
    func crest(cx: CGFloat, y: CGFloat, ink: Color, scale: CGFloat) {
        var c = context
        c.translateBy(x: cx - 5 * scale, y: y)
        c.scaleBy(x: scale, y: scale)
        c.fill(Path { p in
            p.move(to: CGPoint(x: 1, y: 3)); p.addLine(to: CGPoint(x: 3, y: 0)); p.addLine(to: CGPoint(x: 5, y: 2.4))
            p.addLine(to: CGPoint(x: 7, y: 0)); p.addLine(to: CGPoint(x: 9, y: 3)); p.closeSubpath()
        }, with: .color(ink))
        c.stroke(Path { p in
            p.move(to: CGPoint(x: 0, y: 4)); p.addLine(to: CGPoint(x: 10, y: 4)); p.addLine(to: CGPoint(x: 10, y: 9))
            p.addQuadCurve(to: CGPoint(x: 5, y: 15), control: CGPoint(x: 10, y: 13))
            p.addQuadCurve(to: CGPoint(x: 0, y: 9), control: CGPoint(x: 0, y: 13))
            p.closeSubpath()
        }, with: .color(ink), lineWidth: 0.7)
        c.stroke(Path { p in
            p.move(to: CGPoint(x: 1.5, y: 6.5)); p.addLine(to: CGPoint(x: 5, y: 9.5)); p.addLine(to: CGPoint(x: 8.5, y: 6.5))
        }, with: .color(ink), lineWidth: 0.6)
    }

    private func resolve(_ text: String, _ face: Face, _ size: CGFloat, _ color: Color, tracking: CGFloat) -> GraphicsContext.ResolvedText {
        context.resolve(Text(verbatim: text).font(face.font(size)).tracking(tracking).foregroundStyle(color))
    }

    /// `hex` darkened by `factor`, the edge of a paper wrapping round the glass.
    static func shade(_ hex: UInt32, _ factor: Double) -> UInt32 {
        func channel(_ shift: UInt32) -> UInt32 {
            UInt32(max(0, min(255, (Double((hex >> shift) & 0xFF) * factor).rounded()))) << shift
        }
        return channel(16) | channel(8) | channel(0)
    }
}
