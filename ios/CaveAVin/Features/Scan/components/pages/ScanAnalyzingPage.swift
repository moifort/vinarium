import SwiftUI

struct ScanAnalyzingPage: View {
    @State private var isPulsing = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                ProgressView()
                    .scaleEffect(2)
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
    ScanAnalyzingPage()
}
