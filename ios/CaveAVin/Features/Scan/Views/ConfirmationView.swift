import SwiftUI

struct ConfirmationView: View {
    let wine: Wine
    let position: String
    let onDone: () -> Void

    @State private var scale = 0.5
    @State private var opacity = 0.0
    @State private var progress: CGFloat = 0.0
    @State private var isDone = false

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

            Button {
                guard !isDone else { return }
                isDone = true
                onDone()
            } label: {
                Text("Terminé")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background {
                        GeometryReader { geometry in
                            Capsule()
                                .fill(.blue)
                            Capsule()
                                .fill(.white.opacity(0.25))
                                .frame(width: geometry.size.width * progress)
                        }
                        .clipShape(Capsule())
                    }
            }
            .padding(.horizontal)
            .accessibilityIdentifier("done-button")
        }
        .padding()
        .navigationBarBackButtonHidden()
        .onAppear {
            withAnimation(.spring(duration: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
        .task {
            withAnimation(.linear(duration: 15)) {
                progress = 1.0
            }
            try? await Task.sleep(for: .seconds(15))
            guard !isDone else { return }
            isDone = true
            onDone()
        }
    }
}

#Preview {
    NavigationStack {
        ConfirmationView(
            wine: Wine(
                id: "1", name: "Château Margaux 2018", color: .red,
                createdAt: Date(), updatedAt: Date()
            ),
            position: "B3",
            onDone: {}
        )
    }
}
