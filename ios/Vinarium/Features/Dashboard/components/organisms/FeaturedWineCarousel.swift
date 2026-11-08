import SwiftUI

/// The wines to open first, one page each: the bottle on its tinted ground, why it
/// is due, where it stands, the notes kept on it, then the three things done with
/// a bottle that is ready: take it out, mark it a favorite, move it.
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
            .frame(height: 270)

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
                HStack(alignment: .top, spacing: 18) {
                    cover(item)
                    VStack(alignment: .leading, spacing: 0) {
                        tag(item)
                        Text(item.name)
                            .font(.system(size: 24, weight: .bold))
                            .tracking(-0.4)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 10)
                        if let subtitle = item.subtitle {
                            Text(subtitle)
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .padding(.top, 2)
                        }
                        if let notes = item.notes {
                            Text(notes)
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                                .lineLimit(4)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 10)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
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

    private func cover(_ item: Item) -> some View {
        ZStack {
            BottleBackdrop(beverageType: item.beverageType, color: item.color)
            BottleArtwork(style: item.style, producer: item.producer, name: item.name, vintage: item.vintage, height: 184)
        }
        .frame(width: 132, height: 198)
        .clipShape(.rect(cornerRadius: 6))
        .shadow(color: .black.opacity(0.28), radius: 9, y: 6)
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
        let producer: String?
        let name: String
        let vintage: Int?
        let notes: String?
        let isFavorite: Bool
        let urgent: Bool
        let drinkUntil: Int?
        /// Where the bottle stands: its slot, with its cellar once there are several.
        let place: String

        var style: BottleArtwork.Style {
            .of(id: id, beverageType: beverageType, subtype: subtype, color: color)
        }

        var subtitle: String? {
            [producer, vintage.map { String($0) }, place].compactMap(\.self).joined(separator: " · ")
        }
    }
}

#Preview {
    FeaturedWineCarousel(
        items: [
            .init(id: "1", color: .rosé, producer: "Domaine Tempier", name: "Bandol Rosé", vintage: 2023, notes: "Un rosé de garde qui gagne à être servi à 12 °C, avec une cuisine provençale ou des grillades.", isFavorite: false, urgent: true, drinkUntil: 2027, place: "B4"),
            .init(id: "2", color: .red, producer: "Château Margaux", name: "Pavillon Rouge", vintage: 2015, notes: nil, isFavorite: true, urgent: false, drinkUntil: nil, place: "A1"),
        ],
        onOpen: { _ in },
        onRemove: { _ in },
        onFavorite: { _ in },
        onMove: { _ in }
    )
}
