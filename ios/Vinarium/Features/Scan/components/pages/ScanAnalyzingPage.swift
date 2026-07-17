import SwiftUI

/// Écran d'attente pendant l'analyse IA de l'étiquette. Garde la photo prise
/// visible en fond (floutée et assombrie) pour ne pas couper le fil avec
/// l'utilisateur, avec l'orbe `SiriLoader` et le message par-dessus. Le fond
/// sombre sert aussi la lisibilité de l'orbe (blend `.hardLight`).
struct ScanAnalyzingPage: View {
    /// Photo capturée/choisie (JPEG). `nil` le temps que le picker charge son
    /// image : on affiche alors l'orbe sur fond noir, puis la photo en fondu.
    let imageData: Data?

    private var image: UIImage? {
        imageData.flatMap(UIImage.init(data:))
    }

    var body: some View {
        ZStack {
            Color.black

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 30)
                    .overlay(Color.black.opacity(0.55))
                    .transition(.opacity)
            }

            VStack(spacing: 32) {
                SiriLoader()

                VStack(spacing: 12) {
                    Text("Analyse en cours")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    Text("Identification de l'étiquette...")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.4), value: imageData)
    }
}

#Preview("Avec photo") {
    ScanAnalyzingPage(
        imageData: UIImage(named: "etiquette")?.jpegData(compressionQuality: 0.8)
    )
}

#Preview("Sans photo") {
    ScanAnalyzingPage(imageData: nil)
}
