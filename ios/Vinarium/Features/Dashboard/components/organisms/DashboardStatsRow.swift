import SwiftUI

struct DashboardStatsRow: View {
    let stats: Stats
    var onTapped: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button { onTapped() } label: {
                GradientWidget(
                    title: "En cave",
                    value: "\(stats.bottleCount)",
                    denominator: "/\(stats.capacity)",
                    subtitle: "Bouteilles",
                    icon: "wineglass",
                    gradient: [Color(red: 0.55, green: 0.25, blue: 0.8), Color(red: 0.75, green: 0.45, blue: 0.95)],
                    backgroundImage: "widget-en-cave"
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("stat-bottles")

            Button { onTapped() } label: {
                GradientWidget(
                    title: "Valeur",
                    value: String(format: "%.0f \u{20AC}", stats.totalValue),
                    subtitle: "Total",
                    icon: "eurosign.circle",
                    gradient: [Color(red: 0.15, green: 0.65, blue: 0.45), Color(red: 0.3, green: 0.8, blue: 0.55)],
                    backgroundImage: "widget-valeur"
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("stat-value")
        }
    }
}

extension DashboardStatsRow {
    struct Stats {
        let bottleCount: Int
        let capacity: Int
        let totalValue: Double
    }
}

#Preview {
    DashboardStatsRow(
        stats: .init(bottleCount: 41, capacity: 48, totalValue: 450),
        onTapped: {}
    )
    .frame(height: 140)
    .padding()
}
