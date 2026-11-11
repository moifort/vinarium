import SwiftUI

/// The latest bottles in and out of the cellar, one card each on the bottle's
/// own backdrop, sliding sideways: the bottle on the left, the move, the wine, its
/// slot and its day on the right, and what to do next with it.
struct RecentMovesSection: View {
    let moves: [Move]
    var onSeeAll: (() -> Void)?
    var onOpen: (String) -> Void
    var onMove: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeSectionHeader(title: "Récemment", onTapped: onSeeAll)
            ScrollView(.horizontal) {
                LazyHStack(spacing: 12) {
                    ForEach(moves) { move in
                        card(move)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .contentMargins(.horizontal, 20, for: .scrollContent)
        }
        .accessibilityIdentifier("dashboard-recent-section")
    }

    /// Low enough to keep the rail light on the home, the 108 pt bottle still
    /// clear of the edges.
    private static let cardSize = CGSize(width: 340, height: 136)
    private static let bottleHeight: CGFloat = 108
    /// The bottle's lane on the leading edge, the text starting just past it.
    private static let bottleLane: CGFloat = 64
    private static let textLeading: CGFloat = 4
    private static let inset: CGFloat = 14
    private static let buttonHeight: CGFloat = 28

    /// The move on top, the wine under it, then its slot and day on the bottom
    /// edge, the buttons beside them. The vintage stays on the bottle's label.
    private func card(_ move: Move) -> some View {
        Button { onOpen(move.wineId) } label: {
            HStack(spacing: 0) {
                BottleArtwork(style: move.style, producer: move.producer, name: move.name, vintage: move.vintage, height: Self.bottleHeight)
                    .frame(width: Self.bottleLane, height: Self.cardSize.height)

                VStack(alignment: .leading, spacing: 0) {
                    overline(move)
                    Text(move.name)
                        .font(.system(size: 19, weight: .bold))
                        .tracking(-0.3)
                        .lineLimit(2)
                        .padding(.top, 3)
                    Spacer(minLength: 0)
                    figures(move)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(EdgeInsets(top: Self.inset, leading: Self.textLeading, bottom: Self.inset, trailing: Self.inset))
            }
            .frame(width: Self.cardSize.width, height: Self.cardSize.height)
            .background { ground(move) }
            .clipShape(.rect(cornerRadius: 18))
            .contentShape(.rect(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        // The buttons sit over the card's bottom corner, each answering its own
        // tap: moving a bottle that just came in, then its sheet.
        .overlay(alignment: .bottomTrailing) {
            HStack(spacing: 8) {
                if move.isEntry {
                    moveButton { onMove(move.wineId) }
                }
                sheetButton { onOpen(move.wineId) }
            }
            .padding([.trailing, .bottom], Self.inset)
        }
    }

    /// "↓ ENTRÉE", with the housemate who made the move.
    private func overline(_ move: Move) -> some View {
        HStack(spacing: 5) {
            Image(systemName: move.isEntry ? "arrow.down" : "arrow.up")
                .font(.system(size: 10, weight: .bold))
            Text(move.overline)
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.7)
                .textCase(.uppercase)
                .lineLimit(1)
        }
        .foregroundStyle(.white.opacity(0.72))
    }

    /// The slot and the day, as the home vignettes and the hero set their figures:
    /// the value large, a short capitalised label under it, a hairline between.
    private func figures(_ move: Move) -> some View {
        let cells: [(value: String, label: LocalizedStringKey)] = [
            (move.position, "cave"),
            (move.dayFigure, "date"),
        ]
        return HStack(spacing: 0) {
            ForEach(Array(cells.enumerated()), id: \.offset) { index, cell in
                HStack(spacing: 12) {
                    if index > 0 {
                        Rectangle().fill(.white.opacity(0.22)).frame(width: 1)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(cell.value)
                            .font(.system(size: 15, weight: .semibold))
                            .tracking(-0.2)
                            .monospacedDigit()
                            .lineLimit(1)
                        Text(cell.label)
                            .font(.system(size: 9, weight: .semibold))
                            .tracking(0.7)
                            .textCase(.uppercase)
                            .foregroundStyle(.white.opacity(0.72))
                            .lineLimit(1)
                    }
                }
                .padding(.trailing, 12)
                .accessibilityElement(children: .combine)
            }
        }
        .fixedSize()
    }

    /// One ground under the bottle and the text: the bottle's own backdrop, lit
    /// behind the bottle and darkening towards the far edge, as the board draws it.
    private func ground(_ move: Move) -> some View {
        let (center, edge) = BottleBackdrop.tones(beverageType: move.beverageType, color: move.color)
        return edge.overlay(alignment: .topLeading) {
            EllipticalGradient(colors: [center, edge], center: .center, startRadiusFraction: 0, endRadiusFraction: 0.5)
                .frame(width: 660, height: 460)
                .position(x: 40, y: Self.cardSize.height * 0.32)
        }
    }

    private func sheetButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("Voir la fiche")
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
                .padding(.horizontal, 12)
                .frame(height: Self.buttonHeight)
                .foregroundStyle(.black)
                .background(.white, in: .capsule)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
    }

    private func moveButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: Self.buttonHeight, height: Self.buttonHeight)
                .background(.white.opacity(0.18), in: .circle)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Déplacer")
    }
}

extension RecentMovesSection {
    struct Move: Identifiable, Equatable {
        let id: String
        let wineId: String
        let isEntry: Bool
        var beverageType: BeverageType = .wine
        var subtype: BeverageSubtype? = nil
        let color: WineColor?
        let producer: String?
        let name: String
        let vintage: Int?
        let position: String
        let date: Date
        /// The housemate behind the move, nil when it was the viewer.
        var memberName: String? = nil
        var labelFamily: BottleArtwork.LabelFamily? = nil
        var labelTraits: BottleArtwork.LabelTraits? = nil

        var style: BottleArtwork.Style {
            .of(id: wineId, beverageType: beverageType, subtype: subtype, color: color, family: labelFamily, traits: labelTraits, vintage: vintage)
        }

        /// "Entrée", with the housemate who made the move.
        var overline: String {
            let direction = isEntry ? String(localized: "Entrée") : String(localized: "Sortie")
            return [direction, memberName].compactMap(\.self).joined(separator: " · ")
        }

        /// "4 oct.", the year added to a date from another year.
        var dayFigure: String {
            let sameYear = Calendar.current.isDate(date, equalTo: .now, toGranularity: .year)
            return sameYear
                ? date.formatted(.dateTime.day().month(.abbreviated))
                : date.formatted(.dateTime.day().month(.abbreviated).year())
        }
    }
}

#Preview {
    RecentMovesSection(
        moves: [
            .init(id: "a", wineId: "1", isEntry: true, color: .red, producer: "Château Margaux", name: "Pavillon Rouge du Château Margaux", vintage: 2015, position: "A1", date: .now),
            .init(id: "b", wineId: "2", isEntry: false, color: .red, producer: "Château Latour", name: "Pauillac Les Forts de Latour", vintage: 2016, position: "E3", date: .now, memberName: "Marie"),
        ],
        onSeeAll: {},
        onOpen: { _ in },
        onMove: { _ in }
    )
}
