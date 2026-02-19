import SwiftUI

struct AnalyzingView: View {
    @State private var isPulsing = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.purple.opacity(0.15))
                    .frame(width: 140, height: 140)
                    .scaleEffect(isPulsing ? 1.4 : 0.8)
                    .opacity(isPulsing ? 0.0 : 0.5)

                Circle()
                    .fill(.purple.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .scaleEffect(isPulsing ? 1.2 : 0.9)
                    .opacity(isPulsing ? 0.0 : 0.4)

                Image(systemName: "wineglass")
                    .font(.system(size: 52))
                    .foregroundStyle(.purple)
                    .symbolEffect(.breathe, options: .repeating)
            }

            VStack(spacing: 12) {
                Text("Analyse en cours")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Identification de l'étiquette...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

#Preview {
    AnalyzingView()
}
