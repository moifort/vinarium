import SwiftUI

struct ConsumptionSheet: View {
    let wine: Wine
    let onConfirm: (Date, Int?, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var consumedDate = Date()
    @State private var rating: Int = 0
    @State private var tastingNotes = ""

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Vin sélectionné
                Section {
                    HStack(spacing: 12) {
                        WineColorBadge(color: wine.color)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(wine.name)
                                .font(.headline)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // MARK: - Date
                Section {
                    HStack {
                        Label("Date", systemImage: "calendar")
                            .foregroundStyle(.secondary)
                        Spacer()
                        DatePicker(
                            "",
                            selection: $consumedDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                    }
 
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Note", systemImage: "star")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        InteractiveStarRating(rating: $rating)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Notes", systemImage: "note")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("Vos impressions, arômes, accords...", text: $tastingNotes, axis: .vertical)
                            .lineLimit(3...6)
                    }
                    .padding(.vertical, 4)
                }

            }
            .navigationTitle("Consommation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirmer", systemImage: "checkmark") {
                        onConfirm(
                            consumedDate,
                            rating > 0 ? rating : nil,
                            tastingNotes.isEmpty ? nil : tastingNotes
                        )
                    }
                    .accessibilityIdentifier("confirm-consumption-button")
                }
            }
            .animation(.default, value: rating)
        }
    }

}

#Preview {
    ConsumptionSheet(
        wine: Wine(
            id: "1", name: "Château Margaux 2018", color: .red,
            createdAt: Date(), updatedAt: Date()
        ),
        onConfirm: { _, _, _ in }
    )
}
