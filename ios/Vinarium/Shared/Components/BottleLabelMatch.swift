import Foundation

// The label a scanned wine wears: the scan describes the real label (colours,
// type, ornaments) and the bottle is drawn with the closest of the catalogue's
// looks, as validated on the board ("Étiquette lue au scan"). The region keeps
// the family, and so the bottle's shape and glass, unless the label's style has
// no likeness in it: a hand-set natural wine from the Loire then wears the Vin
// de France label. Without traits, a wine keeps the look its id picks.

extension BottleArtwork {
    /// What a label looks like, as the scan read it off the photo.
    struct LabelTraits: Equatable, Codable, Sendable {
        enum Typeface: String, Codable, Sendable {
            case didone, garalde, script, slab, blackletter, hand
            case geometricSans = "geometric-sans"
            case humanistSans = "humanist-sans"
        }

        enum Emblem: String, Codable, Sendable {
            case castle, crest, keys, grapes, mountains, sun, stars, illustration, none
        }

        enum Shape: String, Codable, Sendable {
            case portrait, landscape, square, oval, shield, irregular
        }

        var paper: UInt32
        var ink: UInt32
        var accent: UInt32? = nil
        var metallic = false
        var typeface: Typeface
        var capitals = false
        var frame = false
        var band = false
        var emblem: Emblem = .none
        var shape: Shape = .portrait
    }
}

// MARK: - Matching

extension BottleArtwork.LabelTraits {
    /// The family and look of the catalogue closest to this label. Only families
    /// that bottle the same kind of drink compete: a still wine never takes a
    /// Champagne shield nor a spirit's whisky bottle.
    func closestLook(regional: BottleArtwork.LabelFamily) -> (family: BottleArtwork.LabelFamily, index: Int) {
        var best: (family: BottleArtwork.LabelFamily, index: Int, distance: Double) = (regional, 0, .infinity)
        for family in regional.rivals {
            for (index, look) in BottleArtwork.LabelLook.looks(of: family).enumerated() {
                let distance = self.distance(to: look) + (family == regional ? 0 : Self.familyPenalty)
                if distance < best.distance { best = (family, index, distance) }
            }
        }
        return (best.family, best.index)
    }

    /// What leaving the region's family costs: a look of another family wins only
    /// when the label's style has nothing close in its own.
    static let familyPenalty = 0.45

    /// How far a look is from this label, zero for a perfect likeness. Colour
    /// weighs most, the paper above all, then the type, the ornaments, the frame.
    func distance(to look: BottleArtwork.LabelLook) -> Double {
        let type = look.family.type
        var d = Self.colourDistance(paper, look.paper)
        d += 0.7 * Self.colourDistance(ink, look.ink)
        if let accent { d += 0.25 * Self.colourDistance(accent, look.accent) }
        d += 0.6 * (1 - typeface.likeness(to: type.face))
        d += capitals == type.capitals ? 0 : 0.15
        d += frame == look.framed ? 0 : 0.25
        d += band == look.banded ? 0 : 0.35
        d += 0.35 * (1 - emblem.likeness(to: look.drawnEmblem))
        return d
    }

    /// The perceived gap between two colours, 0 for the same, 1 for black and white.
    static func colourDistance(_ a: UInt32, _ b: UInt32) -> Double {
        let (l1, a1, b1) = lab(a), (l2, a2, b2) = lab(b)
        let delta = ((l1 - l2) * (l1 - l2) + (a1 - a2) * (a1 - a2) + (b1 - b2) * (b1 - b2)).squareRoot()
        return min(delta / 100, 1)
    }

    /// CIE L*a*b* of an sRGB colour, D65 white.
    private static func lab(_ hex: UInt32) -> (Double, Double, Double) {
        func linear(_ c: UInt32) -> Double {
            let v = Double(c) / 255
            return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        let r = linear(hex >> 16 & 0xFF), g = linear(hex >> 8 & 0xFF), b = linear(hex & 0xFF)
        let x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047
        let y = 0.2126 * r + 0.7152 * g + 0.0722 * b
        let z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883
        func f(_ t: Double) -> Double { t > 0.008856 ? cbrt(t) : 7.787 * t + 16 / 116 }
        let fx = f(x), fy = f(y), fz = f(z)
        return (116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz))
    }
}

extension BottleArtwork.LabelTraits.Typeface {
    /// How alike two kinds of type read on a label: a Didot and a Baskerville are
    /// both classic serifs, a Futura and a Gill Sans both sans, a script and a
    /// hand-drawn name both written by hand.
    func likeness(to other: Self) -> Double {
        if self == other { return 1 }
        let pair = Set([self, other])
        return Self.pairs.first { $0.0 == pair }?.1 ?? 0
    }

    private static let pairs: [(Set<Self>, Double)] = [
        ([.didone, .garalde], 0.6), ([.garalde, .slab], 0.5), ([.didone, .slab], 0.3),
        ([.geometricSans, .humanistSans], 0.6), ([.geometricSans, .slab], 0.2),
        ([.script, .hand], 0.5), ([.hand, .geometricSans], 0.4), ([.hand, .humanistSans], 0.3),
        ([.blackletter, .garalde], 0.4), ([.blackletter, .didone], 0.4),
        ([.script, .garalde], 0.3), ([.script, .didone], 0.2),
    ]
}

extension BottleArtwork.LabelTraits.Emblem {
    /// A crest reads like a castle at a glance, a sun like mountains: close
    /// enough to beat a label with no picture at all.
    func likeness(to other: Self) -> Double {
        if self == other { return 1 }
        let pair = Set([self, other])
        if pair == [.castle, .crest] { return 0.5 }
        if pair == [.sun, .mountains] || pair == [.sun, .stars] || pair == [.mountains, .stars] { return 0.4 }
        if pair == [.keys, .crest] { return 0.4 }
        if !pair.contains(.none) { return 0.2 }
        return 0
    }
}

extension BottleArtwork.LabelLook {
    /// The picture a look draws: its own emblem, else the motif its family always
    /// draws (the sun of a Provence veil, the disc of a natural wine).
    var drawnEmblem: BottleArtwork.LabelTraits.Emblem {
        switch emblem {
        case .castle: .castle
        case .crest: .crest
        case .keys: .keys
        case .grapes: .grapes
        case .mountains: .mountains
        case .sun: .sun
        case .stars: .stars
        case .none:
            switch family {
            case .provence: .sun
            case .natural: .illustration
            default: .none
            }
        }
    }
}

extension BottleArtwork.LabelFamily {
    /// The type a family sets its name in, and whether in capitals.
    var type: (face: BottleArtwork.LabelTraits.Typeface, capitals: Bool) {
        switch self {
        case .chateau, .champagne, .alsace, .spain: (.didone, false)
        case .italy, .spirit: (.didone, true)
        case .burgundy, .south, .rhone: (.garalde, true)
        case .portugal: (.garalde, false)
        case .sweet: (.script, false)
        case .provence, .natural, .newWorld: (.geometricSans, false)
        case .sparkling: (.geometricSans, true)
        case .loire, .germany: (.humanistSans, false)
        }
    }

    /// The families a scanned label may move to from this one: those that bottle
    /// the same kind of drink.
    var rivals: [Self] {
        switch self {
        case .spirit: [.spirit]
        case .champagne, .sparkling: [.champagne, .sparkling]
        default: Self.allCases.filter { ![.spirit, .champagne, .sparkling].contains($0) }
        }
    }
}

// MARK: - API

extension BottleArtwork.LabelTraits {
    init?(_ f: VinariumGraphQL.LabelTraitsFields?) {
        guard let f, let paper = Self.hex(f.paper), let ink = Self.hex(f.ink),
              let typeface = f.typeface.value.flatMap({ Typeface(graphql: $0) })
        else { return nil }
        self.init(
            paper: paper, ink: ink, accent: f.accent.flatMap(Self.hex), metallic: f.metallic,
            typeface: typeface, capitals: f.capitals, frame: f.frame, band: f.band,
            emblem: f.emblem.value.flatMap { Emblem(graphql: $0) } ?? .none,
            shape: f.shape.value.flatMap { Shape(graphql: $0) } ?? .portrait
        )
    }

    /// The traits as `addBeverage` takes them back, unchanged.
    var graphQLInput: VinariumGraphQL.LabelTraitsInput {
        VinariumGraphQL.LabelTraitsInput(
            accent: accent.map { .some(Self.hexString($0)) } ?? .none,
            band: band,
            capitals: capitals,
            emblem: .case(emblem.graphql),
            frame: frame,
            ink: Self.hexString(ink),
            metallic: metallic,
            paper: Self.hexString(paper),
            shape: .case(shape.graphql),
            typeface: .case(typeface.graphql)
        )
    }

    static func hex(_ string: String) -> UInt32? {
        guard string.count == 7, string.hasPrefix("#") else { return nil }
        return UInt32(string.dropFirst(), radix: 16)
    }

    static func hexString(_ value: UInt32) -> String { String(format: "#%06x", value) }
}

extension BottleArtwork.LabelTraits.Typeface {
    init?(graphql: VinariumGraphQL.LabelTypeface) {
        switch graphql {
        case .didone: self = .didone
        case .garalde: self = .garalde
        case .script: self = .script
        case .geometricSans: self = .geometricSans
        case .humanistSans: self = .humanistSans
        case .slab: self = .slab
        case .blackletter: self = .blackletter
        case .hand: self = .hand
        }
    }

    var graphql: VinariumGraphQL.LabelTypeface {
        switch self {
        case .didone: .didone
        case .garalde: .garalde
        case .script: .script
        case .geometricSans: .geometricSans
        case .humanistSans: .humanistSans
        case .slab: .slab
        case .blackletter: .blackletter
        case .hand: .hand
        }
    }
}

extension BottleArtwork.LabelTraits.Emblem {
    init?(graphql: VinariumGraphQL.LabelEmblem) {
        switch graphql {
        case .castle: self = .castle
        case .crest: self = .crest
        case .keys: self = .keys
        case .grapes: self = .grapes
        case .mountains: self = .mountains
        case .sun: self = .sun
        case .stars: self = .stars
        case .illustration: self = .illustration
        case .none: self = .none
        }
    }

    var graphql: VinariumGraphQL.LabelEmblem {
        switch self {
        case .castle: .castle
        case .crest: .crest
        case .keys: .keys
        case .grapes: .grapes
        case .mountains: .mountains
        case .sun: .sun
        case .stars: .stars
        case .illustration: .illustration
        case .none: .none
        }
    }
}

extension BottleArtwork.LabelTraits.Shape {
    init?(graphql: VinariumGraphQL.LabelShape) {
        switch graphql {
        case .portrait: self = .portrait
        case .landscape: self = .landscape
        case .square: self = .square
        case .oval: self = .oval
        case .shield: self = .shield
        case .irregular: self = .irregular
        }
    }

    var graphql: VinariumGraphQL.LabelShape {
        switch self {
        case .portrait: .portrait
        case .landscape: .landscape
        case .square: .square
        case .oval: .oval
        case .shield: .shield
        case .irregular: .irregular
        }
    }
}
