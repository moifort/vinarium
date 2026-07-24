import SwiftUI

struct ScanConfirmationPage: View {
    let wineName: String
    var beverageType: BeverageType = .wine
    let wineColor: WineColor?
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

            Text("Succès !")
                .font(.title)
                .fontWeight(.bold)

            Text("Bouteille ajoutée avec succès")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                HStack {
                    BeverageBadge(beverageType: beverageType, color: wineColor)
                    Text(wineName)
                        .font(.headline)
                }

                Text("Position : \(position)")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    onDone()
                } label: {
                    Text("Terminé")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityLabel(Text("Terminé"))
                .accessibilityIdentifier("done-button")
            }
            .padding(.horizontal)
        }
        .padding()
        .navigationBarBackButtonHidden()
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

#Preview {
    NavigationStack {
        ScanConfirmationPage(
            wineName: "Château Margaux 2018",
            wineColor: .red,
            position: "B3",
            onDone: {}
        )
    }
}
