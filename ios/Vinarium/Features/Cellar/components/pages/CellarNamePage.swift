import SwiftUI

/// First step of a new cellar: the name that tells it apart from the others.
struct CellarNamePage: View {
    @Binding var name: String
    var onNext: () -> Void
    var onClose: () -> Void

    @FocusState private var focused: Bool

    private var trimmed: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Comment s'appelle cette cave ?")
                    .font(.title.bold())
                Text("Une cave par meuble ou par pièce : chacune a sa grille.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            TextField("Garage, cuisine, maison de campagne…", text: $name)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.next)
                .focused($focused)
                .onSubmit { if !trimmed.isEmpty { onNext() } }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityIdentifier("new-cellar-name")

            Spacer()

            Button(action: onNext) {
                Text("Continuer")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(trimmed.isEmpty)
            .accessibilityIdentifier("new-cellar-name-next")
        }
        .padding()
        .navigationTitle("Nouvelle cave")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                ToolbarIconButton(title: "Annuler", systemImage: "xmark", role: .cancel, action: onClose)
            }
        }
        .onAppear { focused = true }
    }
}

#Preview {
    NavigationStack {
        CellarNamePage(name: .constant("Garage"), onNext: {}, onClose: {})
    }
}
