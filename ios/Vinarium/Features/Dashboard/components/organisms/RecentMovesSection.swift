import SwiftUI

/// The latest bottles in and out of the cellar, one dark card each in the wine's
/// colour, sliding sideways: the bottle on the left, the move, the wine and its
/// date on the right, and what to do next with it.
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

    private func card(_ move: Move) -> some View {
        Button { onOpen(move.wineId) } label: {
            HStack(spacing: 0) {
                ZStack {
                    BottleBackdrop(beverageType: move.beverageType, color: move.color)
                    BottleArtwork(style: move.style, producer: move.producer, name: move.name, vintage: move.vintage, height: 150)
                }
                .frame(width: 104, height: 164)

                VStack(alignment: .leading, spacing: 0) {
                    Text(move.overline)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(1)
                    Text(move.name)
                        .font(.system(size: 19, weight: .bold))
                        .lineLimit(2)
                        .padding(.top, 2)
                    Text(move.dateLine)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(1)
                        .padding(.top, 4)
                    Spacer(minLength: 0)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 14))
            }
            .frame(width: 340, height: 164)
            .background(BottleBackdrop.cardColor(beverageType: move.beverageType, color: move.color))
            .clipShape(.rect(cornerRadius: 18))
            .contentShape(.rect(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        // The two pills sit over the card, each answering its own tap.
        .overlay(alignment: .bottomLeading) {
            HStack(spacing: 8) {
                pill("Voir la fiche", filled: true) { onOpen(move.wineId) }
                if move.isEntry {
                    pill("Déplacer", filled: false) { onMove(move.wineId) }
                }
            }
            .padding(.leading, 104 + 16)
            .padding(.bottom, 14)
        }
    }

    private func pill(_ title: LocalizedStringKey, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)
                .padding(.horizontal, 14)
                .frame(height: 32)
                .foregroundStyle(filled ? Color.black : Color.white)
                .background(filled ? Color.white : Color.white.opacity(0.18), in: .capsule)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
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

        var style: BottleArtwork.Style {
            .of(id: wineId, beverageType: beverageType, subtype: subtype, color: color)
        }

        /// "Entrée · A1", with the housemate who made the move.
        var overline: String {
            let direction = isEntry ? String(localized: "Entrée") : String(localized: "Sortie")
            return [direction, position, memberName].compactMap(\.self).joined(separator: " · ")
        }

        /// "2015 · le 4 octobre", the year added to a date from another year.
        var dateLine: String {
            let sameYear = Calendar.current.isDate(date, equalTo: .now, toGranularity: .year)
            let day = sameYear
                ? date.formatted(.dateTime.day().month(.wide))
                : date.formatted(.dateTime.day().month(.wide).year())
            let when = String(localized: "le \(day)")
            return [vintage.map { String($0) }, when].compactMap(\.self).joined(separator: " · ")
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
