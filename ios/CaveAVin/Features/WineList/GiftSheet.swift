import SwiftUI

struct GiftSheet: View {
    let wine: Wine
    let onConfirm: (Date, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var giftedDate = Date()
    @State private var recipientName = ""
    @State private var showContactPicker = false

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

                Section("Date du cadeau") {
                    DatePicker("Date", selection: $giftedDate, displayedComponents: .date)
                }

                Section("Destinataire") {
                    HStack {
                        TextField("Nom du destinataire", text: $recipientName)
                        Button {
                            showContactPicker = true
                        } label: {
                            Image(systemName: "person.crop.circle")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section {
                    Button("Confirmer le cadeau") {
                        onConfirm(
                            giftedDate,
                            recipientName.isEmpty ? nil : recipientName
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("confirm-gift-button")
                }
            }
            .navigationTitle("Offrir")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
            .sheet(isPresented: $showContactPicker) {
                ContactPicker { name in
                    recipientName = name
                }
            }
        }
    }
}

#Preview {
    GiftSheet(
        wine: Wine(
            id: "1", name: "Château Margaux 2018", color: .red,
            createdAt: Date(), updatedAt: Date()
        ),
        onConfirm: { _, _ in }
    )
}
