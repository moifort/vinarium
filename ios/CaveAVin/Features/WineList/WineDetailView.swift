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
            Section {
                HStack {
                    WineColorBadge(color: wine.color)
                    Text(wine.name)
                        .font(.headline)
                }
                Text(wine.color.label)
                    .foregroundStyle(.secondary)
                if let domain = wine.domain {
                    LabeledContent("Domaine", value: domain)
                }
                if let vintage = wine.vintage {
                    LabeledContent("Millésime", value: "\(vintage)")
                }
            }

            if wine.appellation != nil || wine.region != nil || wine.country != nil {
                Section("Origine") {
                    if let appellation = wine.appellation {
                        LabeledContent("Appellation", value: appellation)
                    }
                    if let region = wine.region {
                        LabeledContent("Région", value: region)
                    }
                    if let country = wine.country {
                        LabeledContent("Pays", value: country)
                    }
                    if let classification = wine.classification {
                        LabeledContent("Classification", value: classification)
                    }
                }
            }

            if wine.alcoholContent != nil || wine.purchasePrice != nil || (wine.grapeVarieties != nil && !wine.grapeVarieties!.isEmpty) {
                Section("Détails") {
                    if let alcohol = wine.alcoholContent {
                        LabeledContent("Alcool", value: String(format: "%.1f%%", alcohol))
                    }
                    if let price = wine.purchasePrice {
                        LabeledContent("Prix d'achat", value: String(format: "%.0f €", price))
                    }
                    if let date = wine.purchaseDate {
                        LabeledContent("Date d'achat", value: date)
                    }
                    if let grapes = wine.grapeVarieties, !grapes.isEmpty {
                        LabeledContent("Cépages", value: grapes.joined(separator: ", "))
                    }
                }
            }

            if wine.drinkFrom != nil || wine.drinkUntil != nil {
                Section("Garde") {
                    if let from = wine.drinkFrom {
                        LabeledContent("À boire à partir de", value: "\(from)")
                    }
                    if let until = wine.drinkUntil {
                        LabeledContent("À boire jusqu'à", value: "\(until)")
                    }
                }
            }

            if let entry = cellarEntry, entry.dateOut == nil {
                Section("En cave") {
                    LabeledContent("Position", value: "\(entry.row)\(entry.col)")
                    LabeledContent("Depuis", value: formatted(entry.dateIn))

                    Button("Retirer de la cave", role: .destructive) {
                        showConsumption = true
                    }
                }
            }

            if let entry = cellarEntry, let dateOut = entry.dateOut {
                Section("Consommé") {
                    LabeledContent("Retiré le", value: formatted(dateOut))
                    if let rating = entry.rating {
                        HStack {
                            Text("Note")
                            Spacer()
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .foregroundStyle(star <= rating ? .yellow : .gray)
                                    .font(.caption)
                            }
                        }
                    }
                    if let notes = entry.tastingNotes {
                        Text(notes)
                    }
                }
            }

            if let notes = wine.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
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
            // Try to get cellar entry (may not exist)
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
