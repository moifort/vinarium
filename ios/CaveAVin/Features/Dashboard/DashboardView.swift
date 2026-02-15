import SwiftUI

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if let data = viewModel.data {
                    ScrollView {
                        VStack(spacing: 20) {
                            bottleCountCard(data.bottleCount)

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
        }
    }

    private func bottleCountCard(_ count: Int) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "wineglass")
                .font(.largeTitle)
                .foregroundStyle(.purple)
            Text("\(count)")
                .font(.system(size: 48, weight: .bold))
            Text("Bouteilles en cave")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.systemGray6))
        .clipShape(.rect(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    private func readyToDrinkSection(_ wines: [DashboardWine]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("À boire maintenant", systemImage: "clock.badge.checkmark")
                .font(.headline)
            ForEach(wines) { wine in
                HStack {
                    WineColorBadge(color: wine.color)
                    Text(wine.name)
                    Spacer()
                    if let vintage = wine.vintage {
                        Text("\(vintage)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(.rect(cornerRadius: 12))
    }

    private func activityCard(
        icon: String,
        iconColor: Color,
        title: String,
        wine: DashboardEntryWine,
        date: Date,
        position: String,
        rating: Int? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(iconColor)
            HStack {
                WineColorBadge(color: wine.color)
                VStack(alignment: .leading) {
                    Text(wine.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("\(position) · \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let rating {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .foregroundStyle(star <= rating ? .yellow : .gray)
                                .font(.caption2)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(.rect(cornerRadius: 12))
    }
}
