import SwiftUI

struct WineDetailSheet: View {
    let wineId: String
    var onRemoved: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var detail: UserWineDetail?
    @State private var isLoading = true
    @State private var error: String?
    @State private var showConsumption = false

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
            .navigationTitle(detail?.name ?? "Détail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .task { await loadData() }
        }
    }

    @ViewBuilder
    private func wineContent(_ detail: UserWineDetail) -> some View {
        List {
            headerSection(detail)
            originSection(detail)
            detailsSection(detail)
            agingSection(detail)

            if let cellar = detail.cellar {
                cellarSection(cellar)
            }

            if let consumption = detail.consumption {
                consumptionSection(consumption)
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
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func headerSection(_ detail: UserWineDetail) -> some View {
        Section {
            HStack(spacing: 12) {
                WineColorBadge(color: detail.color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(detail.name)
                        .font(.headline)
                    Text(headerSubtitle(detail))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let domain = detail.domain {
                labeledRow("Domaine", value: domain, icon: "building.2")
            }
            if let vintage = detail.vintage {
                labeledRow("Millésime", value: "\(vintage)", icon: "calendar")
            }
        }
    }

    @ViewBuilder
    private func originSection(_ detail: UserWineDetail) -> some View {
        if detail.appellation != nil || detail.region != nil
            || detail.country != nil || detail.classification != nil
        {
            Section("Origine") {
                if let appellation = detail.appellation {
                    labeledRow("Appellation", value: appellation, icon: "seal")
                }
                if let region = detail.region {
                    labeledRow("Région", value: region, icon: "map")
                }
                if let country = detail.country {
                    labeledRow("Pays", value: country, icon: "globe.europe.africa")
                }
                if let classification = detail.classification {
                    labeledRow("Classification", value: classification, icon: "rosette")
                }
            }
        }
    }

    @ViewBuilder
    private func detailsSection(_ detail: UserWineDetail) -> some View {
        if detail.alcoholContent != nil || detail.purchasePrice != nil
            || detail.purchaseDate != nil || !detail.grapeVarieties.isEmpty
        {
            Section("Détails") {
                if let alcohol = detail.alcoholContent {
                    labeledRow("Alcool", value: String(format: "%.1f %% vol", alcohol), icon: "drop")
                }
                if let price = detail.purchasePrice {
                    labeledRow("Prix d'achat", value: String(format: "%.0f €", price), icon: "eurosign.circle")
                }
                if let date = detail.purchaseDate {
                    labeledRow("Date d'achat", value: date, icon: "calendar.badge.clock")
                }
                if !detail.grapeVarieties.isEmpty {
                    labeledRow(
                        "Cépages",
                        value: detail.grapeVarieties.joined(separator: " \u{2022} "),
                        icon: "leaf"
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func agingSection(_ detail: UserWineDetail) -> some View {
        if detail.drinkFrom != nil || detail.drinkUntil != nil {
            Section("Garde") {
                if let from = detail.drinkFrom {
                    labeledRow("À partir de", value: "\(from)", icon: "hourglass.bottomhalf.filled")
                }
                if let until = detail.drinkUntil {
                    labeledRow("Jusqu'à", value: "\(until)", icon: "hourglass.tophalf.filled")
                }
            }
        }
    }

    @ViewBuilder
    private func cellarSection(_ cellar: CellarInfo) -> some View {
        Section("En cave") {
            Label {
                LabeledContent("Position", value: "\(cellar.row)\(cellar.col)")
            } icon: {
                Image(systemName: "mappin.circle")
                    .foregroundStyle(.blue)
            }
            Label {
                LabeledContent("Depuis", value: formatted(cellar.dateIn))
            } icon: {
                Image(systemName: "calendar.badge.plus")
                    .foregroundStyle(.green)
            }

            Button(role: .destructive) {
                showConsumption = true
            } label: {
                Label("Retirer de la cave", systemImage: "arrow.up.circle")
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .accessibilityIdentifier("remove-from-cellar-button")
        }
    }

    @ViewBuilder
    private func consumptionSection(_ consumption: ConsumptionInfo) -> some View {
        Section("Consommé") {
            Label {
                LabeledContent("Retiré le", value: formatted(consumption.dateOut))
            } icon: {
                Image(systemName: "calendar.badge.minus")
                    .foregroundStyle(.red)
            }
            if let rating = consumption.rating {
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
            if let notes = consumption.tastingNotes {
                Label {
                    Text(notes)
                } icon: {
                    Image(systemName: "note.text")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Helpers

    private func labeledRow(_ title: String, value: String, icon: String) -> some View {
        Label {
            LabeledContent(title, value: value)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
        }
    }

    private func headerSubtitle(_ detail: UserWineDetail) -> String {
        [detail.color.label,
         detail.domain,
         detail.vintage.map { "\($0)" }]
            .compactMap { $0 }
            .joined(separator: " \u{2022} ")
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

    private func formatted(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}
