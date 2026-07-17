import SwiftUI

/// Sheet présentée quand l'IA n'a rien reconnu sur la photo. La caméra reste
/// visible derrière ; fermer ou réessayer ramène directement dessus.
struct ScanNoResultPage: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 88, height: 88)
                .background(Color(.secondarySystemBackground), in: .circle)

            Text("Aucun résultat")
                .font(.title2.weight(.semibold))

            Button {
                dismiss()
            } label: {
                Text("Réessayer")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
                    .background(Color(.secondarySystemBackground), in: .circle)
            }
            .padding()
        }
    }
}

#Preview {
    Color.black
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            ScanNoResultPage()
                .presentationDetents([.medium])
        }
}
