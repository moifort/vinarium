#if DEBUG
import SwiftUI

/// The whole label catalogue, the nine looks of each family on real wines: what the
/// board's "Étiquettes de la bouteille" artboard shows, drawn by the app. Opened
/// from the debug gallery (`-debugScreen bottleLabels`); `-debugLabelFamilies
/// loire,rhone` keeps only the families named, `-debugLabelLegible YES` shows the
/// legible labels as the home vignettes crop them.
struct DebugBottleLabels: View {
    struct Sample {
        var beverageType: BeverageType = .wine
        var subtype: BeverageSubtype? = nil
        let color: WineColor?
        let producer: String?
        let name: String
        let vintage: Int?
        var appellation: String? = nil
        var classification: String? = nil
    }

    struct Family: Identifiable {
        let family: BottleArtwork.LabelFamily
        let title: String
        let samples: [Sample]
        var id: String { family.rawValue }
    }

    static let catalogue: [Family] = [
        .init(family: .chateau, title: "Château bordelais", samples: [
            .init(color: .red, producer: nil, name: "Château Talbot", vintage: 2016, appellation: "Saint-Julien", classification: "4e Grand Cru Classé"),
            .init(color: .red, producer: nil, name: "Château Gruaud Larose", vintage: 1990, appellation: "Saint-Julien", classification: "2e Grand Cru Classé"),
            .init(color: .red, producer: nil, name: "Château Lynch-Bages", vintage: 2015, appellation: "Pauillac", classification: "5e Grand Cru Classé"),
        ]),
        .init(family: .burgundy, title: "Domaine bourguignon", samples: [
            .init(color: .white, producer: "Domaine Roulot", name: "Meursault 1er Cru Les Charmes", vintage: 2020, appellation: "Meursault", classification: "1er Cru"),
            .init(color: .red, producer: "Domaine Fourrier", name: "Gevrey-Chambertin Vieille Vigne", vintage: 2019, appellation: "Gevrey-Chambertin"),
            .init(color: .white, producer: "William Fèvre", name: "Chablis Les Clos", vintage: 2021, appellation: "Chablis", classification: "Grand Cru"),
        ]),
        .init(family: .champagne, title: "Écusson de Champagne", samples: [
            .init(subtype: .sparkling, color: .white, producer: "Pierre Péters", name: "Blanc de Blancs", vintage: 2017, appellation: "Champagne", classification: "Grand Cru"),
            .init(subtype: .sparkling, color: .white, producer: "Bollinger", name: "Special Cuvée", vintage: nil, appellation: "Champagne", classification: "Brut"),
            .init(subtype: .sparkling, color: .rosé, producer: "Billecart-Salmon", name: "Brut Rosé", vintage: nil, appellation: "Champagne"),
        ]),
        .init(family: .provence, title: "Voile de Provence", samples: [
            .init(color: .rosé, producer: "Domaine Tempier", name: "Bandol Rosé", vintage: 2023, appellation: "Bandol"),
            .init(color: .rosé, producer: "Château d'Esclans", name: "Whispering Angel", vintage: 2024, appellation: "Côtes de Provence"),
            .init(color: .rosé, producer: "Domaine Ott", name: "Clos Mireille", vintage: 2023, appellation: "Côtes de Provence"),
        ]),
        .init(family: .south, title: "Sud", samples: [
            .init(color: .red, producer: "Mas Jullien", name: "Terrasses du Larzac", vintage: 2020, appellation: "Terrasses du Larzac"),
            .init(color: .red, producer: "Domaine Gauby", name: "Vieilles Vignes", vintage: 2020, appellation: "Côtes Catalanes"),
            .init(color: .red, producer: "Grange des Pères", name: "Grange des Pères", vintage: 2019, appellation: "Pays d'Hérault"),
        ]),
        .init(family: .alsace, title: "Alsace", samples: [
            .init(color: .white, producer: "Weinbach", name: "Riesling Schlossberg", vintage: 2021, appellation: "Alsace", classification: "Grand Cru"),
            .init(color: .white, producer: "Zind-Humbrecht", name: "Gewurztraminer Heimbourg", vintage: 2020, appellation: "Alsace"),
            .init(color: .white, producer: "Trimbach", name: "Riesling Clos Sainte Hune", vintage: 2016, appellation: "Alsace"),
        ]),
        .init(family: .sweet, title: "Vins doux", samples: [
            .init(subtype: .sweet, color: .white, producer: nil, name: "Château Rieussec", vintage: 2015, appellation: "Sauternes", classification: "1er Cru Classé"),
            .init(subtype: .sweet, color: .white, producer: nil, name: "Château d'Yquem", vintage: 2001, appellation: "Sauternes", classification: "1er Cru Supérieur"),
            .init(subtype: .sweet, color: .white, producer: "Domaine Huet", name: "Le Haut-Lieu Moelleux", vintage: 2018, appellation: "Vouvray"),
        ]),
        .init(family: .natural, title: "Vin de France", samples: [
            .init(color: .red, producer: "Domaine de l'Écu", name: "Granite", vintage: 2022, appellation: "Vin de France"),
            .init(color: .red, producer: "Domaine Gramenon", name: "La Sagesse", vintage: 2021, appellation: "Vin de France"),
            .init(color: .white, producer: "Les Vins Pirouettes", name: "Éric le Mafieux", vintage: 2022, appellation: "Vin de France"),
        ]),
        .init(family: .italy, title: "Italie", samples: [
            .init(color: .red, producer: "Giacomo Conterno", name: "Barolo Cascina Francia", vintage: 2019, appellation: "Barolo"),
            .init(color: .red, producer: "Tenuta San Guido", name: "Sassicaia", vintage: 2018, appellation: "Bolgheri Sassicaia"),
            .init(color: .red, producer: "Castello di Ama", name: "San Lorenzo", vintage: 2019, appellation: "Chianti Classico", classification: "Gran Selezione"),
        ]),
        .init(family: .spirit, title: "Spiritueux", samples: [
            .init(beverageType: .spirit, subtype: .whisky, color: nil, producer: "Talisker", name: "Isle of Skye 10 ans", vintage: nil),
            .init(beverageType: .spirit, subtype: .rum, color: nil, producer: "Clément", name: "Rhum Vieux Agricole", vintage: 2010),
            .init(beverageType: .spirit, color: nil, producer: "Delamain", name: "Pale & Dry XO", vintage: nil),
        ]),
        .init(family: .loire, title: "Loire", samples: [
            .init(color: .white, producer: "Didier Dagueneau", name: "Silex", vintage: 2020, appellation: "Pouilly-Fumé"),
            .init(color: .red, producer: "Clos Rougeard", name: "Le Bourg", vintage: 2016, appellation: "Saumur-Champigny"),
            .init(color: .white, producer: "François Chidaine", name: "Les Argiles", vintage: 2021, appellation: "Vouvray"),
        ]),
        .init(family: .rhone, title: "Rhône", samples: [
            .init(color: .red, producer: "Domaine Santa Duc", name: "Gigondas", vintage: 2019, appellation: "Gigondas"),
            .init(color: .red, producer: "Château de Beaucastel", name: "Hommage à Jacques Perrin", vintage: 2017, appellation: "Châteauneuf-du-Pape"),
            .init(color: .red, producer: "Domaine Jamet", name: "Côte-Rôtie", vintage: 2018, appellation: "Côte-Rôtie"),
        ]),
        .init(family: .spain, title: "Espagne", samples: [
            .init(color: .red, producer: "La Rioja Alta", name: "Gran Reserva 904", vintage: 2015, appellation: "Rioja", classification: "Gran Reserva"),
            .init(color: .red, producer: "Vega Sicilia", name: "Único", vintage: 2012, appellation: "Ribera del Duero"),
            .init(color: .red, producer: "CVNE", name: "Imperial", vintage: 2018, appellation: "Rioja", classification: "Reserva"),
        ]),
        .init(family: .portugal, title: "Portugal", samples: [
            .init(color: .red, producer: "Quinta do Crasto", name: "Vinhas Velhas", vintage: 2019, appellation: "Douro", classification: "Reserva"),
            .init(color: .white, producer: "Niepoort", name: "Redoma Branco", vintage: 2021, appellation: "Douro"),
            .init(color: .red, producer: "Luis Pato", name: "Vinha Pan", vintage: 2017, appellation: "Bairrada"),
        ]),
        .init(family: .germany, title: "Allemagne et Autriche", samples: [
            .init(color: .white, producer: "Egon Müller", name: "Scharzhofberger Riesling", vintage: 2021, appellation: "Mosel", classification: "Kabinett"),
            .init(color: .white, producer: "Dönnhoff", name: "Hermannshöhle Riesling", vintage: 2020, appellation: "Nahe", classification: "Grosses Gewächs"),
            .init(color: .white, producer: "F.X. Pichler", name: "Grüner Veltliner Loibner Berg", vintage: 2021, appellation: "Wachau", classification: "Smaragd"),
        ]),
        .init(family: .newWorld, title: "Nouveau Monde", samples: [
            .init(color: .red, producer: "Ridge", name: "Monte Bello", vintage: 2016, appellation: "Santa Cruz Mountains"),
            .init(color: .white, producer: "Cloudy Bay", name: "Sauvignon Blanc", vintage: 2023, appellation: "Marlborough"),
            .init(color: .red, producer: "Catena Zapata", name: "Adrianna Vineyard Malbec", vintage: 2018, appellation: "Mendoza"),
        ]),
        .init(family: .sparkling, title: "Effervescents", samples: [
            .init(subtype: .sparkling, color: .white, producer: "Bailly Lapierre", name: "Réserve Brut", vintage: nil, appellation: "Crémant de Bourgogne"),
            .init(subtype: .sparkling, color: .white, producer: "Recaredo", name: "Terrers", vintage: 2017, appellation: "Corpinnat", classification: "Brut Nature"),
            .init(subtype: .sparkling, color: .white, producer: "Bisol", name: "Cartizze", vintage: nil, appellation: "Prosecco Superiore", classification: "Dry"),
        ]),
    ]

    private var shown: [Family] {
        let names = (UserDefaults.standard.string(forKey: "debugLabelFamilies") ?? "")
            .split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        return names.isEmpty ? Self.catalogue : Self.catalogue.filter { names.contains($0.family.rawValue.lowercased()) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ForEach(shown) { family in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(family.title).font(.system(size: 22, weight: .bold))
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: legible ? 2 : 3), spacing: 12) {
                            ForEach(0..<9, id: \.self) { index in
                                if legible {
                                    vignette(family.samples[index % 3], family: family.family, look: index)
                                } else {
                                    bottle(family.samples[index % 3], family: family.family, look: index)
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(BottleBackdrop(beverageType: .wine, color: .red).ignoresSafeArea())
        .foregroundStyle(.white)
    }

    private var legible: Bool { UserDefaults.standard.bool(forKey: "debugLabelLegible") }

    private func style(_ sample: Sample, family: BottleArtwork.LabelFamily, look index: Int) -> BottleArtwork.Style {
        let base = BottleArtwork.Style.of(
            id: "\(family.rawValue)-\(index)", beverageType: sample.beverageType, subtype: sample.subtype,
            color: sample.color, family: family, vintage: sample.vintage
        )
        var look = BottleArtwork.LabelLook.looks(of: family)[index]
        look.aged = base.look.aged
        return BottleArtwork.Style(shape: base.shape, glass: base.glass, capsule: look.capsule, look: look, kind: base.kind)
    }

    private func vignette(_ sample: Sample, family: BottleArtwork.LabelFamily, look index: Int) -> some View {
        BottleVignette(
            style: style(sample, family: family, look: index), beverageType: sample.beverageType, color: sample.color,
            producer: sample.producer, name: sample.name, vintage: sample.vintage,
            appellation: sample.appellation, classification: sample.classification, facts: .init()
        )
        .frame(maxWidth: .infinity)
    }

    private func bottle(_ sample: Sample, family: BottleArtwork.LabelFamily, look index: Int) -> some View {
        let base = BottleArtwork.Style.of(
            id: "\(family.rawValue)-\(index)", beverageType: sample.beverageType, subtype: sample.subtype,
            color: sample.color, family: family, vintage: sample.vintage
        )
        var look = BottleArtwork.LabelLook.looks(of: family)[index]
        look.aged = base.look.aged
        let style = BottleArtwork.Style(shape: base.shape, glass: base.glass, capsule: look.capsule, look: look, kind: base.kind)
        return BottleArtwork(
            style: style, producer: sample.producer, name: sample.name, vintage: sample.vintage,
            appellation: sample.appellation, classification: sample.classification, height: 230
        )
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    DebugBottleLabels()
}
#endif
