import SwiftUI

/// A titled shelf of bottle vignettes sliding sideways, each with its slot, its
/// drinking limit, its stock and its price: the wines ready to drink, or the
/// favorites.
struct BottleShelfSection: View {
    let title: LocalizedStringKey
    let items: [Item]
    var onSeeAll: (() -> Void)?
    var onWineTapped: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeSectionHeader(title: title, onTapped: onSeeAll)
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 12) {
                    ForEach(items) { item in
                        Button { onWineTapped(item.id) } label: {
                            BottleVignette(
                                style: item.style,
                                beverageType: item.beverageType,
                                color: item.color,
                                producer: item.producer,
                                name: item.name,
                                vintage: item.vintage,
                                appellation: item.appellation,
                                classification: item.classification,
                                facts: item.facts
                            )
                            .contentShape(.rect)
                        }
                        .accessibilityLabel(Text(item.name))
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
        /// The slot, drinking limit, stock and price in the vignette's column.
        var facts = BottleVignette.Facts()
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
        items: DashboardPage.Content.sample.ready,
        onSeeAll: {},
        onWineTapped: { _ in }
    )
}

#Preview("Favorites") {
    BottleShelfSection(
        title: "Mes favoris",
        items: DashboardPage.Content.sample.favorites,
        onWineTapped: { _ in }
    )
}
