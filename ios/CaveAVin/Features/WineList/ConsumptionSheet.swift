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
                Section {
                    HStack {
                        WineColorBadge(color: wine.color)
                        Text(wine.name)
                            .font(.headline)
                    }
                }

                Section("Date de consommation") {
                    DatePicker("Date", selection: $consumedDate, displayedComponents: .date)
                }

                Section("Note") {
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .foregroundStyle(star <= rating ? .yellow : .gray)
                                .font(.title2)
                                .onTapGesture {
                                    rating = star == rating ? 0 : star
                                }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
                }

                Section("Notes de dégustation") {
                    TextField("Vos impressions...", text: $tastingNotes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Button("Confirmer la consommation") {
                        onConfirm(
                            consumedDate,
                            rating > 0 ? rating : nil,
                            tastingNotes.isEmpty ? nil : tastingNotes
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Consommation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
        }
    }
}
