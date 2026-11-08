import SwiftUI

/// The four figures under the title, set in a line with hairlines between them: the
/// bottles in the cellar, those ready to drink, the favorites and what the cellar is
/// worth. Each one opens what it counts.
struct HomeFigures: View {
    let figures: Figures
    var onTapped: (Figure) -> Void

    enum Figure { case bottles, ready, favorites, value }

    var body: some View {
        HStack(spacing: 0) {
            cell(.bottles, value: "\(figures.bottleCount)", label: "En cave", identifier: "stat-bottles")
            divider
            cell(.ready, value: "\(figures.readyCount)", label: "Prêtes", identifier: "stat-ready")
            divider
            cell(.favorites, value: "\(figures.favoriteCount)", label: "Favoris", identifier: "stat-favorites")
            divider
            cell(
                .value,
                value: Money.formattedFromEur(figures.totalValue, fractionLength: 0),
                label: "Valeur",
                identifier: "stat-value"
            )
        }
        .padding(.horizontal, 12)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color(.separator))
            .frame(width: 1, height: 44)
    }

    private func cell(_ figure: Figure, value: String, label: LocalizedStringKey, identifier: String) -> some View {
        Button { onTapped(figure) } label: {
            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .semibold))
                    .tracking(-0.4)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .contentTransition(.numericText())
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .tracking(0.7)
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }
}

extension HomeFigures {
    struct Figures: Equatable {
        let bottleCount: Int
        let readyCount: Int
        let favoriteCount: Int
        let totalValue: Double
    }
}

#Preview {
    HomeFigures(
        figures: .init(bottleCount: 18, readyCount: 5, favoriteCount: 3, totalValue: 2434),
        onTapped: { _ in }
    )
}
