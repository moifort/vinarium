import SwiftUI

/// Écran affiché juste après l'analyse IA : résumé de la bouteille identifiée
/// et choix explicite de la destination (cave, favori, à retenir, conseillé).
struct ScanDestinationPage: View {
    let name: String
    let beverageType: BeverageType
    let color: WineColor?
    let style: String?
    let vintage: Int?
    let onSelect: (ScanDestination) -> Void
    let onCancel: () -> Void

    private var subtitle: String {
        var parts: [String] = []
        if beverageType == .wine {
            if let color { parts.append(color.label) }
        } else {
            parts.append(beverageType.label)
            if let style { parts.append(style) }
        }
        if let vintage { parts.append(String(vintage)) }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                BeverageBadge(beverageType: beverageType, color: color)
                    .scaleEffect(2)
                    .padding(.bottom, 12)

                Text(name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 32)

            Text("Que veux-tu en faire ?")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(ScanDestination.allCases) { destination in
                    Button {
                        onSelect(destination)
                    } label: {
                        VStack(spacing: 10) {
                            Image(systemName: destination.icon)
                                .font(.system(size: 28))
                                .frame(height: 32)
                            Text(destination.label)
                                .font(.headline)
                            Text(destination.caption)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, minHeight: 130)
                        .padding(12)
                        .background(.fill.tertiary, in: .rect(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("destination-\(destination.rawValue)")
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("Nouvelle bouteille")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Fermer", systemImage: "xmark") { onCancel() }
                    .accessibilityIdentifier("destination-close-button")
            }
        }
    }
}

#Preview("Vin") {
    NavigationStack {
        ScanDestinationPage(
            name: "Château Margaux",
            beverageType: .wine,
            color: .red,
            style: nil,
            vintage: 2018,
            onSelect: { _ in },
            onCancel: {}
        )
    }
}

#Preview("Whisky") {
    NavigationStack {
        ScanDestinationPage(
            name: "Lagavulin 16",
            beverageType: .spirit,
            color: nil,
            style: "Single Malt",
            vintage: nil,
            onSelect: { _ in },
            onCancel: {}
        )
    }
}
