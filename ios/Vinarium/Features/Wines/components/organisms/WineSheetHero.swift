import SwiftUI

/// The top of a wine's sheet, as the TV app opens a film: the bottle turning on
/// itself on the left, over the wine's colours, and beside it, set on the bottle's
/// foot, the producer, the name, the vintage with where it comes from and its colour
/// in an outlined tag, then how long it has been in the cellar. Under them, the
/// bottle's actions while it is in the cellar: taking it out first, in white, then
/// the favourite and the move on glass. White text whatever the appearance: it sits
/// on the dark top of the backdrop.
struct WineSheetHero: View {
    let item: Item
    var onRemove: () -> Void = {}
    var onToggleFavorite: () -> Void = {}
    var onMove: () -> Void = {}

    struct Item {
        let bottle: SpinningBottle.Wine
        let producer: String?
        let name: String
        /// "2015 · Margaux": the vintage and the narrowest place known.
        let meta: String?
        /// The colour, or the kind of drink, in the outlined tag.
        let tag: String?
        /// "En cave depuis 41 jours"; nil once the bottle is out.
        let status: String?
        /// Whether the bottle stands in the cellar: the actions only make sense then.
        let isInCellar: Bool
        let isFavorite: Bool
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .bottom, spacing: 18) {
                SpinningBottle(wine: item.bottle, height: 330)
                    .background {
                        // A soft light behind the glass, so the bottle stands out of
                        // the dark rather than sinking in it.
                        Ellipse()
                            .fill(Color(hex: 0xFFC4D6).opacity(0.3))
                            .frame(width: 190, height: 300)
                            .blur(radius: 28)
                            .offset(y: 30)
                    }
                identity
                    .padding(.bottom, 10)
            }
            if item.isInCellar {
                actions
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.white)
        .environment(\.colorScheme, .dark)
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let producer = item.producer {
                Text(producer)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
            }
            Text(item.name)
                .font(.title2.weight(.bold))
                .lineLimit(4)
                .minimumScaleFactor(0.8)
                .padding(.top, 3)
            if item.meta != nil || item.tag != nil {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    if let meta = item.meta {
                        Text(meta)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.78))
                            .lineLimit(1)
                    }
                    if let tag = item.tag {
                        Text(tag)
                            .font(.caption2.weight(.bold))
                            .textCase(.uppercase)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .overlay {
                                RoundedRectangle(cornerRadius: 3)
                                    .strokeBorder(.white.opacity(0.78), lineWidth: 1)
                            }
                    }
                }
                .padding(.top, 8)
            }
            if let status = item.status {
                HStack(spacing: 7) {
                    Circle()
                        .fill(Color(.systemGreen))
                        .frame(width: 7, height: 7)
                        .accessibilityHidden(true)
                    Text(status)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.white.opacity(0.86))
                }
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Take it out, love it, move it: the three things done to a bottle in the cellar.
    private var actions: some View {
        HStack(spacing: 10) {
            Button(action: onRemove) {
                Label("Sortir de la cave", systemImage: "arrow.up")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .foregroundStyle(Color(hex: 0x2A0614))
                    .background(.white, in: .capsule)
                    .contentShape(.capsule)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("remove-from-cellar-button")

            roundButton(
                title: item.isFavorite ? "Retirer des favoris" : "Ajouter aux favoris",
                systemImage: item.isFavorite ? "heart.fill" : "heart",
                identifier: "hero-favorite-button",
                action: onToggleFavorite
            )
            roundButton(
                title: "Déplacer",
                systemImage: "arrow.left.arrow.right",
                identifier: "move-bottle-button",
                action: onMove
            )
        }
    }

    private func roundButton(
        title: LocalizedStringKey,
        systemImage: String,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3)
                .frame(width: 52, height: 52)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel(Text(title))
        .accessibilityIdentifier(identifier)
    }
}

extension WineSheetHero.Item {
    static let preview = WineSheetHero.Item(
        bottle: .init(
            style: .of(id: "1", beverageType: .wine, subtype: nil, color: .red, family: .chateau, vintage: 2015),
            text: .init(
                producer: "Château Margaux", name: "Pavillon Rouge", vintage: 2015,
                appellation: "Margaux", classification: nil, kind: nil
            )
        ),
        producer: "Château Margaux",
        name: "Pavillon Rouge du Château Margaux",
        meta: "2015 · Margaux",
        tag: "Rouge",
        status: "En cave depuis 41 jours",
        isInCellar: true,
        isFavorite: false
    )
}

#Preview("In cellar") {
    ScrollView {
        WineSheetHero(item: .preview)
            .padding(.horizontal, 20)
            .padding(.top, 40)
            .background(alignment: .top) {
                WineSheetBackdrop(tone: .red).padding(.top, -200)
            }
    }
    .background(Color(.systemGroupedBackground))
}
