import SwiftUI

struct ShortlistSheet: View {
    let onConfirm: (Date, [String], String?, Int?) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var consumedDate = Date()
    @State private var contacts: [String] = []
    @State private var tastingNotes = ""
    @State private var rating: Int = 3
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

                    Picker(selection: $rating) {
                        ForEach(1...4, id: \.self) { value in
                            Text("\(value) / 5").tag(value)
                        }
                    } label: {
                        Label("Note", systemImage: "star")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityIdentifier("shortlist-rating-picker")

                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Commentaires", systemImage: "text.quote")
                                .foregroundStyle(.secondary)

                            TextField("Vos impressions, arômes, accords...", text: $tastingNotes, axis: .vertical)
                                .lineLimit(3...6)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("À retenir")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler", systemImage: "xmark") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    AsyncToolbarButton(title: "Confirmer", systemImage: "checkmark") {
                        await onConfirm(
                            consumedDate,
                            contacts,
                            tastingNotes.isEmpty ? nil : tastingNotes,
                            rating
                        )
                    }
                    .accessibilityIdentifier("confirm-shortlist-button")
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
    ShortlistSheet { _, _, _, _ in }
}
