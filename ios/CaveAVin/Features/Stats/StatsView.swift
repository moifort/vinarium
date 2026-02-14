import Charts
import SwiftUI

struct StatsView: View {
    @State private var viewModel = StatsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.summary == nil {
                    ProgressView("Chargement...")
                } else if let error = viewModel.error, viewModel.summary == nil {
                    ContentUnavailableView("Erreur", systemImage: "exclamationmark.triangle", description: Text(error))
                } else if let summary = viewModel.summary {
                    summaryContent(summary)
                }
            }
            .navigationTitle("Statistiques")
            .refreshable {
                await viewModel.load()
            }
            .task {
                await viewModel.load()
            }
        }
    }

    @ViewBuilder
    private func summaryContent(_ summary: FinanceSummary) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Key metrics
                HStack(spacing: 16) {
                    metricCard(title: "Valeur", value: String(format: "%.0f €", summary.currentValue))
                    metricCard(title: "Bouteilles", value: "\(summary.bottleCount)")
                    metricCard(title: "Prix moyen", value: String(format: "%.0f €", summary.averagePrice))
                }
                .padding(.horizontal)

                // Pie chart by color
                if !summary.byColor.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Par couleur")
                            .font(.headline)
                            .padding(.horizontal)

                        Chart(Array(summary.byColor), id: \.key) { item in
                            SectorMark(
                                angle: .value("Bouteilles", item.value.count),
                                innerRadius: .ratio(0.5),
                                angularInset: 2
                            )
                            .foregroundStyle(colorForWineType(item.key))
                            .annotation(position: .overlay) {
                                Text("\(item.value.count)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(height: 200)
                        .padding(.horizontal)

                        // Legend
                        HStack(spacing: 12) {
                            ForEach(Array(summary.byColor), id: \.key) { item in
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(colorForWineType(item.key))
                                        .frame(width: 8, height: 8)
                                    Text(labelForWineType(item.key))
                                        .font(.caption)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Bar chart by region
                if !summary.byRegion.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Par région")
                            .font(.headline)
                            .padding(.horizontal)

                        let sortedRegions = summary.byRegion.sorted { $0.value.count > $1.value.count }
                        let topRegions = Array(sortedRegions.prefix(8))

                        Chart(topRegions, id: \.key) { item in
                            BarMark(
                                x: .value("Bouteilles", item.value.count),
                                y: .value("Région", item.key)
                            )
                            .foregroundStyle(.purple.gradient)
                        }
                        .frame(height: CGFloat(topRegions.count * 32 + 20))
                        .padding(.horizontal)
                    }
                }

                // Monthly value trend
                if !summary.monthlyHistory.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Valeur de la cave")
                            .font(.headline)
                            .padding(.horizontal)

                        Chart(summary.monthlyHistory, id: \.month) { report in
                            LineMark(
                                x: .value("Mois", report.month),
                                y: .value("Valeur", report.cellarValue)
                            )
                            .foregroundStyle(.blue.gradient)

                            AreaMark(
                                x: .value("Mois", report.month),
                                y: .value("Valeur", report.cellarValue)
                            )
                            .foregroundStyle(.blue.opacity(0.1))
                        }
                        .frame(height: 200)
                        .padding(.horizontal)
                    }
                }

                // Trend deltas
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tendance")
                        .font(.headline)

                    trendRow(label: "Dernier mois", delta: summary.trend.lastMonthDelta)
                    trendRow(label: "3 derniers mois", delta: summary.trend.last3MonthsDelta)
                    trendRow(label: "12 derniers mois", delta: summary.trend.last12MonthsDelta)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    private func metricCard(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func trendRow(label: String, delta: Double) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(String(format: "%+.0f €", delta))
                .foregroundStyle(delta >= 0 ? .green : .red)
                .fontWeight(.medium)
        }
    }

    private func colorForWineType(_ type: String) -> Color {
        switch type {
        case "red": .red
        case "white": .yellow
        case "rosé": .pink
        case "sparkling": .mint
        case "sweet": .orange
        default: .gray
        }
    }

    private func labelForWineType(_ type: String) -> String {
        switch type {
        case "red": "Rouge"
        case "white": "Blanc"
        case "rosé": "Rosé"
        case "sparkling": "Pétillant"
        case "sweet": "Moelleux"
        default: type
        }
    }
}
