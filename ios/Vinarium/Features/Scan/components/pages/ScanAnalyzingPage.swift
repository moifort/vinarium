import SwiftUI

/// L'étape d'attente de l'analyse IA, présentée en sheet par-dessus la caméra :
/// l'orbe `SiriLoader` posé sur un scrim `.ultraThinMaterial` avec son message. Le
/// matériau suit l'apparence système au lieu de forcer le noir, et l'orbe (qui porte
/// sa propre scène sombre) y flotte sans traîner de disque. Purement présentationnel.
struct ScanAnalyzingPage: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                SiriLoader()

                VStack(spacing: 12) {
                    Text("Analyse en cours")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Identification de l'étiquette...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
            }
        }
    }
}

#Preview("Clair") {
    Color(.systemBackground)
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            ScanAnalyzingPage()
        }
        .preferredColorScheme(.light)
}

#Preview("Sombre") {
    Color(.systemBackground)
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            ScanAnalyzingPage()
        }
        .preferredColorScheme(.dark)
}
