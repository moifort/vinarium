import SwiftUI

struct CellDetailSheet: View {
    let wine: Wine
    let row: Int
    let col: Int
    let onRemoved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showConsumption = false

    private var positionLabel: String {
        "\(String(UnicodeScalar(65 + row)!))\(col + 1)"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        WineColorBadge(color: wine.color)
                        Text(wine.name)
                            .font(.headline)
                    }
                    if let domain = wine.domain {
                        LabeledContent("Domaine", value: domain)
                    }
                    if let vintage = wine.vintage {
                        LabeledContent("Millésime", value: "\(vintage)")
                    }
                    LabeledContent("Position", value: positionLabel)
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

                if wine.alcoholContent != nil || wine.purchasePrice != nil {
                    Section("Détails") {
                        if let alcohol = wine.alcoholContent {
                            LabeledContent("Alcool", value: String(format: "%.1f%%", alcohol))
                        }
                        if let price = wine.purchasePrice {
                            LabeledContent("Prix", value: String(format: "%.0f €", price))
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

                if let notes = wine.notes, !notes.isEmpty {
                    Section("Notes") {
                        Text(notes)
                    }
                }

                Section {
                    Button("Retirer de la cave", role: .destructive) {
                        showConsumption = true
                    }
                }
            }
            .navigationTitle(wine.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
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
                        dismiss()
                        onRemoved()
                    }
                }
            }
        }
    }
}
