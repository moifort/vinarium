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

                Section {
                    HStack {
                        Label("Date", systemImage: "calendar")
                        Spacer()
                        DatePicker(
                            "",
                            selection: $giftedDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                    }
                    HStack {
                        Label("Destinataire", systemImage: "person")
                        TextField("Nom", text: $recipientName)
                            .textInputAutocapitalization(.words)
                            .multilineTextAlignment(.trailing)
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
                    Button {
                        onConfirm(
                            giftedDate,
                            recipientName.isEmpty ? nil : recipientName
                        )
                    } label: {
                        Label("Confirmer", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .fontWeight(.semibold)
                    }
                    .controlSize(.large)
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
