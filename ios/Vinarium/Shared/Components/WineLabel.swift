import SwiftUI

/// The opening's label: Vinarium dressed as a château's own, on cream paper
/// framed in a double gold rule, the app icon standing in for the engraving of
/// the house, and the vintage it is handed.
///
/// The words stay in French in every language the app speaks, as they would
/// on any bottle of French wine: the label is a picture, not copy.
struct WineLabel: View {
    var vintage: Int

    /// Every type and ornament size, as a fraction of the one it was drawn at.
    private static let scale: CGFloat = 1.0
    /// Every space between the lines, likewise: the air that makes the label
    /// a tall rectangle, as on a bottle, rather than a square.
    private static let air: CGFloat = 1.4
    /// Narrow enough that the wine shows on either side.
    static let width: CGFloat = 280
    private static let iconSize: CGFloat = 78 * scale
    private static let paper = Color(red: 0.95, green: 0.92, blue: 0.85)
    private static let ink = Color(red: 0.29, green: 0.05, blue: 0.10)
    private static let gold = Color(red: 0.72, green: 0.57, blue: 0.25)

    var body: some View {
        VStack(spacing: 0) {
            smallCaps("Grand Vin")
                .padding(.bottom, 14 * Self.air)
            Image("LaunchIcon")
                .resizable()
                .frame(width: Self.iconSize, height: Self.iconSize)
                .clipShape(RoundedRectangle(cornerRadius: Self.iconSize * 0.2237, style: .continuous))
                .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                .padding(.bottom, 16 * Self.air)
            Text(verbatim: "Domaine")
                .font(.custom("Didot-Italic", size: 15 * Self.scale))
                .foregroundStyle(Self.ink.opacity(0.8))
            Text(verbatim: "VINARIUM")
                .font(.custom("Didot", size: 34 * Self.scale))
                .tracking(3 * Self.scale)
                .foregroundStyle(Self.ink)
                .padding(.bottom, 6 * Self.air)
            Text(verbatim: "Appellation Cave Contrôlée")
                .font(.custom("Didot-Italic", size: 13 * Self.scale))
                .foregroundStyle(Self.ink.opacity(0.75))
            rule
                .padding(.vertical, 12 * Self.air)
            Text(verbatim: String(vintage))
                .font(.custom("Didot", size: 30 * Self.scale))
                .monospacedDigit()
                .tracking(5 * Self.scale)
                .foregroundStyle(Self.gold)
                .padding(.bottom, 14 * Self.air)
            smallCaps("Mis en bouteille au domaine")
            Text(verbatim: "75 cl · 13,5 % vol.")
                .font(.custom("Didot", size: 12 * Self.scale))
                .foregroundStyle(Self.ink.opacity(0.6))
                .padding(.top, 4 * Self.air)
        }
        .padding(.vertical, 26 * Self.air)
        // Clear of the double rule.
        .padding(.horizontal, 22 * Self.scale)
        .frame(width: Self.width)
        .background(Self.paper)
        // A double gold rule, inset from the edge, as on a château's label.
        .overlay {
            Rectangle()
                .strokeBorder(Self.gold, lineWidth: 1.5 * Self.scale)
                .padding(7 * Self.scale)
        }
        .overlay {
            Rectangle()
                .strokeBorder(Self.gold.opacity(0.7), lineWidth: 0.5)
                .padding(11 * Self.scale)
        }
        .shadow(color: .black.opacity(0.5), radius: 24 * Self.scale, y: 12 * Self.scale)
    }

    private func smallCaps(_ text: String) -> some View {
        Text(verbatim: text.uppercased())
            .font(.custom("Didot", size: 10.5 * Self.scale))
            .tracking(1.6 * Self.scale)
            .foregroundStyle(Self.ink.opacity(0.7))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    /// A short gold rule with a diamond in its middle.
    private var rule: some View {
        HStack(spacing: 8 * Self.scale) {
            Rectangle().fill(Self.gold).frame(width: 40 * Self.scale, height: 0.75)
            Rectangle().fill(Self.gold).frame(width: 5 * Self.scale, height: 5 * Self.scale).rotationEffect(.degrees(45))
            Rectangle().fill(Self.gold).frame(width: 40 * Self.scale, height: 0.75)
        }
    }
}

#Preview {
    WineLabel(vintage: 2026)
        .padding(40)
        .background(Color(red: 0.2, green: 0.02, blue: 0.05))
}
