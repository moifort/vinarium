import SwiftUI

struct FavoriteSheet: View {
    /// (date, contacts, notes, rating) — rating is 0 when the user left it unset.
    let onConfirm: (Date, [String], String?, Int) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var consumedDate = Date()
    @State private var contacts: [String] = []
    @State private var tastingNotes = ""
    @State private var rating = 0
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

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Note", systemImage: "star")
                            .foregroundStyle(.secondary)
                        InteractiveStarRating(rating: $rating)
                    }
                    .padding(.vertical, 4)

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
            .navigationTitle("Ajouter aux favoris")
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
                            consumedDate,
                            contacts,
                            tastingNotes.isEmpty ? nil : tastingNotes,
                            rating
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
    FavoriteSheet { _, _, _, _ in }
}
