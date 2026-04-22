import SwiftUI

struct RecommendationSheet: View {
    let onConfirm: (String?, String?) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var recommenderName = ""
    @State private var comment = ""
    @State private var showContactPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Label("Conseillé par", systemImage: "person.badge.star")
                            .foregroundStyle(.secondary)
                        TextField("Nom", text: $recommenderName)
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
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Commentaires", systemImage: "text.quote")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            TextField("Vos impressions, arômes, accords...", text: $comment, axis: .vertical)
                                .lineLimit(3...6)
                        }
                        .padding(.vertical, 4)
                    
                    }
                }
            }
            .navigationTitle("Conseillé par un ami")
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
                            recommenderName.isEmpty ? nil : recommenderName,
                            comment.isEmpty ? nil : comment
                        )
                    }
                    .accessibilityIdentifier("confirm-recommendation-button")
                }
            }
            .sheet(isPresented: $showContactPicker) {
                ContactPicker { name in
                    recommenderName = name
                }
            }
        }
    }
}

#Preview {
    RecommendationSheet { _, _ in }
}
