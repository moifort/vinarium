import SwiftUI

struct DashboardView: View {
    @Binding var selectedTab: TabSelection

    @State private var viewModel = DashboardViewModel()
    @State private var selectedWineId: String?

    var body: some View {
        NavigationStack {
            Group {
                if let data = viewModel.data {
                    ScrollView {
                        VStack(spacing: 20) {
                            statsRow(data)
                            readyToDrinkSection(data)
                            journalSection(data)
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
            Button { selectedTab = .cellar } label: {
                GradientWidget(
                    title: "En cave",
                    value: "\(data.bottleCount)",
                    subtitle: "Bouteilles",
                    icon: "wineglass",
                    gradient: [Color(red: 0.55, green: 0.25, blue: 0.8), Color(red: 0.75, green: 0.45, blue: 0.95)],
                    backgroundImage: "widget-en-cave"
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("stat-bottles")

            Button { selectedTab = .cellar } label: {
                GradientWidget(
                    title: "Valeur",
                    value: String(format: "%.0f €", data.totalValue),
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

    // MARK: - Ready to Drink

    private func readyToDrinkSection(_ data: DashboardData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Prêt à déguster", systemImage: "wineglass")
                    .font(.headline)
                Spacer()
                if !data.readyToDrink.isEmpty {
                    Text("\(data.readyToDrink.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if data.readyToDrink.isEmpty {
                Text("Aucun vin prêt à déguster")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(Color(.systemGray6))
                    .clipShape(.rect(cornerRadius: 12))
            } else {
                VStack(spacing: 0) {
                    ForEach(data.readyToDrink) { wine in
                        Button {
                            selectedWineId = wine.id
                        } label: {
                            HStack(spacing: 10) {
                                WineColorBadge(color: wine.color)
                                Text(wine.name)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                if wine.urgent, let year = wine.drinkUntil {
                                    Text("Avant \(year)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.orange, in: .capsule)
                                }
                                Spacer()
                                Text(wine.position)
                                    .font(.subheadline.monospaced())
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray5))
                                    .clipShape(.rect(cornerRadius: 6))
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                        }
                        .tint(.primary)
                    }
                }
                .background(Color(.systemGray6))
                .clipShape(.rect(cornerRadius: 12))
            }
        }
    }

    // MARK: - Journal

    private func journalSection(_ data: DashboardData) -> some View {
        let lastEntry = data.history.first { $0.isEntry }
        let lastExit = data.history.first { !$0.isEntry }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Journal", systemImage: "book")
                    .font(.headline)
                Spacer()
                if !data.history.isEmpty {
                    Text("\(data.history.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if data.history.isEmpty {
                Text("Aucun événement récent")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(Color(.systemGray6))
                    .clipShape(.rect(cornerRadius: 12))
            } else {
                VStack(spacing: 0) {
                    if let entry = lastEntry {
                        eventRow(entry)
                    }
                    if let exit = lastExit {
                        eventRow(exit)
                    }
                }
                .background(Color(.systemGray6))
                .clipShape(.rect(cornerRadius: 12))
            }
        }
    }

    private func eventRow(_ event: DashboardHistoryEvent) -> some View {
        Button {
            selectedWineId = event.wineId
        } label: {
            HStack(spacing: 12) {
                Image(systemName: event.isEntry ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .foregroundStyle(event.isEntry ? .green : .red)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.wineName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(event.isEntry ? "Dernière entrée" : "Dernière sortie")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(event.position)
                    .font(.subheadline.monospaced())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .clipShape(.rect(cornerRadius: 6))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
        }
        .tint(.primary)
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
