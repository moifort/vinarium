import SwiftUI

struct SummaryPage: View {
    let firstName: String
    let rows: Int
    let cols: Int
    let isSubmitting: Bool
    var onSubmit: () -> Void
    var onBack: () -> Void

    private var capacity: Int { rows * cols }

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section("Récapitulatif") {
                    LabeledContent("Prénom", value: firstName)
                    LabeledContent("Rangées", value: "\(rows)")
                    LabeledContent("Emplacements par rangée", value: "\(cols)")
                    LabeledContent("Capacité totale") {
                        Text("\(capacity) emplacements").fontWeight(.semibold)
                    }
                }
            }

            Button(action: onSubmit) {
                Text("Terminer")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isSubmitting)
            .padding()
            .accessibilityIdentifier("onboarding-finish")
        }
        .navigationTitle("Résumé")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Retour", systemImage: "chevron.left", action: onBack)
                    .disabled(isSubmitting)
            }
        }
        .overlay {
            if isSubmitting {
                ZStack {
                    Color.black.opacity(0.1).ignoresSafeArea()
                    ProgressView("Enregistrement…")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SummaryPage(
            firstName: "Thibaut",
            rows: 12,
            cols: 6,
            isSubmitting: false,
            onSubmit: {},
            onBack: {}
        )
    }
}
