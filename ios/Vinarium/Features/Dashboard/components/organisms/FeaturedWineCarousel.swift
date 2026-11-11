import SwiftUI

/// The wines to open first, one page each: the bottle on the page's haze and, at
/// its right between its cork and its base, the wine, its drinking window, its
/// stock and price, with its tag and its slot's plate on the bottle's top line,
/// then the three things done with a bottle that is ready: take it out, mark it
/// a favorite, move it.
struct FeaturedWineCarousel: View {
    let items: [Item]
    var onOpen: (String) -> Void
    var onRemove: (String) -> Void
    var onFavorite: (String) -> Void
    var onMove: (String) -> Void

    @State private var selection: String?

    var body: some View {
        VStack(spacing: 16) {
            TabView(selection: $selection) {
                ForEach(items) { item in
                    page(item)
                        .tag(Optional(item.id))
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 320)

            if items.count > 1 {
                dots
            }
        }
        .onAppear { selection = selection ?? items.first?.id }
        .onChange(of: items.map(\.id)) { _, ids in
            if let selection, ids.contains(selection) { return }
            selection = ids.first
        }
    }

    private func page(_ item: Item) -> some View {
        VStack(spacing: 18) {
            Button { onOpen(item.id) } label: {
                HStack(alignment: .top, spacing: 16) {
                    cover(item)
                    details(item)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("featured-wine")

            actions(item)
        }
        .padding(.horizontal, 20)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    /// The bottle alone, no tile behind it: it stands on the page's ambience.
    private func cover(_ item: Item) -> some View {
        BottleArtwork(
            style: item.style, producer: item.producer, name: item.name, vintage: item.vintage,
            appellation: item.appellation, classification: item.classification, height: Self.bottleHeight
        )
        .frame(width: Self.bottleHeight / 3 + 8, height: Self.bottleHeight + 10)
    }

    /// The bottle's height, and where its cork and its base fall in its lane: the
    /// artwork is drawn on a 300-high frame, the glass from 8 to 294.
    private static let bottleHeight: CGFloat = 240
    private static let corkTop: CGFloat = 5 + bottleHeight * 8 / 300
    private static let base: CGFloat = 5 + bottleHeight * 294 / 300

    /// Three blocks stacked on the bottle's base, nothing below it and no gap
    /// between them: the wine, its drinking window close under it, then its stock
    /// and price. The tag and the slot's plate sit on the bottle's top line, the
    /// tag on the leading edge, the plate on the trailing one.
    private func details(_ item: Item) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 0) {
                Text(item.name)
                    .font(.system(size: 24, weight: .bold))
                    .tracking(-0.4)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .padding(.top, 2)
                }
            }
            if let window = item.window {
                DrinkingWindowRail(window: window)
            }
            figures(item)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: Self.base - Self.corkTop, alignment: .bottom)
        .padding(.top, Self.corkTop)
        .overlay(alignment: .top) {
            HStack(alignment: .top, spacing: 8) {
                tag(item)
                Spacer(minLength: 0)
                LocationPlate(position: item.position, style: .page, cellarName: item.cellarName)
            }
        }
    }

    /// Stock and price on two equal columns, as wide as the rail, each centred
    /// in its column.
    private func figures(_ item: Item) -> some View {
        let cells = item.figures
        return HStack(spacing: 0) {
            ForEach(Array(cells.enumerated()), id: \.offset) { index, cell in
                HStack(spacing: 0) {
                    if index > 0 {
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(width: 1)
                    }
                    VStack(alignment: .center, spacing: 2) {
                        Text(cell.value)
                            .font(.system(size: 20, weight: .semibold))
                            .tracking(-0.4)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        cell.label
                            .font(.system(size: 11, weight: .medium))
                            .tracking(0.7)
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity)
                }
                .accessibilityElement(children: .combine)
            }
            ForEach(cells.count..<2, id: \.self) { _ in Color.clear.frame(maxWidth: .infinity) }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func tag(_ item: Item) -> some View {
        Group {
            if item.urgent, let year = item.drinkUntil {
                Text("À ouvrir avant \(String(year))")
            } else {
                Text("Prêt à déguster")
            }
        }
        .font(.system(size: 13, weight: .semibold))
        .lineLimit(1)
        .padding(.horizontal, 10)
        .frame(height: 24)
        .glassEffect(.regular, in: .capsule)
    }

    private func actions(_ item: Item) -> some View {
        HStack(spacing: 10) {
            Button { onRemove(item.id) } label: {
                Label("Sortir de la cave", systemImage: "arrow.up")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .foregroundStyle(Color(.systemBackground))
                    .background(Color.primary, in: .capsule)
                    .contentShape(.capsule)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("featured-remove")

            roundButton(
                title: item.isFavorite ? "Retirer des favoris" : "Ajouter aux favoris",
                systemImage: item.isFavorite ? "heart.fill" : "heart",
                identifier: "featured-favorite"
            ) { onFavorite(item.id) }

            roundButton(title: "Déplacer", systemImage: "arrow.left.arrow.right", identifier: "featured-move") {
                onMove(item.id)
            }
        }
    }

    private func roundButton(
        title: LocalizedStringKey,
        systemImage: String,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .labelStyle(.iconOnly)
                .font(.system(size: 20, weight: .medium))
                .frame(width: 52, height: 52)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityIdentifier(identifier)
    }

    private var dots: some View {
        HStack(spacing: 7) {
            ForEach(items) { item in
                Capsule()
                    .fill(item.id == selection ? Color.primary : Color(.tertiaryLabel))
                    .frame(width: item.id == selection ? 22 : 7, height: 7)
            }
        }
        .animation(.smooth, value: selection)
        .accessibilityHidden(true)
    }
}

extension FeaturedWineCarousel {
    struct Item: Identifiable, Equatable {
        let id: String
        var beverageType: BeverageType = .wine
        var subtype: BeverageSubtype? = nil
        let color: WineColor?
        /// The producer the bottle's label carries.
        let producer: String?
        let name: String
        let vintage: Int?
        /// The domain under the name, nil when the name is the domain itself.
        var domain: String? = nil
        let isFavorite: Bool
        let urgent: Bool
        var drinkFrom: Int? = nil
        let drinkUntil: Int?
        /// The bottle's slot, and its cellar once the household has several.
        let position: String
        var cellarName: String? = nil
        /// How many identical bottles the cellars hold.
        var stock: Int? = nil
        /// What one bottle is worth, in euros.
        var price: Double? = nil
        var labelFamily: BottleArtwork.LabelFamily? = nil
        var labelTraits: BottleArtwork.LabelTraits? = nil
        var appellation: String? = nil
        var classification: String? = nil

        var style: BottleArtwork.Style {
            .of(id: id, beverageType: beverageType, subtype: subtype, color: color, family: labelFamily, traits: labelTraits, vintage: vintage)
        }

        var subtitle: String? {
            let parts = [domain, vintage.map { String($0) }].compactMap(\.self)
            return parts.isEmpty ? nil : parts.joined(separator: " · ")
        }

        /// The drinking window, from its first year (else the vintage) to its last.
        var window: DrinkingWindowRail.Window? {
            guard let until = drinkUntil else { return nil }
            let from = min(drinkFrom ?? vintage ?? until, until)
            return .init(from: from, until: until)
        }

        /// The stock, then what one bottle costs; a figure the wine lacks is left
        /// out. The slot has its own plate.
        var figures: [(value: String, label: Text)] {
            var cells: [(value: String, label: Text)] = []
            if let stock, stock > 0 { cells.append((stock.formatted(), Text("stock"))) }
            if let price { cells.append((Money.formattedFromEur(price, fractionLength: 0), Text("prix"))) }
            return cells
        }
    }
}

#Preview {
    FeaturedWineCarousel(
        items: [
            .init(id: "1", color: .rosé, producer: "Domaine Tempier", name: "Bandol Rosé", vintage: 2023, domain: "Domaine Tempier", isFavorite: false, urgent: true, drinkFrom: 2024, drinkUntil: 2027, position: "B4", cellarName: "Entrée", stock: 3, price: 42, labelFamily: .provence, appellation: "Bandol"),
            .init(id: "2", color: .red, producer: "Château Margaux", name: "Pavillon Rouge du Château Margaux", vintage: 2015, domain: "Château Margaux", isFavorite: true, urgent: false, drinkUntil: nil, position: "A1"),
        ],
        onOpen: { _ in },
        onRemove: { _ in },
        onFavorite: { _ in },
        onMove: { _ in }
    )
}
