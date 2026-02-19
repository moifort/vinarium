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

                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { star in
                                Button {
                                    rating = star == rating ? 0 : star
                                } label: {
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .foregroundStyle(star <= rating ? .yellow : .gray.opacity(0.4))
                                        .font(.title)
                                        .scaleEffect(star == rating ? 1.15 : 1.0)
                                        .animation(.spring(duration: 0.2), value: rating)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("star-rating-\(star)")
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 4)
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Note : \(rating) sur 5")
                    .accessibilityAdjustableAction { direction in
                        switch direction {
                        case .increment: if rating < 5 { rating += 1 }
                        case .decrement: if rating > 0 { rating -= 1 }
                        @unknown default: break
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Notes", systemImage: "note")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("Vos impressions, arômes, accords...", text: $tastingNotes, axis: .vertical)
                            .lineLimit(3...6)
                    }
                    .padding(.vertical, 4)
                }

                // MARK: - Bouton de confirmation
                Section {
                    Button {
                        onConfirm(
                            consumedDate,
                            rating > 0 ? rating : nil,
                            tastingNotes.isEmpty ? nil : tastingNotes
                        )
                    } label: {
                        Label("Confirmer", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .fontWeight(.semibold)
                    }
                    .controlSize(.large)
                    .accessibilityIdentifier("confirm-consumption-button")
                }
            }
            .navigationTitle("Consommation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
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
