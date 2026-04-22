import SwiftUI

struct ConsumptionSheet: View {
    let onConfirm: (Date, Int?, String?, [String]) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var consumedDate = Date()
    @State private var rating: Int = 0
    @State private var tastingNotes = ""
    @State private var contacts: [String] = []
    @State private var showContactPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Label("Avec", systemImage: "person.2")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            showContactPicker = true
                        } label: {
                            Label("Ajouter", systemImage: "plus.circle")
                        }
                    }
                    ForEach(contacts, id: \.self) { contact in
                        HStack {
                            Text(contact)
                            Spacer()
                            Button {
                                contacts.removeAll { $0 == contact }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        InteractiveStarRating(rating: $rating)
                    }
                    .padding(.vertical, 4)
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
                        Label("Commentaires", systemImage: "text.quote")
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
                    AsyncToolbarButton(title: "Confirmer", systemImage: "checkmark") {
                        await onConfirm(
                            consumedDate,
                            rating > 0 ? rating : nil,
                            tastingNotes.isEmpty ? nil : tastingNotes,
                            contacts
                        )
                    }
                    .accessibilityIdentifier("confirm-consumption-button")
                }
            }
            .animation(.default, value: rating)
            .sheet(isPresented: $showContactPicker) {
                ContactPicker { name in
                    if !contacts.contains(name) {
                        contacts.append(name)
                    }
                }
            }
        }
    }

}

#Preview {
    ConsumptionSheet { _, _, _, _ in }
}
