import SwiftUI

struct ConsumptionSheet: View {
    let onConfirm: (Date, Int?, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var consumedDate = Date()
    @State private var rating: Int = 0
    @State private var tastingNotes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        InteractiveStarRating(rating: $rating)
                    }
                    .padding(.vertical, 4)
                   
                }
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
    ConsumptionSheet(onConfirm: { _, _, _ in })
}
