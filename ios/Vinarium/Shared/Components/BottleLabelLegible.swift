import SwiftUI

// The labels of the home vignettes, where the bottle is cropped to its label and
// drawn 80 pt wide: the same paper, ornaments, faces and colours as the labels of
// `BottleLabel.swift`, the text set large enough to read at that size (the name
// from 11 pt, the producer from 6 pt), as validated on the board ("Étiquettes :
// titre lisible"). The text of a label is a stack laid out in the room the
// ornaments leave, shrunk as a whole when it does not fit. A whole bottle (the
// featured wine, a recent move) keeps the finer label: its name is written beside it.

private typealias B = LabelBlock

extension BottleArtwork {
    /// Draws the legible label of `look` in `rect`, then what the family adds on the neck.
    static func drawLegibleLabel(_ look: LabelLook, text: LabelText, in rect: CGRect, context: GraphicsContext) {
        let pen = LabelPen(context: context)
        switch look.family {
        case .chateau: legibleChateau(look, text, rect, pen)
        case .burgundy: legibleBurgundy(look, text, rect, pen)
        case .champagne: legibleChampagne(look, text, rect, pen)
        case .provence: legibleProvence(look, text, rect, pen)
        case .south: legibleSouth(look, text, rect, pen)
        case .alsace: legibleAlsace(look, text, rect, pen)
        case .sweet: legibleSweet(look, text, rect, pen)
        case .natural: legibleNatural(look, text, rect, pen)
        case .italy: legibleItaly(look, text, rect, pen)
        case .spirit: legibleSpirit(look, text, rect, pen)
        case .loire: legibleLoire(look, text, rect, pen)
        case .rhone: legibleRhone(look, text, rect, pen)
        case .spain: legibleSpain(look, text, rect, pen)
        case .portugal: legiblePortugal(look, text, rect, pen)
        case .germany: legibleGermany(look, text, rect, pen)
        case .newWorld: legibleNewWorld(look, text, rect, pen)
        case .sparkling: legibleSparkling(look, text, rect, pen)
        }
    }

    // MARK: Families

    private static func legibleChateau(_ v: LabelLook, _ t: LabelText, _ r: CGRect, _ pen: LabelPen) {
        let cx = r.midX, ink = Color(hex: v.ink), accent = Color(hex: v.accent)
        pen.paper(r, v)
        if v.framed {
            pen.stroke(Path(r.insetBy(dx: 3, dy: 3)), accent, 0.7)
            pen.stroke(Path(r.insetBy(dx: 4.6, dy: 4.6)), accent, 0.3)
        }
        if v.banded { pen.fill(Path(CGRect(x: r.minX, y: r.maxY - 16, width: r.width, height: 9)), accent) }
        switch v.emblem {
        case .castle: pen.castle(cx: cx, y: r.minY + 10, ink: ink, paper: Color(hex: v.paper))
        case .crest: pen.crest(cx: cx, y: r.minY + 9, ink: ink, scale: 1.1)
        default: break
        }
        let (kicker, title) = chateauTitle(t)
        let width = r.width - 12
        let blocks: [LabelBlock?] = [
            kicker.map { B.text(pen.wrapBreaking($0.uppercased(), .copperplateBold, from: 5.4, to: 4.2, width: width - 2, lines: 2), .copperplateBold, ink, tracking: 0.5, leading: 1.18) },
            B.text(pen.wrapBreaking(title, .didotBold, from: 13, to: 6.5, width: width, lines: 3), .didotBold, ink, leading: 1, gap: 4),
            t.classification.map { B.line($0, .baskervilleItalic, 4.4, accent, gap: 3.6) },
            B.rule(width: 18, height: 0.5, color: accent, gap: 2.8),
            t.appellation.map { B.line($0.uppercased(), .copperplateBold, 4, ink, tracking: 0.4, gap: 3.4) },
        ]
        pen.stack(blocks, x: cx, top: r.minY + (v.emblem == .none ? 9 : 28.5), bottom: r.maxY - (v.banded ? 30 : 23), maxWidth: width)
        if let vintage = t.vintage {
            pen.write(String(vintage), .didotBold, 8, ink, x: cx, y: r.maxY - (v.banded ? 20 : 12.5))
        }
    }

    private static func legibleBurgundy(_ v: LabelLook, _ t: LabelText, _ r: CGRect, _ pen: LabelPen) {
        let cx = r.midX, ink = Color(hex: v.ink), accent = Color(hex: v.accent)
        pen.paper(r, v)
        // The producer takes two lines when it needs them, and the band or the rule
        // under it moves down with it.
        let producer = t.producer.map { pen.wrapBreaking($0.uppercased(), .systemSemibold, from: 5.4, to: 4.2, width: r.width - 12, lines: 2) }
        let head: CGFloat = (producer?.0.count ?? 0) > 1 ? 21 : 15
        if v.banded {
            pen.fill(Path(CGRect(x: r.minX, y: r.minY, width: r.width, height: head)), accent)
        } else {
            pen.fill(Path(CGRect(x: r.minX + 8, y: r.minY + head, width: r.width - 16, height: 0.4)), ink.opacity(0.6))
        }
        if let producer {
            pen.stack(
                [B.text(producer, .systemSemibold, v.banded ? Color(hex: v.paper) : ink, tracking: 0.35, leading: 1.2)],
                x: cx, top: r.minY + (v.banded ? 1.5 : 3), bottom: r.minY + head - 1.5, maxWidth: r.width - 8
            )
        }
        var title = t.name
        var climat = t.appellation.flatMap { t.name.localizedStandardContains($0) ? nil : $0 }
        if let appellation = t.appellation, t.name.lowercased().hasPrefix(appellation.lowercased()) {
            let rest = t.name.dropFirst(appellation.count).trimmingCharacters(in: .whitespaces)
            title = appellation
            climat = rest.isEmpty ? nil : rest
        }
        let blocks: [LabelBlock?] = [
            B.text(pen.wrapBreaking(title, .baskervilleBold, from: 11.5, to: 6.5, width: r.width - 8, lines: 3), .baskervilleBold, ink, leading: 1.08),
            climat.map { B.text(pen.wrapBreaking($0, .baskervilleItalic, from: 6.4, to: 5, width: r.width - 10, lines: 2), .baskervilleItalic, accent, leading: 1.12, gap: 3.8) },
        ]
        pen.stack(blocks, x: cx, top: r.minY + head + 3, bottom: r.maxY - 24, maxWidth: r.width - 8)
        pen.fill(Path(CGRect(x: r.minX + 8, y: r.maxY - 21, width: r.width - 16, height: 0.4)), ink.opacity(0.6))
        let crest = v.emblem == .crest
        if let vintage = t.vintage {
            pen.write(String(vintage), .baskervilleBold, crest ? 6.2 : 7.4, ink, x: r.minX + 7, y: r.maxY - 9.5, align: .leading)
        }
        if let classification = t.classification {
            pen.write(classification.uppercased(), .systemSemibold, crest ? 3.6 : 4.4, accent, tracking: 0.3, x: r.maxX - 7, y: r.maxY - 10, align: .trailing, maxWidth: r.width / 2 - (crest ? 15 : 4))
        }
        if crest { pen.crest(cx: cx, y: r.maxY - 17, ink: accent, scale: 0.7) }
    }

    private static func legibleChampagne(_ v: LabelLook, _ t: LabelText, _ r: CGRect, _ pen: LabelPen) {
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
        if let appellation = t.appellation {
            pen.write(appellation.uppercased(), .copperplateBold, 3.6, ink, tracking: 0.7, x: cx, y: r.minY + 15.5, maxWidth: r.width - 24)
        }
        let crest = v.emblem == .crest
        if crest {
            pen.crest(cx: cx, y: r.minY + 18, ink: ink, scale: 0.45)
        } else {
            pen.diamond(cx, r.minY + 20.5, 1.2, ink)
        }
        // The house's name, on its band when the look has one, clipped to the shield.
        var inside = pen
        inside.context.clip(to: shield)
        let (kicker, title) = t.producer.map { ($0, Optional(t.name)) } ?? (t.name, nil)
        let blocks: [LabelBlock?] = [
            B.text(
                pen.wrapBreaking(kicker.uppercased(), .copperplateBold, from: 6.4, to: 4.6, width: r.width - 24, lines: 2), .copperplateBold,
                v.banded ? Color(hex: v.paper) : ink, tracking: 0.3, leading: 1.15,
                band: v.banded ? LabelBlock.Band(color: ink, x: r.minX, width: r.width, pad: 2) : nil
            ),
            title.map { B.text(pen.wrapBreaking($0, .didotItalic, from: 9.5, to: 6, width: r.width - 22, lines: 2), .didotItalic, ink, leading: 1.08, gap: v.banded ? 5 : 4) },
            t.classification.map { B.line($0, .baskervilleItalic, 4.2, ink.opacity(0.85), gap: 3.2) },
        ]
        inside.stack(blocks, x: cx, top: r.minY + (crest ? 28 : 25), bottom: r.maxY - 26, maxWidth: r.width - 22)
        pen.stroke(shield, ink, 0.8)
        let inner = shield.applying(
            CGAffineTransform(translationX: cx, y: r.midY).scaledBy(x: 0.9, y: 0.9).translatedBy(x: -cx, y: -r.midY)
        )
        pen.stroke(inner, ink, 0.3)
        // The collar on the neck carries the vintage, or a diamond for a non-vintage.
        let collar = CGRect(x: 0, y: 94, width: 100, height: 15)
        pen.paper(Path(collar), bounds: collar, v)
        pen.fill(Path(CGRect(x: 0, y: 95.5, width: 100, height: 0.4)), ink)
        pen.fill(Path(CGRect(x: 0, y: 107.1, width: 100, height: 0.4)), ink)
        if let vintage = t.vintage {
            pen.write(String(vintage), .didotBold, 6.4, ink, tracking: 0.4, x: 50, y: 104.6)
        } else {
            pen.diamond(50, 101.5, 1.6, ink)
        }
    }

    private static func legibleProvence(_ v: LabelLook, _ t: LabelText, _ r: CGRect, _ pen: LabelPen) {
        let cx = r.midX, ink = Color(hex: v.ink)
        pen.fill(Path(r), Color(hex: v.paper).opacity(0.82))
        if v.framed { pen.stroke(Path(r.insetBy(dx: 2, dy: 2)), ink.opacity(0.5), 0.3) }
        if v.banded {
            for i in 0..<3 {
                pen.fill(Path(CGRect(x: r.minX + 6, y: r.minY + 6 + CGFloat(i) * 3.6, width: r.width - 12, height: 2)), Color(hex: v.mark))
            }
        } else {
            pen.fill(Path(ellipseIn: CGRect(x: cx - 6, y: r.minY + 5, width: 12, height: 12)), Color(hex: v.mark))
        }
        pen.fill(Path(CGRect(x: r.minX + 4, y: r.minY + 19.5, width: r.width - 8, height: 0.4)), ink.opacity(0.5))
        let width = r.width - 8
        let appellation = t.appellation.flatMap { t.name.localizedStandardContains($0) ? nil : $0 }
        let blocks: [LabelBlock?] = [
            t.producer.map { B.text(pen.wrapBreaking($0.uppercased(), .futuraMedium, from: 4.8, to: 3.8, width: width - 4, lines: 2), .futuraMedium, ink, tracking: 0.4, leading: 1.18) },
            B.text(pen.wrapBreaking(t.name, .futuraMedium, from: 11, to: 6, width: width, lines: 2), .futuraMedium, ink, tracking: 0.1, leading: 1.02, gap: 3.6),
            appellation.map { B.line($0, .snellRoundhand, 6.6, ink, gap: 3) },
        ]
        pen.stack(blocks, x: cx, top: r.minY + 22.5, bottom: r.maxY - 12.5, maxWidth: width)
        if let vintage = t.vintage {
            pen.write(String(vintage), .futuraMedium, 5.2, ink, tracking: 0.5, x: cx, y: r.maxY - 5.5)
        }
    }

    private static func legibleSouth(_ v: LabelLook, _ t: LabelText, _ r: CGRect, _ pen: LabelPen) {
        let cx = r.midX, ink = Color(hex: v.ink), stamp = Color(hex: v.mark)
        pen.paper(r, v)
        for i in 0..<14 {
            pen.fill(Path(CGRect(x: r.minX, y: r.minY + 4 + CGFloat(i) * 7, width: r.width, height: 0.25)), ink.opacity(0.06))
        }
        if v.banded { pen.fill(Path(CGRect(x: r.minX, y: r.minY, width: 4, height: r.height)), stamp) }
        if let producer = t.producer {
            pen.stack(
                [B.text(pen.wrapBreaking(producer, .baskervilleItalic, from: 6, to: 4.6, width: r.width - 10, lines: 2), .baskervilleItalic, ink, leading: 1.05)],
                x: cx, top: r.minY + 4, bottom: r.minY + 15, maxWidth: r.width - 10
            )
        }
        if v.emblem == .crest {
            pen.crest(cx: cx, y: r.minY + 16, ink: ink, scale: 0.45)
        } else {
            pen.diamond(cx - 10, r.minY + 19, 0.9, ink)
            pen.diamond(cx, r.minY + 19, 1.2, ink)
            pen.diamond(cx + 10, r.minY + 19, 0.9, ink)
        }
        let appellation = t.appellation.flatMap { t.name.localizedStandardContains($0) ? nil : $0 }
        let blocks: [LabelBlock?] = [
            B.text(pen.wrapBreaking(t.name.uppercased(), .copperplateBold, from: 11, to: 6.5, width: r.width - 10, lines: 3), .copperplateBold, ink, tracking: 0.15, leading: 1.05),
            appellation.map { B.line($0.uppercased(), .systemSemibold, 4, ink.opacity(0.75), tracking: 0.3, gap: 3.4) },
        ]
        pen.stack(blocks, x: cx, top: r.minY + 25, bottom: r.maxY - 32, maxWidth: r.width - 10)
        let center = CGPoint(x: cx + 14, y: r.maxY - 20)
        pen.stroke(Path(ellipseIn: CGRect(x: center.x - 10, y: center.y - 10, width: 20, height: 20)), stamp, 0.9)
        pen.stroke(Path(ellipseIn: CGRect(x: center.x - 8.2, y: center.y - 8.2, width: 16.4, height: 16.4)), stamp, 0.35)
        if let vintage = t.vintage {
            pen.write(String(vintage), .copperplateBold, 6, stamp, x: center.x, y: center.y + 2.4, maxWidth: 15)
        } else {
            pen.diamond(center.x, center.y, 1.6, stamp)
        }
        if let classification = t.classification {
            pen.write(classification, .baskervilleItalic, 4, ink.opacity(0.8), x: r.minX + 7, y: r.maxY - 14.5, align: .leading, maxWidth: 28)
        }
    }

    private static func legibleAlsace(_ v: LabelLook, _ t: LabelText, _ r: CGRect, _ pen: LabelPen) {
        let cx = r.midX, ink = Color(hex: v.ink), band = Color(hex: v.mark)
        pen.paper(r, v)
        let producer = t.producer.map { pen.wrapBreaking($0.uppercased(), .systemBold, from: 3.8, to: 3.2, width: r.width - 6, lines: 2) }
        let head: CGFloat = (producer?.0.count ?? 0) > 1 ? 16 : 11
        pen.fill(Path(CGRect(x: r.minX, y: r.minY, width: r.width, height: head)), band)
        if let producer {
            pen.stack(
                [B.text(producer, .systemBold, .white, tracking: 0.25, leading: 1.2)],
                x: cx, top: r.minY + 1.5, bottom: r.minY + head - 1.5, maxWidth: r.width - 4
            )
        }
        let crest = v.emblem == .crest
        if crest { pen.crest(cx: cx, y: r.minY + head + 2, ink: band, scale: 0.5) }
        let blocks: [LabelBlock?] = [
            t.appellation.map { B.line($0.uppercased(), .copperplateBold, 3.3, band, tracking: 0.6) },
            B.text(pen.wrapBreaking(t.name, .didotBoldItalic, from: 8.6, to: 5.2, width: r.width - 4, lines: 3), .didotBoldItalic, ink, leading: 1.08, gap: 4),
            t.classification.map { B.line($0.uppercased(), .systemBold, 3.2, band, tracking: 0.5, gap: 3.8) },
        ]
        pen.stack(blocks, x: cx, top: r.minY + head + (crest ? 12 : 3), bottom: r.maxY - (v.banded ? 15.5 : 20), maxWidth: r.width - 4)
        if v.banded {
            pen.fill(Path(CGRect(x: r.minX, y: r.maxY - 13, width: r.width, height: 13)), band)
            if let vintage = t.vintage {
                pen.write(String(vintage), .didotBold, 5.6, .white, x: cx, y: r.maxY - 4.4)
            }
        } else {
            pen.fill(Path(CGRect(x: cx - 6, y: r.maxY - 17.5, width: 12, height: 0.4)), band)
            if let vintage = t.vintage {
                pen.write(String(vintage), .didotBold, 5.6, ink, x: cx, y: r.maxY - 7.5)
            }
        }
    }

    private static func legibleSweet(_ v: LabelLook, _ t: LabelText, _ r: CGRect, _ pen: LabelPen) {
        let cx = r.midX, ink = Color(hex: v.ink), accent = Color(hex: v.accent)
        pen.paper(r, v)
        pen.stroke(Path(roundedRect: r.insetBy(dx: 3, dy: 3), cornerRadius: 3), accent, 0.6)
        for corner in [CGPoint(x: r.minX + 3, y: r.minY + 3), CGPoint(x: r.maxX - 3, y: r.minY + 3),
                       CGPoint(x: r.minX + 3, y: r.maxY - 3), CGPoint(x: r.maxX - 3, y: r.maxY - 3)] {
            pen.fill(Path(ellipseIn: CGRect(x: corner.x - 1.6, y: corner.y - 1.6, width: 3.2, height: 3.2)), accent)
        }
        let crest = v.emblem == .crest
        if crest { pen.crest(cx: cx, y: r.minY + 7, ink: accent, scale: 0.6) }
        if v.banded { pen.fill(Path(CGRect(x: r.minX, y: r.maxY - 21, width: r.width, height: 11)), accent) }
        let (kicker, title) = chateauTitle(t)
        let blocks: [LabelBlock?] = [
            kicker.map { B.text(pen.wrapBreaking($0.uppercased(), .copperplateBold, from: 5, to: 4, width: r.width - 12, lines: 2), .copperplateBold, ink, tracking: 0.5, leading: 1.18) },
            B.text(pen.wrapBreaking(title, .snellRoundhand, from: 15, to: 9, width: r.width - 10, lines: 2), .snellRoundhand, ink, leading: 0.95, gap: 3),
            B.rule(width: 20, height: 0.5, color: accent, gap: 3.4),
            t.appellation.map { B.line($0.uppercased(), .copperplateBold, 4.4, accent, tracking: 0.5, gap: 3.6) },
            t.classification.map { B.line($0, .baskervilleItalic, 4.2, ink.opacity(0.8), gap: 3) },
        ]
        pen.stack(blocks, x: cx, top: r.minY + (crest ? 18 : 8), bottom: r.maxY - 24, maxWidth: r.width - 12)
        if let vintage = t.vintage {
            pen.write(String(vintage), .didotBold, 8, v.banded ? Color(hex: v.paper) : ink, x: cx, y: r.maxY - 12.5)
        }
    }

    private static func legibleNatural(_ v: LabelLook, _ t: LabelText, _ r: CGRect, _ pen: LabelPen) {
        let ink = Color(hex: v.ink)
        pen.paper(r, v)
        var inside = pen
        inside.context.clip(to: Path(r))
        if v.banded {
            for i in 0..<3 {
                inside.fill(Path(CGRect(x: r.maxX - 17 + CGFloat(i) * 5, y: r.minY, width: 3, height: 46)), Color(hex: v.mark))
            }
        } else {
            inside.fill(Path(ellipseIn: CGRect(x: r.maxX - 28, y: r.minY + 6, width: 40, height: 40)), Color(hex: v.mark))
        }
        if let producer = t.producer {
            pen.write(producer.lowercased(), .futuraMedium, 5, ink, x: r.minX + 7, y: r.minY + 12, align: .leading, maxWidth: r.width - 30)
        }
        pen.stack(
            [B.text(pen.wrapBreaking(t.name, .futuraHeavy, from: 15, to: 8, width: r.width - 12, lines: 3), .futuraHeavy, ink, tracking: -0.4, leading: 0.95)],
            x: r.minX + 6, top: r.minY + 17, bottom: r.maxY - 17, maxWidth: r.width - 12, align: .leading
        )
        if let appellation = t.appellation {
            pen.write(appellation.lowercased(), .futuraMedium, 4.2, ink, tracking: 0.2, x: r.minX + 7, y: r.maxY - 8, align: .leading, maxWidth: r.width - 30)
        }
        if let vintage = t.vintage {
            pen.write(String(vintage), .futuraBold, 5.4, ink, x: r.maxX - 7, y: r.maxY - 8, align: .trailing)
        }
    }

    private static func legibleItaly(_ v: LabelLook, _ t: LabelText, _ r: CGRect, _ pen: LabelPen) {
        let cx = r.midX, ink = Color(hex: v.ink), accent = Color(hex: v.accent)
        pen.paper(r, v)
        if v.emblem == .castle {
            pen.castle(cx: cx, y: r.minY + 7, ink: accent, paper: Color(hex: v.paper))
        } else {
            pen.crest(cx: cx, y: r.minY + 8, ink: accent, scale: 1.1)
        }
        if v.banded { pen.fill(Path(CGRect(x: r.minX, y: r.maxY - 18, width: r.width, height: 11)), accent) }
        let mention = t.appellation.flatMap { t.name.localizedStandardContains($0) ? nil : $0 } ?? t.classification
        let blocks: [LabelBlock?] = [
            B.text(pen.wrapBreaking(t.name.uppercased(), .didotBold, from: 10.5, to: 6, width: r.width - 9, lines: 3), .didotBold, ink, tracking: 0.3, leading: 1.08),
            mention.map { B.line($0.uppercased(), .systemSemibold, 3.9, ink.opacity(0.8), tracking: 0.3, gap: 3.4) },
            B.rule(width: 24, height: 0.4, color: accent, gap: 2.8),
            t.producer.map { B.text(pen.wrapBreaking($0, .baskervilleItalic, from: 6, to: 4.6, width: r.width - 10, lines: 2), .baskervilleItalic, ink, leading: 1.12, gap: 3.8) },
        ]
        pen.stack(blocks, x: cx, top: r.minY + 27, bottom: r.maxY - 21, maxWidth: r.width - 8)
        if let vintage = t.vintage {
            pen.write(String(vintage), .didotBold, 7, v.banded ? Color(hex: v.paper) : accent, x: cx, y: r.maxY - 10)
        }
        let band = CGRect(x: 46.5, y: 30, width: 7, height: 26)
        pen.fill(Path(band), Color(hex: v.mark))
        pen.stroke(Path(band), .black.opacity(0.15), 0.3)
    }

    private static func legibleSpirit(_ v: LabelLook, _ t: LabelText, _ r: CGRect, _ pen: LabelPen) {
        let cx = r.midX, ink = Color(hex: v.ink)
        pen.paper(r, v)
        if v.framed { pen.stroke(Path(r.insetBy(dx: 4, dy: 4)), ink, 0.5) }
        if v.banded { pen.fill(Path(CGRect(x: r.minX, y: r.minY + 11.5, width: r.width, height: 9)), ink) }
        if v.emblem == .crest { pen.crest(cx: cx, y: r.minY + 4, ink: ink, scale: 0.5) }
        if let kind = t.kind {
            pen.write(kind.uppercased(), .copperplateBold, 4.4, v.banded ? Color(hex: v.paper) : ink, tracking: 0.8, x: cx, y: r.minY + 18.2, maxWidth: r.width - 14)
        }
        pen.fill(Path(CGRect(x: cx - 14, y: r.minY + 22.5, width: 28, height: 0.4)), ink)
        let (title, subtitle) = t.producer.map { ($0, Optional(t.name)) } ?? (t.name, nil)
        let blocks: [LabelBlock?] = [
            B.text(pen.wrapBreaking(title.uppercased(), .didotBold, from: 11, to: 6.5, width: r.width - 14, lines: 2), .didotBold, ink, tracking: 0.3, leading: 1.08),
            subtitle.map { B.text(pen.wrapBreaking($0, .baskervilleItalic, from: 5.4, to: 4.2, width: r.width - 14, lines: 2), .baskervilleItalic, ink, leading: 1.15, gap: 3) },
        ]
        pen.stack(blocks, x: cx, top: r.minY + 27, bottom: r.minY + 80, maxWidth: r.width - 14)
        let center = CGPoint(x: cx, y: r.minY + 94)
        pen.stroke(Path(ellipseIn: CGRect(x: center.x - 11, y: center.y - 11, width: 22, height: 22)), ink, 0.6)
        if let vintage = t.vintage {
            pen.write(String(vintage), .didotBold, 6.4, ink, x: center.x, y: center.y + 2.3, maxWidth: 19)
        } else {
            pen.diamond(center.x, center.y, 2, ink)
        }
    }

    private static func legibleLoire(_ v: LabelLook, _ t: LabelText, _ r: CGRect, _ pen: LabelPen) {
        let ink = Color(hex: v.ink), accent = Color(hex: v.accent), river = Color(hex: v.mark)
        let left = r.minX + 7
        pen.paper(r, v)
        let crest = v.emblem == .crest
        if crest { pen.crest(cx: left + 3, y: r.minY + 6, ink: ink, scale: 0.55) }
        let textLeft = crest ? left + 9 : left
        let producer = t.producer.map { pen.wrapBreaking($0.uppercased(), .optima, from: 5, to: 4, width: r.maxX - 7 - textLeft, lines: 2) }
        let head: CGFloat = (producer?.0.count ?? 0) > 1 ? 19 : 14
        if let producer {
            pen.stack(
                [B.text(producer, .optima, ink, tracking: 0.5, leading: 1.18)],
                x: textLeft, top: r.minY + 5, bottom: r.minY + head - 1, maxWidth: r.maxX - 7 - textLeft, align: .leading
            )
        }
        if v.framed { pen.fill(Path(CGRect(x: left, y: r.minY + head + 1.5, width: r.width - 14, height: 0.35)), ink.opacity(0.5)) }
        let appellation = t.appellation.flatMap { t.name.localizedStandardContains($0) ? nil : $0 }
        let blocks: [LabelBlock?] = [
            B.text(pen.wrapBreaking(t.name, .optima, from: 12, to: 6.5, width: r.width - 14, lines: 3), .optima, ink, leading: 1.06),
            appellation.map { B.line($0, .baskervilleItalic, 5, accent, gap: 3) },
            t.classification.map { B.line($0.uppercased(), .optima, 4, accent, tracking: 0.4, gap: 3) },
        ]
        pen.stack(blocks, x: left, top: r.minY + head + 5, bottom: r.maxY - 29, maxWidth: r.width - 14, align: .leading)
        let y0 = r.maxY - 25
        var water = pen
        water.context.clip(to: Path(r))
        if v.banded {
            var band = LabelPen.wave(from: r.minX - 4, to: r.maxX + 6, y: y0, amplitude: 1.6, length: 12)
            band.addLine(to: CGPoint(x: r.maxX + 6, y: y0 + 7))
            band.addLine(to: CGPoint(x: r.minX - 4, y: y0 + 7))
            band.closeSubpath()
            water.fill(band, river)
        } else {
            for i in 0..<3 {
                let line = LabelPen.wave(from: r.minX - 4 - CGFloat(i) * 3, to: r.maxX + 6, y: y0 + CGFloat(i) * 3.2, amplitude: 1.4, length: 12)
                water.stroke(line, river, 0.5)
            }
        }
        if let vintage = t.vintage {
            pen.write(String(vintage), .optimaBold, 6.4, ink, x: r.maxX - 7, y: r.maxY - 6.5, align: .trailing)
        }
    }

    private static func legibleRhone(_ v: LabelLook, _ t: LabelText, _ r: CGRect, _ pen: LabelPen) {
        let cx = r.midX, ink = Color(hex: v.ink), accent = Color(hex: v.accent)
        func arch(_ d: CGFloat) -> Path {
            Path { p in
                p.move(to: CGPoint(x: r.minX + d, y: r.maxY - d))
                p.addLine(to: CGPoint(x: r.minX + d, y: r.minY + 16 + d))
                p.addQuadCurve(to: CGPoint(x: r.maxX - d, y: r.minY + 16 + d), control: CGPoint(x: cx, y: r.minY - 14 + d * 1.6))
                p.addLine(to: CGPoint(x: r.maxX - d, y: r.maxY - d))
                p.closeSubpath()
            }
        }
        pen.paper(arch(0), bounds: r, v)
        if v.framed { pen.stroke(arch(3), accent, 0.4) }
        if v.emblem == .crest {
            pen.crest(cx: cx, y: r.minY + 8, ink: accent, scale: 1)
        } else {
            pen.keys(cx: cx, y: r.minY + 21, ink: accent, scale: 0.85)
        }
        let width = r.width - 9
        let appellation = t.appellation.flatMap { t.name.localizedStandardContains($0) ? nil : $0 }
        let blocks: [LabelBlock?] = [
            t.producer.map { B.text(pen.wrapBreaking($0, .cochinItalic, from: 6, to: 4.6, width: width - 4, lines: 2), .cochinItalic, ink, leading: 1.05) },
            B.text(pen.wrapBreaking(t.name.uppercased(), .cochinBold, from: 11, to: 6, width: width, lines: 2), .cochinBold, ink, tracking: 0.15, leading: 1.05, gap: 3.4),
            appellation.map {
                B.line(
                    $0.uppercased(), .copperplateBold, 4, v.banded ? Color(hex: v.paper) : accent, tracking: 0.6, gap: v.banded ? 5 : 3.6,
                    maxWidth: width - 4, band: v.banded ? LabelBlock.Band(color: accent, x: r.minX, width: r.width, pad: 1.8) : nil
                )
            },
            t.classification.map { B.line($0, .baskervilleItalic, 4.2, ink.opacity(0.8), gap: v.banded && appellation != nil ? 4.6 : 3) },
        ]
        pen.stack(blocks, x: cx, top: r.minY + 31, bottom: r.maxY - 17.5, maxWidth: width)
        if let vintage = t.vintage {
            pen.write(String(vintage), .cochinBold, 7, ink, x: cx, y: r.maxY - 8.5)
            pen.fill(Path(CGRect(x: cx - 20, y: r.maxY - 10.8, width: 8, height: 0.35)), accent)
            pen.fill(Path(CGRect(x: cx + 12, y: r.maxY - 10.8, width: 8, height: 0.35)), accent)
        }
    }

    private static func legibleSpain(_ v: LabelLook, _ t: LabelText, _ r: CGRect, _ pen: LabelPen) {
        let cx = r.midX, ink = Color(hex: v.ink), accent = Color(hex: v.accent), paper = Color(hex: v.paper)
        if v.meshed {
            let wire = Color(hex: v.mark).opacity(0.9)
            for x in stride(from: CGFloat(-130), through: 110, by: 6) {
                pen.stroke(Path { p in p.move(to: CGPoint(x: x, y: 104)); p.addLine(to: CGPoint(x: x + 122, y: 300)) }, wire, 0.3)
                pen.stroke(Path { p in p.move(to: CGPoint(x: x + 122, y: 104)); p.addLine(to: CGPoint(x: x, y: 300)) }, wire, 0.3)
            }
        }
        pen.paper(r, v)
        if v.framed {
            pen.stroke(Path(r.insetBy(dx: 2, dy: 2)), accent, 0.8)
            pen.stroke(Path(r.insetBy(dx: 3.6, dy: 3.6)), accent, 0.3)
            for corner in [CGPoint(x: r.minX + 3.6, y: r.minY + 3.6), CGPoint(x: r.maxX - 3.6, y: r.minY + 3.6),
                           CGPoint(x: r.minX + 3.6, y: r.maxY - 3.6), CGPoint(x: r.maxX - 3.6, y: r.maxY - 3.6)] {
                pen.diamond(corner.x, corner.y, 1.6, accent)
            }
        }
        let crest = v.emblem == .crest
        if crest { pen.crest(cx: cx, y: r.minY + 9, ink: accent, scale: 0.9) }
        let onBand = t.classification ?? t.appellation
        let blocks: [LabelBlock?] = [
            t.producer.map { B.text(pen.wrapBreaking($0.uppercased(), .copperplateBold, from: 5, to: 4, width: r.width - 14, lines: 2), .copperplateBold, ink, tracking: 0.4, leading: 1.18) },
            B.text(pen.wrapBreaking(t.name, .didotBold, from: 12, to: 7, width: r.width - 12, lines: 2), .didotBold, ink, leading: 1.05, gap: 3.6),
            onBand.map {
                B.line($0.uppercased(), .copperplateBold, 4.4, paper, tracking: 0.6, gap: 5, maxWidth: r.width - 10,
                       band: LabelBlock.Band(color: accent, x: r.minX, width: r.width, pad: 2.2))
            },
            t.classification != nil ? t.appellation.map { B.line($0, .baskervilleItalic, 4.6, ink, gap: 5) } : nil,
        ]
        pen.stack(blocks, x: cx, top: r.minY + (crest ? 25 : 8), bottom: r.maxY - 22, maxWidth: r.width - 12)
        if let vintage = t.vintage {
            pen.write(String(vintage), .didotBold, 8, ink, x: cx, y: r.maxY - 11)
        }
    }

    private static func legiblePortugal(_ v: LabelLook, _ t: LabelText, _ r: CGRect, _ pen: LabelPen) {
        let cx = r.midX, ink = Color(hex: v.ink), accent = Color(hex: v.accent), blue = Color(hex: v.mark)
        pen.paper(r, v)
        let side = r.width / 6
        let rows = v.banded ? 2 : 1
        pen.azulejos(r, top: r.minY, rows: rows, side: side, blue: blue)
        if v.framed { pen.azulejos(r, top: r.maxY - side / 2, rows: 1, side: side / 2, blue: blue) }
        let blocks: [LabelBlock?] = [
            t.producer.map { B.text(pen.wrapBreaking($0, .cochinItalic, from: 6, to: 4.6, width: r.width - 12, lines: 2), .cochinItalic, ink, leading: 1.05) },
            B.text(pen.wrapBreaking(t.name, .cochinBold, from: 12, to: 7, width: r.width - 12, lines: 2), .cochinBold, ink, leading: 1.05, gap: 3),
            B.diamond(radius: 1.2, color: blue, gap: 3),
            t.appellation.map { B.line($0.uppercased(), .copperplateBold, 4.2, accent, tracking: 0.5, gap: 3) },
            t.classification.map { B.line($0, .baskervilleItalic, 4.2, ink.opacity(0.8), gap: 3) },
        ]
        pen.stack(blocks, x: cx, top: r.minY + CGFloat(rows) * side + 4, bottom: r.maxY - (v.framed ? side / 2 + 13 : 17), maxWidth: r.width - 12)
        if let vintage = t.vintage {
            pen.write(String(vintage), .cochinBold, 7.5, ink, x: cx, y: r.maxY - (v.framed ? side / 2 + 4.5 : 8))
        }
    }

    private static func legibleGermany(_ v: LabelLook, _ t: LabelText, _ r: CGRect, _ pen: LabelPen) {
        let cx = r.midX, ink = Color(hex: v.ink), accent = Color(hex: v.accent)
        pen.paper(r, v)
        if v.framed { pen.stroke(Path(r.insetBy(dx: 2, dy: 2)), accent.opacity(0.8), 0.35) }
        if v.banded {
            pen.fill(Path(CGRect(x: r.minX, y: r.minY, width: r.width, height: 3)), Color(hex: v.mark))
            pen.fill(Path(CGRect(x: r.minX, y: r.minY + 6, width: r.width, height: 3)), Color(hex: v.mark))
        }
        let top = r.minY + (v.banded ? 11 : 4)
        var emblem: CGFloat = 0
        switch v.emblem {
        case .grapes: pen.grapes(cx: cx, y: top, ink: accent, scale: 0.75); emblem = 12
        case .crest: pen.crest(cx: cx, y: top, ink: accent, scale: 0.6); emblem = 10
        default: break
        }
        let appellation = t.appellation.flatMap { t.name.localizedStandardContains($0) ? nil : $0 }
        let blocks: [LabelBlock?] = [
            t.producer.map { B.text(pen.wrapBreaking($0.uppercased(), .gillSans, from: 3.8, to: 3.2, width: r.width - 6, lines: 2), .gillSans, ink, tracking: 0.3, leading: 1.2) },
            B.rule(width: 16, height: 0.3, color: accent, gap: 2.4),
            B.text(pen.wrapBreaking(t.name, .gillSans, from: 8.6, to: 5, width: r.width - 5, lines: 3), .gillSans, ink, leading: 1.08, gap: 3),
            t.classification.map { B.line($0.uppercased(), .gillSans, 3.2, accent, tracking: 0.3, gap: 4.2, maxWidth: r.width - 9, boxed: accent) },
            appellation.map { B.line($0.uppercased(), .systemSemibold, 3, ink.opacity(0.75), tracking: 0.2, gap: 3.6) },
        ]
        pen.stack(blocks, x: cx, top: top + emblem + 1, bottom: r.maxY - 12, maxWidth: r.width - 5)
        if let vintage = t.vintage {
            pen.write(String(vintage), .gillSans, 5.8, ink, x: cx, y: r.maxY - 5.5)
        }
    }

    private static func legibleNewWorld(_ v: LabelLook, _ t: LabelText, _ r: CGRect, _ pen: LabelPen) {
        let cx = r.midX, ink = Color(hex: v.ink), accent = Color(hex: v.accent), mark = Color(hex: v.mark)
        let x0 = r.minX + 8, x1 = r.maxX - 8, base = r.minY + 44
        pen.paper(r, v)
        switch v.emblem {
        case .mountains:
            pen.fill(Path { p in
                p.addLines([CGPoint(x: x0, y: base), CGPoint(x: x0 + 8, y: base - 11), CGPoint(x: cx - 6, y: base - 6),
                            CGPoint(x: cx + 12, y: base - 20), CGPoint(x: x1, y: base)])
                p.closeSubpath()
            }, mark.opacity(0.35))
            pen.stroke(Path { p in
                p.addLines([CGPoint(x: x0, y: base), CGPoint(x: x0 + 12, y: base - 18), CGPoint(x: x0 + 19, y: base - 10),
                            CGPoint(x: cx + 2, y: base - 28), CGPoint(x: x1 - 10, y: base - 12), CGPoint(x: x1 - 5, y: base - 17),
                            CGPoint(x: x1, y: base - 8)])
            }, ink, 0.6)
        case .sun:
            pen.fill(Path(ellipseIn: CGRect(x: cx - 11, y: base - 24, width: 22, height: 22)), mark)
            for i in 0..<4 {
                let stripe = CGRect(x: cx - 13, y: base - 11 + CGFloat(i) * 2.6, width: 26, height: 0.9 + CGFloat(i) * 0.25)
                pen.fill(Path(stripe), Color(hex: v.paper))
            }
        default:
            for (dx, dy, size) in [(0.0, -30.0, 3.4), (-10, -16, 2.8), (10, -20, 3), (1, -5, 3.2), (5, -12, 1.4)] {
                pen.star(cx + dx, base + dy, size, mark)
            }
        }
        pen.fill(Path(CGRect(x: x0, y: base + 1, width: x1 - x0, height: 0.5)), ink)
        let blocks: [LabelBlock?] = [
            t.producer.map { B.text(pen.wrapBreaking($0.uppercased(), .avenirHeavy, from: 5.6, to: 4.4, width: r.width - 12, lines: 2), .avenirHeavy, ink, tracking: 0.6, leading: 1.15) },
            B.text(pen.wrapBreaking(t.name, .avenirMedium, from: 9, to: 5.5, width: r.width - 12, lines: 2), .avenirMedium, ink, leading: 1.1, gap: 3),
            t.appellation.map { B.line($0.uppercased(), .avenirMedium, 4, ink.opacity(0.8), tracking: 0.5, gap: 3.4) },
        ]
        pen.stack(blocks, x: cx, top: base + 5, bottom: r.maxY - 15, maxWidth: r.width - 12)
        if let vintage = t.vintage {
            pen.write(String(vintage), .avenirHeavy, 5.4, accent, tracking: 0.4, x: cx, y: r.maxY - 6.5)
        }
    }

    private static func legibleSparkling(_ v: LabelLook, _ t: LabelText, _ r: CGRect, _ pen: LabelPen) {
        let cx = r.midX, ink = Color(hex: v.ink), sash = Color(hex: v.mark), paper = Color(hex: v.paper)
        let shape = Path(roundedRect: r, cornerRadius: 3)
        pen.paper(shape, bounds: r, v)
        let tilt = Angle(radians: v.banded ? 0 : atan2(-34, Double(r.width)))
        var clipped = pen
        clipped.context.clip(to: shape)
        clipped.context.translateBy(x: cx, y: r.minY + 59)
        clipped.context.rotate(by: tilt)
        clipped.fill(Path(CGRect(x: -r.width, y: -6, width: r.width * 2, height: 12)), sash)
        if v.framed { pen.stroke(Path(roundedRect: r.insetBy(dx: 3, dy: 3), cornerRadius: 2), ink.opacity(0.6), 0.3) }
        let blocks: [LabelBlock?] = [
            t.producer.map { B.text(pen.wrapBreaking($0.uppercased(), .futuraMedium, from: 4.8, to: 4, width: r.width - 14, lines: 2), .futuraMedium, ink, tracking: 0.5, leading: 1.18) },
            B.text(pen.wrapBreaking(t.name.uppercased(), .futuraBold, from: 10, to: 6, width: r.width - 14, lines: 2), .futuraBold, ink, tracking: 0.2, leading: 1.05, gap: 3),
        ]
        pen.stack(blocks, x: cx, top: r.minY + 6, bottom: r.minY + (v.banded ? 51 : 38), maxWidth: r.width - 14)
        if let appellation = t.appellation {
            var along = pen
            along.context.translateBy(x: cx, y: r.minY + 59)
            along.context.rotate(by: tilt)
            along.write(appellation.uppercased(), .futuraBold, 4.2, paper, tracking: 0.6, x: 0, y: 1.5, maxWidth: r.width - 16)
        }
        if let classification = t.classification {
            pen.write(classification.uppercased(), .futuraMedium, 3.8, ink, tracking: 0.4, x: r.minX + 7, y: r.maxY - 7, align: .leading, maxWidth: r.width / 2 - 8)
        }
        if let vintage = t.vintage {
            pen.write(String(vintage), .futuraBold, 6.4, ink, x: r.maxX - 7, y: r.maxY - 6.5, align: .trailing)
        }
        pen.fill(Path(CGRect(x: 0, y: 96, width: 100, height: 8)), sash)
        pen.diamond(50, 100, 1.4, paper)
    }
}

// MARK: - Stack

/// One piece of a label's text stack: lines of type, a rule or a diamond, and the
/// room left above it.
struct LabelBlock {
    struct Band {
        let color: Color
        let x: CGFloat
        let width: CGFloat
        let pad: CGFloat
    }

    enum Kind {
        case text(lines: [String], face: LabelPen.Face, size: CGFloat, color: Color)
        case rule(width: CGFloat, height: CGFloat, color: Color)
        case diamond(radius: CGFloat, color: Color)
    }

    let kind: Kind
    var tracking: CGFloat = 0
    var leading: CGFloat = 1.1
    var gap: CGFloat = 0
    var maxWidth: CGFloat?
    /// A band of colour behind the text, as wide as the paper.
    var band: Band?
    /// A frame drawn round the text, the way a Prädikat is boxed.
    var boxed: Color?

    /// How tall the cap of a face is, in ems.
    static let cap: CGFloat = 0.72

    static func text(
        _ wrapped: ([String], CGFloat), _ face: LabelPen.Face, _ color: Color, tracking: CGFloat = 0, leading: CGFloat = 1.1,
        gap: CGFloat = 0, maxWidth: CGFloat? = nil, band: Band? = nil, boxed: Color? = nil
    ) -> LabelBlock {
        LabelBlock(
            kind: .text(lines: wrapped.0, face: face, size: wrapped.1, color: color),
            tracking: tracking, leading: leading, gap: gap, maxWidth: maxWidth, band: band, boxed: boxed
        )
    }

    static func line(
        _ text: String, _ face: LabelPen.Face, _ size: CGFloat, _ color: Color, tracking: CGFloat = 0, gap: CGFloat = 0,
        maxWidth: CGFloat? = nil, band: Band? = nil, boxed: Color? = nil
    ) -> LabelBlock {
        Self.text(([text], size), face, color, tracking: tracking, gap: gap, maxWidth: maxWidth, band: band, boxed: boxed)
    }

    static func rule(width: CGFloat, height: CGFloat, color: Color, gap: CGFloat = 0) -> LabelBlock {
        LabelBlock(kind: .rule(width: width, height: height, color: color), gap: gap)
    }

    static func diamond(radius: CGFloat, color: Color, gap: CGFloat = 0) -> LabelBlock {
        LabelBlock(kind: .diamond(radius: radius, color: color), gap: gap)
    }

    /// The height the block takes, from the cap of its first line to the foot of its
    /// last, descenders included.
    var height: CGFloat {
        switch kind {
        case let .text(lines, _, size, _):
            let descends = lines.last?.contains(where: { "gjpqyQ,;".contains($0) }) == true ? 0.2 * size : 0
            return Self.cap * size + CGFloat(lines.count - 1) * size * leading + descends
        case let .rule(_, height, _): return height
        case let .diamond(radius, _): return radius * 2
        }
    }
}

extension LabelPen {
    /// Lays `blocks` out between `top` and `bottom`, centred in that room, and shrinks
    /// them together when they are taller than it.
    func stack(_ blocks: [LabelBlock?], x: CGFloat, top: CGFloat, bottom: CGFloat, maxWidth: CGFloat, align: Align = .center) {
        let blocks = blocks.compactMap { $0 }
        guard !blocks.isEmpty else { return }
        let room = bottom - top
        let total = blocks.enumerated().reduce(CGFloat(0)) { sum, item in sum + (item.offset > 0 ? item.element.gap : 0) + item.element.height }
        guard total > 0 else { return }
        let k = min(1, room / total)
        var y = top + (room - total * k) / 2
        for (index, block) in blocks.enumerated() {
            if index > 0 { y += block.gap * k }
            let height = block.height * k
            switch block.kind {
            case let .rule(width, _, color):
                let left = switch align {
                case .leading: x
                case .center: x - width / 2
                case .trailing: x - width
                }
                fill(Path(CGRect(x: left, y: y, width: width, height: height)), color)
            case let .diamond(radius, color):
                let center = switch align {
                case .leading: x + radius * k
                case .center: x
                case .trailing: x - radius * k
                }
                diamond(center, y + height / 2, radius * k, color)
            case let .text(lines, face, size, color):
                if let band = block.band {
                    fill(Path(CGRect(x: band.x, y: y - band.pad * k, width: band.width, height: height + 2 * band.pad * k)), band.color)
                }
                let size = size * k, width = block.maxWidth ?? maxWidth
                if let boxed = block.boxed, let first = lines.first {
                    let w = min(measure(first, face, size, tracking: block.tracking * k), width)
                    stroke(Path(CGRect(x: x - w / 2 - 1.8 * k, y: y - 1.2 * k, width: w + 3.6 * k, height: height + 2.4 * k)), boxed, 0.35)
                }
                for (i, line) in lines.enumerated() {
                    write(
                        line, face, size, color, tracking: block.tracking * k,
                        x: x, y: y + LabelBlock.cap * size + CGFloat(i) * size * block.leading, align: align, maxWidth: width
                    )
                }
            }
            y += height
        }
    }

    /// `wrap` in finer steps, a word of twelve letters or more allowed to break after
    /// its hyphens ("Châteauneuf-" / "du-Pape").
    func wrapBreaking(_ text: String, _ face: Face, from: CGFloat, to: CGFloat, width: CGFloat, lines maxLines: Int) -> ([String], CGFloat) {
        var tokens: [(word: String, glued: Bool)] = []
        for word in text.split(separator: " ").map(String.init) {
            guard word.count >= 12, word.contains("-") else {
                tokens.append((word, false))
                continue
            }
            var part = ""
            var parts: [String] = []
            for character in word {
                part.append(character)
                if character == "-" { parts.append(part); part = "" }
            }
            if !part.isEmpty { parts.append(part) }
            for (i, piece) in parts.enumerated() { tokens.append((piece, i > 0)) }
        }
        func split(_ size: CGFloat) -> [String] {
            var lines: [String] = []
            var current = ""
            for token in tokens {
                let candidate = current.isEmpty ? token.word : current + (token.glued ? "" : " ") + token.word
                if current.isEmpty || measure(candidate, face, size) <= width {
                    current = candidate
                } else {
                    lines.append(current)
                    current = token.word
                }
            }
            if !current.isEmpty { lines.append(current) }
            return lines
        }
        let step = max((from - to) / 12, 0.1)
        var size = from
        while size >= to - 0.001 {
            let lines = split(size)
            if lines.count <= maxLines, lines.allSatisfy({ measure($0, face, size) <= width + 0.001 }) { return (lines, size) }
            size -= step
        }
        var lines = split(to)
        if lines.count > maxLines {
            lines = Array(lines.prefix(maxLines - 1)) + [lines.dropFirst(maxLines - 1).joined(separator: " ")]
        }
        return (lines, to)
    }
}
