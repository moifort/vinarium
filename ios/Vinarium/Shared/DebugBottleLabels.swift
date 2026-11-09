#if DEBUG
import SwiftUI

/// The label families side by side, each on a real wine, then the six looks of the
/// château: the catalogue the board's "Étiquettes de la bouteille" artboard shows,
/// drawn by the app. Opened from the debug gallery (`-debugScreen bottleLabels`).
struct DebugBottleLabels: View {
    struct Sample: Identifiable {
        let id: String
        let family: BottleArtwork.LabelFamily
        var beverageType: BeverageType = .wine
        var subtype: BeverageSubtype? = nil
        let color: WineColor?
        let producer: String?
        let name: String
        let vintage: Int?
        var appellation: String? = nil
        var classification: String? = nil

        func style(look index: Int? = nil) -> BottleArtwork.Style {
            let style = BottleArtwork.Style.of(
                id: id, beverageType: beverageType, subtype: subtype, color: color, family: family, vintage: vintage
            )
            guard let index else { return style }
            var look = BottleArtwork.LabelLook.looks(of: family)[index]
            look.aged = style.look.aged
            return BottleArtwork.Style(shape: style.shape, glass: style.glass, capsule: look.capsule, look: look, kind: style.kind)
        }
    }

    static let families: [Sample] = [
        .init(id: "talbot", family: .chateau, color: .red, producer: nil, name: "Château Talbot", vintage: 2016, appellation: "Saint-Julien", classification: "4e Grand Cru Classé"),
        .init(id: "roulot", family: .burgundy, color: .white, producer: "Domaine Roulot", name: "Meursault 1er Cru Les Charmes", vintage: 2020, appellation: "Meursault", classification: "1er Cru"),
        .init(id: "peters", family: .champagne, subtype: .sparkling, color: .white, producer: "Pierre Péters", name: "Blanc de Blancs", vintage: 2017, appellation: "Champagne", classification: "Grand Cru"),
        .init(id: "tempier", family: .provence, color: .rosé, producer: "Domaine Tempier", name: "Bandol Rosé", vintage: 2023, appellation: "Bandol"),
        .init(id: "santaduc", family: .south, color: .red, producer: "Domaine Santa Duc", name: "Gigondas", vintage: 2019, appellation: "Gigondas"),
        .init(id: "weinbach", family: .alsace, color: .white, producer: "Weinbach", name: "Riesling Schlossberg", vintage: 2021, appellation: "Alsace", classification: "Grand Cru"),
        .init(id: "rieussec", family: .sweet, subtype: .sweet, color: .white, producer: nil, name: "Château Rieussec", vintage: 2015, appellation: "Sauternes", classification: "1er Cru Classé"),
        .init(id: "ecu", family: .natural, color: .red, producer: "Domaine de l'Écu", name: "Granite", vintage: 2022, appellation: "Vin de France"),
        .init(id: "conterno", family: .italy, color: .red, producer: "Giacomo Conterno", name: "Barolo Cascina Francia", vintage: 2019, appellation: "Barolo"),
        .init(id: "talisker", family: .spirit, beverageType: .spirit, subtype: .whisky, color: nil, producer: "Talisker", name: "Isle of Skye 10 ans", vintage: nil),
    ]

    static let chateaux: [Sample] = [
        .init(id: "c0", family: .chateau, color: .red, producer: nil, name: "Château Talbot", vintage: 2016, appellation: "Saint-Julien", classification: "4e Grand Cru Classé"),
        .init(id: "c1", family: .chateau, color: .red, producer: nil, name: "Château Gloria", vintage: 2018, appellation: "Saint-Julien"),
        .init(id: "c2", family: .chateau, color: .red, producer: nil, name: "Château Gruaud Larose", vintage: 1990, appellation: "Saint-Julien", classification: "2e Grand Cru Classé"),
        .init(id: "c3", family: .chateau, color: .red, producer: nil, name: "Château Pédesclaux", vintage: 2019, appellation: "Pauillac", classification: "5e Grand Cru Classé"),
        .init(id: "c4", family: .chateau, color: .red, producer: nil, name: "Château Montrose", vintage: 2010, appellation: "Saint-Estèphe", classification: "2e Grand Cru Classé"),
        .init(id: "c5", family: .chateau, color: .red, producer: nil, name: "Château Lynch-Bages", vintage: 2015, appellation: "Pauillac", classification: "5e Grand Cru Classé"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Dix familles").font(.system(size: 22, weight: .bold))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 14) {
                    ForEach(Self.families) { sample in
                        bottle(sample, style: sample.style(look: 0), height: 222)
                    }
                }
                Text("Six looks du château").font(.system(size: 22, weight: .bold))
                HStack(spacing: 4) {
                    ForEach(Array(Self.chateaux.enumerated()), id: \.offset) { index, sample in
                        bottle(sample, style: sample.style(look: index), height: 186)
                    }
                }
            }
            .padding(16)
        }
        .background(BottleBackdrop(beverageType: .wine, color: .red).ignoresSafeArea())
        .foregroundStyle(.white)
    }

    private func bottle(_ sample: Sample, style: BottleArtwork.Style, height: CGFloat) -> some View {
        BottleArtwork(
            style: style, producer: sample.producer, name: sample.name, vintage: sample.vintage,
            appellation: sample.appellation, classification: sample.classification, height: height
        )
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    DebugBottleLabels()
}
#endif
