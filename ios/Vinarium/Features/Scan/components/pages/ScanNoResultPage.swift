import SwiftUI

/// Écran affiché quand l'IA n'a rien reconnu sur la photo. Garde la photo prise
/// en fond (floutée et assombrie, comme l'écran d'analyse) pour la continuité,
/// et propose de réessayer. Pas de saisie manuelle depuis cet écran.
struct ScanNoResultPage: View {
    /// Photo qui a échoué à la reconnaissance ; `nil` retombe sur un fond noir.
    let imageData: Data?
    let onRetry: () -> Void

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
            }

            ContentUnavailableView {
                Label("Aucun résultat", systemImage: "wineglass")
            } description: {
                Text("L'étiquette n'a pas pu être identifiée. Réessaie avec une photo plus nette et bien cadrée.")
            } actions: {
                Button("Réessayer", action: onRetry)
                    .buttonStyle(.borderedProminent)
            }
        }
        .ignoresSafeArea()
        // The backdrop is always dark, so resolve semantic colors light
        // regardless of the device appearance.
        .environment(\.colorScheme, .dark)
    }
}

#Preview("Avec photo") {
    ScanNoResultPage(
        imageData: UIImage(named: "etiquette")?.jpegData(compressionQuality: 0.8),
        onRetry: {}
    )
}

#Preview("Sans photo") {
    ScanNoResultPage(imageData: nil, onRetry: {})
}
