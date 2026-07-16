import SwiftUI

struct GiftSheet: View {
    let onConfirm: (Date, String?) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var giftedDate = Date()
    @State private var recipientName = ""
    @State private var showContactPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Label("Date", systemImage: "calendar")
                            .foregroundStyle(.secondary)
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
                            .foregroundStyle(.secondary)
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
            }
            .navigationTitle("Offrir")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    ToolbarIconButton(title: "Annuler", systemImage: "xmark", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    AsyncToolbarButton(title: "Confirmer", systemImage: "checkmark") {
                        await onConfirm(
                            giftedDate,
                            recipientName.isEmpty ? nil : recipientName
                        )
                    }
                    .accessibilityIdentifier("confirm-gift-button")
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
    GiftSheet { _, _ in }
}
