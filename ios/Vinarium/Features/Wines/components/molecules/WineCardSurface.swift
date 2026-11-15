import SwiftUI

extension View {
    /// The surface of a card laid on a wine's colours, as the board draws it: glass,
    /// with the grouped card colour at 70 % over it, so the card reads white (dark in
    /// dark mode) with the colours only softly showing through.
    func wineCardSurface(cornerRadius: CGFloat = 26) -> some View {
        background(
            Color(.secondarySystemGroupedBackground).opacity(0.7),
            in: .rect(cornerRadius: cornerRadius)
        )
        .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
    }
}

#Preview {
    Text("Garde")
        .frame(width: 170, height: 196)
        .wineCardSurface()
        .padding(40)
        .background(WineSheetBackdrop(tone: .red))
}
