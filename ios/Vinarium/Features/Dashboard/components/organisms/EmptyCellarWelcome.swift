import SwiftUI

/// The home of a cellar with nothing in it yet: no figures at zero and no empty
/// shelves, only a bottle turning on itself and the one gesture that starts it all,
/// scanning a label.
struct EmptyCellarWelcome: View {
    var onScanTapped: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            SpinningBottle(height: 330)

            Text("La cave est vide")
                .font(.system(size: 28, weight: .bold))
                .tracking(-0.4)
                .padding(.top, 22)

            Text("Scanner une étiquette remplit la fiche de la première bouteille.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .frame(maxWidth: 280)
                .padding(.top, 6)

            Button(action: onScanTapped) {
                Label("Scanner une étiquette", systemImage: "text.viewfinder")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .foregroundStyle(Color(.systemBackground))
                    .background(Color.primary, in: .capsule)
                    .contentShape(.capsule)
            }
            .buttonStyle(.plain)
            .padding(.top, 26)
            .accessibilityIdentifier("empty-home-scan")
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
    }
}

#Preview("Empty cellar") {
    EmptyCellarWelcome()
        .background(alignment: .top) {
            HomeAmbience(tone: .purple).frame(height: 760).offset(y: -200)
        }
}
