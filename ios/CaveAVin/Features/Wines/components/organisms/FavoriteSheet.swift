import SwiftUI

struct FavoriteSheet: View {
    let onConfirm: (Date, [String], String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var consumedDate = Date()
    @State private var contacts: [String] = []
    @State private var tastingNotes = ""
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
                            selection: $consumedDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                    }
                }

                Section {
                    HStack {
                        Label("Avec", systemImage: "person.2")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            showContactPicker = true
                        } label: {
                            Label("Ajouter", systemImage: "plus.circle")
                                .font(.subheadline)
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
            .navigationTitle("Ajouter aux favoris")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler", systemImage: "xmark") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirmer", systemImage: "checkmark") {
                        onConfirm(
                            consumedDate,
                            contacts,
                            tastingNotes.isEmpty ? nil : tastingNotes
                        )
                    }
                    .accessibilityIdentifier("confirm-favorite-button")
                }
            }
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
    FavoriteSheet(onConfirm: { _, _, _ in })
}
