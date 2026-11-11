#if DEBUG
import SwiftUI

/// The board's "Étiquette lue au scan" drawn by the app: four labels as the scan
/// reads them, the bottle a wine gets today from its id, and the one the traits
/// pick. Opened from the debug gallery (`-debugScreen labelMatch`).
struct DebugLabelMatch: View {
    struct Example: Identifiable {
        let title: String
        let family: BottleArtwork.LabelFamily
        let color: WineColor
        let producer: String?
        let name: String
        let vintage: Int
        let appellation: String
        let traits: BottleArtwork.LabelTraits
        var id: String { title }
    }

    static let examples: [Example] = [
        .init(
            title: "Bordeaux classique", family: .chateau, color: .red, producer: nil,
            name: "Château Varenne", vintage: 2018, appellation: "Pauillac",
            traits: .init(paper: 0x18181A, ink: 0xD4B25C, metallic: true, typeface: .didone, capitals: true, frame: true)
        ),
        .init(
            title: "Bourgogne épurée", family: .burgundy, color: .red, producer: "Domaine Lavergne",
            name: "Chambolle-Musigny Vieilles Vignes", vintage: 2019, appellation: "Chambolle-Musigny",
            traits: .init(paper: 0xFDFDFB, ink: 0x121212, typeface: .garalde)
        ),
        .init(
            title: "Loire nature", family: .loire, color: .white, producer: "Clos des Grives",
            name: "Le Merle", vintage: 2022, appellation: "Vouvray",
            traits: .init(paper: 0xF0CF6E, ink: 0x1C1A17, typeface: .geometricSans, capitals: true, emblem: .illustration)
        ),
        .init(
            title: "Rhône à bandeau", family: .rhone, color: .red, producer: "Domaine des Aiguiers",
            name: "Gigondas", vintage: 2019, appellation: "Gigondas",
            traits: .init(paper: 0xE6D8BC, ink: 0x2B2016, accent: 0x5A1622, typeface: .garalde, capitals: true, frame: true, band: true, emblem: .keys)
        ),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Étiquette lue au scan")
                    .font(.title2.bold())
                ForEach(Self.examples) { example in
                    row(example)
                }
            }
            .padding(16)
        }
        .background(BottleBackdrop(beverageType: .wine, color: .red).ignoresSafeArea())
        .foregroundStyle(.white)
    }

    private func row(_ example: Example) -> some View {
        let today = style(example, traits: nil)
        let scanned = style(example, traits: example.traits)
        return VStack(alignment: .leading, spacing: 8) {
            Text(example.title).font(.headline)
            HStack(alignment: .bottom, spacing: 12) {
                swatch(example.traits)
                bottle(example, style: today, caption: "Aujourd’hui", detail: lookName(today))
                    .opacity(0.6)
                bottle(example, style: scanned, caption: "Avec le scan", detail: lookName(scanned))
            }
        }
    }

    private func style(_ example: Example, traits: BottleArtwork.LabelTraits?) -> BottleArtwork.Style {
        .of(
            id: example.title, beverageType: .wine, subtype: nil, color: example.color,
            family: example.family, traits: traits, vintage: example.vintage
        )
    }

    private func lookName(_ style: BottleArtwork.Style) -> String {
        let family = style.look.family
        let index = BottleArtwork.LabelLook.looks(of: family).firstIndex { $0.paper == style.look.paper && $0.ink == style.look.ink && $0.emblem == style.look.emblem && $0.banded == style.look.banded } ?? 0
        return "\(family.rawValue) · \(index + 1)"
    }

    private func bottle(_ example: Example, style: BottleArtwork.Style, caption: String, detail: String) -> some View {
        VStack(spacing: 6) {
            BottleArtwork(
                style: style, producer: example.producer, name: example.name, vintage: example.vintage,
                appellation: example.appellation, height: 190
            )
            Text(caption).font(.caption.weight(.semibold))
            Text(detail).font(.caption2).foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }

    /// The label as the scan describes it: its paper, its ink, a few words.
    private func swatch(_ traits: BottleArtwork.LabelTraits) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: traits.paper))
                .overlay(
                    Text("Aa")
                        .font(.system(size: 22, weight: .bold, design: traits.typeface == .geometricSans || traits.typeface == .humanistSans ? .default : .serif))
                        .foregroundStyle(Color(hex: traits.ink))
                )
                .overlay(alignment: .bottom) {
                    if traits.band { Rectangle().fill(Color(hex: traits.accent ?? traits.ink)).frame(height: 8).padding(.bottom, 10) }
                }
                .frame(width: 84, height: 104)
            Group {
                Text(traits.typeface.rawValue)
                Text([traits.frame ? "cadre" : nil, traits.band ? "bandeau" : nil, traits.emblem == .none ? nil : traits.emblem.rawValue]
                    .compactMap { $0 }.joined(separator: ", "))
            }
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.75))
        }
        .frame(width: 92, alignment: .leading)
    }
}

#Preview {
    DebugLabelMatch()
}
#endif
