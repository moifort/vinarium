import SwiftUI

struct WineDetailView: View {
    let wineId: String

    @State private var wine: Wine?
    @State private var cellarEntry: CellarEntry?
    @State private var isLoading = true
    @State private var error: String?
    @State private var showConsumption = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let wine {
                wineDetail(wine)
            } else if let error {
                ContentUnavailableView("Erreur", systemImage: "exclamationmark.triangle", description: Text(error))
            }
        }
        .navigationTitle(wine?.name ?? "Détail")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadData()
        }
    }

    @ViewBuilder
    private func wineDetail(_ wine: Wine) -> some View {
        List {
            // Header
            Section {
                HStack(spacing: 12) {
                    WineColorBadge(color: wine.color)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(wine.name)
                            .font(.headline)
                        Text(wine.color.label)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if let domain = wine.domain {
                    Label {
                        LabeledContent("Domaine", value: domain)
                    } icon: {
                        Image(systemName: "building.2")
                            .foregroundStyle(.secondary)
                    }
                }
                if let vintage = wine.vintage {
                    Label {
                        LabeledContent("Millésime", value: "\(vintage)")
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Origine
            if wine.appellation != nil || wine.region != nil || wine.country != nil {
                Section("Origine") {
                    if let appellation = wine.appellation {
                        Label {
                            LabeledContent("Appellation", value: appellation)
                        } icon: {
                            Image(systemName: "seal")
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let region = wine.region {
                        Label {
                            LabeledContent("Région", value: region)
                        } icon: {
                            Image(systemName: "map")
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let country = wine.country {
                        Label {
                            LabeledContent("Pays", value: country)
                        } icon: {
                            Image(systemName: "globe.europe.africa")
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let classification = wine.classification {
                        Label {
                            LabeledContent("Classification", value: classification)
                        } icon: {
                            Image(systemName: "rosette")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Détails
            if wine.alcoholContent != nil || wine.purchasePrice != nil || (wine.grapeVarieties != nil && !wine.grapeVarieties!.isEmpty) {
                Section("Détails") {
                    if let alcohol = wine.alcoholContent {
                        Label {
                            LabeledContent("Alcool", value: String(format: "%.1f %% vol", alcohol))
                        } icon: {
                            Image(systemName: "drop")
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let price = wine.purchasePrice {
                        Label {
                            LabeledContent("Prix d'achat", value: String(format: "%.0f €", price))
                        } icon: {
                            Image(systemName: "eurosign.circle")
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let date = wine.purchaseDate {
                        Label {
                            LabeledContent("Date d'achat", value: date)
                        } icon: {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let grapes = wine.grapeVarieties, !grapes.isEmpty {
                        Label {
                            LabeledContent("Cépages", value: grapes.joined(separator: ", "))
                        } icon: {
                            Image(systemName: "leaf")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Garde
            if wine.drinkFrom != nil || wine.drinkUntil != nil {
                Section("Garde") {
                    if let from = wine.drinkFrom {
                        Label {
                            LabeledContent("À partir de", value: "\(from)")
                        } icon: {
                            Image(systemName: "hourglass.bottomhalf.filled")
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let until = wine.drinkUntil {
                        Label {
                            LabeledContent("Jusqu'à", value: "\(until)")
                        } icon: {
                            Image(systemName: "hourglass.tophalf.filled")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // En cave
            if let entry = cellarEntry, entry.dateOut == nil {
                Section("En cave") {
                    Label {
                        LabeledContent("Position", value: "\(entry.row)\(entry.col)")
                    } icon: {
                        Image(systemName: "mappin.circle")
                            .foregroundStyle(.blue)
                    }
                    Label {
                        LabeledContent("Depuis", value: formatted(entry.dateIn))
                    } icon: {
                        Image(systemName: "calendar.badge.plus")
                            .foregroundStyle(.green)
                    }

                    Button(role: .destructive) {
                        showConsumption = true
                    } label: {
                        Label("Retirer de la cave", systemImage: "arrow.up.circle")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }

            // Consommé
            if let entry = cellarEntry, let dateOut = entry.dateOut {
                Section("Consommé") {
                    Label {
                        LabeledContent("Retiré le", value: formatted(dateOut))
                    } icon: {
                        Image(systemName: "calendar.badge.minus")
                            .foregroundStyle(.red)
                    }
                    if let rating = entry.rating {
                        HStack {
                            Label("Note", systemImage: "star")
                                .foregroundStyle(.secondary)
                            Spacer()
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .foregroundStyle(star <= rating ? .yellow : .gray)
                                    .font(.caption)
                            }
                        }
                    }
                    if let notes = entry.tastingNotes {
                        Label {
                            Text(notes)
                        } icon: {
                            Image(systemName: "note.text")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Notes
            if let notes = wine.notes, !notes.isEmpty {
                Section("Notes") {
                    Label {
                        Text(notes)
                    } icon: {
                        Image(systemName: "note.text")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showConsumption) {
            ConsumptionSheet(wine: wine) { date, rating, notes in
                let formatter = ISO8601DateFormatter()
                Task {
                    _ = try? await CellarAPI.remove(
                        wineId: wine.id,
                        consumedDate: formatter.string(from: date),
                        rating: rating,
                        tastingNotes: notes
                    )
                    showConsumption = false
                    await loadData()
                }
            }
        }
    }

    private func loadData() async {
        do {
            wine = try await WineAPI.get(id: wineId)
            cellarEntry = try? await CellarAPI.getEntry(wineId: wineId)
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    private func formatted(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}
