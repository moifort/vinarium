import SwiftUI

struct ConfirmationView: View {
    let wine: Wine
    let position: String
    let onDone: () -> Void

    @State private var scale = 0.5
    @State private var opacity = 0.0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
                .scaleEffect(scale)
                .opacity(opacity)

            Text("Bouteille ajoutée !")
                .font(.title)
                .fontWeight(.bold)

            VStack(spacing: 8) {
                HStack {
                    WineColorBadge(color: wine.color)
                    Text(wine.name)
                        .font(.headline)
                }

                Text("Position : \(position)")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Terminé") {
                onDone()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
            .accessibilityIdentifier("done-button")
        }
        .padding()
        .navigationTitle("Confirmation")
        .navigationBarBackButtonHidden()
        .onAppear {
            withAnimation(.spring(duration: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
