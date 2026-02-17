import SwiftUI

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @State private var selectedWineId: String?

    var body: some View {
        NavigationStack {
            Group {
                if let data = viewModel.data {
                    ScrollView {
                        VStack(spacing: 20) {
                            statsRow(data)

                            if !data.readyToDrink.isEmpty {
                                readyToDrinkSection(data)
                            }

                            if !data.history.isEmpty {
                                journalSection(data)
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

    // MARK: - Stats

    private func statsRow(_ data: DashboardData) -> some View {
        HStack(spacing: 12) {
            GradientWidget(
                title: "En cave",
                value: "\(data.bottleCount)",
                subtitle: "Bouteilles",
                icon: "wineglass",
                gradient: [Color(red: 0.55, green: 0.25, blue: 0.8), Color(red: 0.75, green: 0.45, blue: 0.95)],
                backgroundImage: "widget-en-cave"
            )
            GradientWidget(
                title: "Valeur",
                value: String(format: "%.0f €", data.totalValue),
                subtitle: "Total",
                icon: "eurosign.circle",
                gradient: [Color(red: 0.15, green: 0.65, blue: 0.45), Color(red: 0.3, green: 0.8, blue: 0.55)],
                backgroundImage: "widget-valeur"
            )
        }
    }

    // MARK: - Ready to Drink

    private func readyToDrinkSection(_ data: DashboardData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            GradientWidget(
                title: "Prêt à déguster",
                value: "\(data.readyToDrink.count)",
                subtitle: "Bouteilles",
                icon: "clock.badge.checkmark",
                gradient: [Color(red: 0.9, green: 0.45, blue: 0.15), Color(red: 0.95, green: 0.65, blue: 0.2)],
                backgroundImage: "widget-pret-a-deguster"
            )

            VStack(spacing: 0) {
                ForEach(data.readyToDrink) { wine in
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
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                    }
                    .tint(.primary)
                }
            }
            .background(Color(.systemGray6))
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    // MARK: - Journal

    private func journalSection(_ data: DashboardData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            GradientWidget(
                title: "Journal",
                value: "\(data.history.count)",
                subtitle: "Activités récentes",
                icon: "book",
                gradient: [Color(red: 0.2, green: 0.45, blue: 0.85), Color(red: 0.35, green: 0.65, blue: 0.95)],
                backgroundImage: "widget-journal"
            )

            VStack(spacing: 0) {
                ForEach(data.history) { event in
                    HStack(spacing: 10) {
                        Image(systemName: event.isEntry ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                            .foregroundStyle(event.isEntry ? .green : .red)
                            .font(.subheadline)
                        WineColorBadge(color: event.wineColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.wineName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(event.position)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(event.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let rating = event.rating {
                                HStack(spacing: 1) {
                                    ForEach(1...5, id: \.self) { star in
                                        Image(systemName: star <= rating ? "star.fill" : "star")
                                            .foregroundStyle(star <= rating ? .yellow : Color(.systemGray4))
                                            .font(.system(size: 8))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                }
            }
            .background(Color(.systemGray6))
            .clipShape(.rect(cornerRadius: 12))
        }
    }
}

// MARK: - Gradient Widget (matching widget.png design)

private struct GradientWidget: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let gradient: [Color]
    var backgroundImage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.9))

            Spacer()

            Text(value)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Spacer()

            HStack(alignment: .bottom) {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
        .background {
            if let bg = backgroundImage {
                Image(bg)
                    .resizable()
                    .scaledToFill()
                    .overlay(Color.black.opacity(0.4))
            } else {
                LinearGradient(
                    colors: gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .clipShape(.rect(cornerRadius: 20))
    }
}

private struct WineIdWrapper: Identifiable {
    let id: String
}
