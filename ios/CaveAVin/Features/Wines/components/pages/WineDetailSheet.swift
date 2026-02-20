import SwiftUI

struct WineDetailSheet: View {
    let wineId: String
    var onRemoved: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var detail: UserWineDetail?
    @State private var isLoading = true
    @State private var error: String?
    @State private var showConsumption = false
    @State private var showRemovalChoice = false
    @State private var showGift = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if let detail {
                    wineContent(detail)
                } else if let error {
                    ContentUnavailableView(
                        "Erreur",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                }
            }
            .navigationTitle(detail?.name ?? "D\u{00E9}tail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer", systemImage: "xmark") { dismiss() }
                }
                if let cellar = detail?.cellar, cellar.dateOut == nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Sortir", systemImage: "arrow.up") {
                            showRemovalChoice = true
                        }
                    }
                }
                if detail != nil {
                    ToolbarItem(placement: .destructiveAction) {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                        }
                        .confirmationDialog(
                            "Supprimer ce vin ?",
                            isPresented: $showDeleteConfirmation,
                            titleVisibility: .visible,
                            presenting: detail
                        ) { detail in
                            Button("Supprimer", role: .destructive) {
                                Task {
                                    try? await WineAPI.delete(id: detail.id)
                                    dismiss()
                                    onRemoved?()
                                }
                            }
                        } message: { _ in
                            Text("Cette action est irréversible. Le vin sera supprimé de votre collection, de la cave et de toutes les données associées.")
                        }
                        .accessibilityIdentifier("delete-wine-button")
                    }
                }
            }
            .task { await loadData() }
        }
    }

    @ViewBuilder
    private func wineContent(_ detail: UserWineDetail) -> some View {
        List {
            WineDetailHeader(
                color: detail.color,
                name: detail.name,
                subtitle: headerSubtitle(detail),
                domain: detail.domain,
                vintage: detail.vintage
            )

            WineOriginSection(
                appellation: detail.appellation,
                region: detail.region,
                country: detail.country,
                classification: detail.classification
            )

            WineDetailsSection(
                alcoholContent: detail.alcoholContent,
                purchasePrice: detail.purchasePrice,
                purchaseDate: detail.purchaseDate,
                grapeVarieties: detail.grapeVarieties
            )

            WineAgingSection(drinkFrom: detail.drinkFrom, drinkUntil: detail.drinkUntil)

            if let cellar = detail.cellar {
                WineCellarSection(
                    position: "\(cellar.row)\(cellar.col)",
                    dateIn: formatted(cellar.dateIn),
                    dateOut: cellar.dateOut.map { formatted($0) },
                    isInCellar: cellar.dateOut == nil,
                    onRemoveRequested: { showRemovalChoice = true }
                )
            }

            if let consumption = detail.consumption {
                WineConsumptionSection(
                    consumedDate: consumption.consumedDate.map { formatted($0) },
                    rating: consumption.rating,
                    tastingNotes: consumption.tastingNotes
                )
            }

            if let gift = detail.gift {
                WineGiftSection(giftedDate: formatted(gift.giftedDate), recipientName: gift.recipientName)
            }

            if let notes = detail.notes, !notes.isEmpty {
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
        .sheet(isPresented: $showRemovalChoice) {
            RemovalChoiceSheet(
                onConsume: {
                    showRemovalChoice = false
                    showConsumption = true
                },
                onGift: {
                    showRemovalChoice = false
                    showGift = true
                }
            )
            .presentationDetents([.height(260)])
        }
        .sheet(isPresented: $showConsumption) {
            ConsumptionSheet(
                wine: Wine(
                    id: detail.id,
                    name: detail.name,
                    color: detail.color,
                    createdAt: detail.createdAt,
                    updatedAt: detail.updatedAt
                )
            ) { date, rating, notes in
                let formatter = ISO8601DateFormatter()
                Task {
                    _ = try? await CellarAPI.remove(
                        wineId: detail.id,
                        consumedDate: formatter.string(from: date),
                        rating: rating,
                        tastingNotes: notes
                    )
                    showConsumption = false
                    dismiss()
                    onRemoved?()
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showGift) {
            GiftSheet(
                wine: Wine(
                    id: detail.id,
                    name: detail.name,
                    color: detail.color,
                    createdAt: detail.createdAt,
                    updatedAt: detail.updatedAt
                )
            ) { date, recipientName in
                let formatter = ISO8601DateFormatter()
                Task {
                    _ = try? await CellarAPI.gift(
                        wineId: detail.id,
                        giftedDate: formatter.string(from: date),
                        recipientName: recipientName
                    )
                    showGift = false
                    dismiss()
                    onRemoved?()
                }
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: - Helpers

    private func headerSubtitle(_ detail: UserWineDetail) -> String {
        [detail.color.label,
         detail.domain,
         detail.vintage.map { "\($0)" }]
            .compactMap { $0 }
            .joined(separator: " \u{2022} ")
    }

    private func formatted(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    private func loadData() async {
        do {
            detail = try await WineAPI.getDetail(id: wineId)
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
}

#Preview("Bouteille sortie") {
    WineDetailSheet(wineId: "5d288fc9-864d-4633-862a-b4410cf8b64a")
}

#Preview("En cave") {
    WineDetailSheet(wineId: "b1e1fe66-5aa8-4d64-80e0-8f2338838b23")
}
