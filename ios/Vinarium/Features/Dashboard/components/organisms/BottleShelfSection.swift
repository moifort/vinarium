import SwiftUI

/// A titled shelf of bottle vignettes sliding sideways, the wine's name under each:
/// the wines ready to drink, with their slot, or the favorites, with their price.
struct BottleShelfSection: View {
    let title: LocalizedStringKey
    let items: [Item]
    var captionKind: BottleVignette.CaptionKind = .position
    var onSeeAll: (() -> Void)?
    var onWineTapped: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeSectionHeader(title: title, onTapped: onSeeAll)
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 12) {
                    ForEach(items) { item in
                        Button { onWineTapped(item.id) } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                BottleVignette(
                                    style: item.style,
                                    beverageType: item.beverageType,
                                    color: item.color,
                                    producer: item.producer,
                                    name: item.name,
                                    vintage: item.vintage,
                                    caption: item.caption,
                                    captionKind: captionKind,
                                    appellation: item.appellation,
                                    classification: item.classification
                                )
                                Text(item.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .lineLimit(2, reservesSpace: true)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(width: BottleVignette.size.width)
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .scrollTargetLayout()
                // Room for the vignettes' shadow, which the scroll view would clip.
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .padding(.vertical, -8)
        }
    }
}

extension BottleShelfSection {
    struct Item: Identifiable, Equatable {
        let id: String
        var beverageType: BeverageType = .wine
        var subtype: BeverageSubtype? = nil
        let color: WineColor?
        let producer: String?
        let name: String
        let vintage: Int?
        /// The slot or the price in the vignette's corner.
        let caption: String?
        var labelFamily: BottleArtwork.LabelFamily? = nil
        var appellation: String? = nil
        var classification: String? = nil

        var style: BottleArtwork.Style {
            .of(id: id, beverageType: beverageType, subtype: subtype, color: color, family: labelFamily, vintage: vintage)
        }
    }
}

#Preview("Ready to drink") {
    BottleShelfSection(
        title: "Prêt à déguster",
        items: [
            .init(id: "1", color: .white, producer: "Vacheron", name: "Sancerre Les Monts Damnés", vintage: 2022, caption: "B1"),
            .init(id: "2", color: .white, producer: "Château des Rontets", name: "Pouilly-Fuissé Les Crays", vintage: 2021, caption: "C3"),
            .init(id: "3", subtype: .sparkling, color: .white, producer: "Pierre Péters", name: "Champagne Blanc de Blancs", vintage: 2017, caption: "E1"),
        ],
        onSeeAll: {},
        onWineTapped: { _ in }
    )
}

#Preview("Favorites") {
    BottleShelfSection(
        title: "Mes favoris",
        items: [
            .init(id: "4", color: .red, producer: "La Rioja Alta", name: "Rioja Gran Reserva 904", vintage: 2011, caption: "62 €"),
            .init(id: "5", color: .white, producer: "Domaine Roulot", name: "Meursault Les Charmes", vintage: 2020, caption: nil),
        ],
        captionKind: .price,
        onWineTapped: { _ in }
    )
}
