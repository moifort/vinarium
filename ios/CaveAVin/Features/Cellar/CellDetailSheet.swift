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
                    HStack(spacing: 12) {
                        WineColorBadge(color: wine.color)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(wine.name)
                                .font(.headline)
                            if let vintage = wine.vintage {
                                Text("\(vintage)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(positionLabel)
                            .font(.title3.monospaced())
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }
                }

                if wine.domain != nil || wine.appellation != nil || wine.region != nil || wine.country != nil {
                    Section {
                        if let domain = wine.domain {
                            Label {
                                LabeledContent("Domaine", value: domain)
                            } icon: {
                                Image(systemName: "building.2")
                                    .foregroundStyle(.secondary)
                            }
                        }
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
                    } header: {
                        Text("Origine")
                    }
                }

                if wine.alcoholContent != nil || wine.purchasePrice != nil || (wine.grapeVarieties != nil && !wine.grapeVarieties!.isEmpty) {
                    Section {
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
                                LabeledContent("Prix", value: String(format: "%.0f €", price))
                            } icon: {
                                Image(systemName: "eurosign.circle")
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
                    } header: {
                        Text("Détails")
                    }
                }

                if wine.drinkFrom != nil || wine.drinkUntil != nil {
                    Section {
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
                    } header: {
                        Text("Garde")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showConsumption = true
                    } label: {
                        Label("Retirer de la cave", systemImage: "arrow.up.circle")
                            .frame(maxWidth: .infinity, alignment: .center)
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
