import SwiftUI

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @State private var selectedWineId: String?

    var body: some View {
        NavigationStack {
            Group {
                if let data = viewModel.data {
                    ScrollView {
                        VStack(spacing: 16) {
                            statsRow(data)

                            if !data.readyToDrink.isEmpty {
                                readyToDrinkSection(data.readyToDrink)
                            }

                            if let entry = data.lastEntry {
                                activityCard(
                                    icon: "arrow.down.circle.fill",
                                    iconColor: .green,
                                    title: "Dernière entrée",
                                    wine: entry.wine,
                                    date: entry.date,
                                    position: entry.position
                                )
                                .onTapGesture { selectedWineId = entry.wine.id }
                            }

                            if let exit = data.lastExit {
                                activityCard(
                                    icon: "arrow.up.circle.fill",
                                    iconColor: .red,
                                    title: "Dernière sortie",
                                    wine: exit.wine,
                                    date: exit.date,
                                    position: exit.position,
                                    rating: exit.rating
                                )
                                .onTapGesture { selectedWineId = exit.wine.id }
                            }
                        }
                        .padding()
                    }
                } else if let error = viewModel.error {
                    ContentUnavailableView("Erreur", systemImage: "exclamationmark.triangle", description: Text(error))
                } else {
                    ProgressView("Chargement...")
                }
            }
            .navigationTitle("Accueil")
            .refreshable { await viewModel.load() }
            .task { await viewModel.load() }
            .sheet(item: Binding(
                get: { selectedWineId.map { WineIdWrapper(id: $0) } },
                set: { selectedWineId = $0?.id }
            )) { wrapper in
                WineDetailSheet(wineId: wrapper.id)
            }
        }
    }

    // MARK: - Stats Row

    private func statsRow(_ data: DashboardData) -> some View {
        HStack(spacing: 12) {
            statCard(
                icon: "wineglass",
                iconColor: .purple,
                value: "\(data.bottleCount)",
                label: "Bouteilles"
            )

            statCard(
                icon: "eurosign.circle",
                iconColor: .green,
                value: String(format: "%.0f €", data.totalValue),
                label: "Valeur totale"
            )
        }
    }

    private func statCard(icon: String, iconColor: Color, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemGray6))
        .clipShape(.rect(cornerRadius: 16))
    }

    // MARK: - Ready to Drink

    private func readyToDrinkSection(_ wines: [DashboardWine]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("À déguster")
                    .font(.headline)
            } icon: {
                Image(systemName: "clock.badge.checkmark")
                    .foregroundStyle(.orange)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 8) {
                ForEach(wines) { wine in
                    Button {
                        selectedWineId = wine.id
                    } label: {
                        HStack(spacing: 12) {
                            WineColorBadge(color: wine.color)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(wine.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                if let domain = wine.domain {
                                    Text(domain)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if let vintage = wine.vintage {
                                Text("\(vintage)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                    }
                    .tint(.primary)
                }
            }
            .padding(.vertical, 4)
            .background(Color(.systemGray6))
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    // MARK: - Activity Cards

    private func activityCard(
        icon: String,
        iconColor: Color,
        title: String,
        wine: DashboardEntryWine,
        date: Date,
        position: String,
        rating: Int? = nil
    ) -> some View {
        HStack(spacing: 0) {
            iconColor
                .frame(width: 4)
                .clipShape(.rect(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                        .font(.subheadline)
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                HStack(spacing: 10) {
                    WineColorBadge(color: wine.color)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(wine.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(position)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Spacer()
                    if let rating {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .foregroundStyle(star <= rating ? .yellow : Color(.systemGray4))
                                    .font(.caption2)
                            }
                        }
                    }
                }
            }
            .padding(12)
        }
        .background(Color(.systemGray6))
        .clipShape(.rect(cornerRadius: 12))
    }
}

private struct WineIdWrapper: Identifiable {
    let id: String
}
