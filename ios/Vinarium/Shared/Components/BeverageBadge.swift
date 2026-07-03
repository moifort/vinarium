import SwiftUI

/// Pastille d'identification d'une bouteille : couleur du vin quand elle existe,
/// sinon icône du type de boisson (bière, spiritueux, saké ...).
struct BeverageBadge: View {
    let beverageType: BeverageType
    let color: WineColor?

    var body: some View {
        if let color {
            WineColorBadge(color: color)
        } else {
            Image(systemName: beverageType.icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 14, height: 14)
                .background(Circle().fill(beverageType.displayColor))
                .overlay(Circle().stroke(.primary.opacity(0.15), lineWidth: 0.5))
                .accessibilityLabel(beverageType.label)
        }
    }
}

#Preview("Vin et autres boissons") {
    HStack(spacing: 12) {
        BeverageBadge(beverageType: .wine, color: .red)
        ForEach([BeverageType.spirit, .beer, .sake, .cider, .other]) { type in
            VStack {
                BeverageBadge(beverageType: type, color: nil)
                Text(type.label)
                    .font(.caption2)
            }
        }
    }
    .padding()
}
