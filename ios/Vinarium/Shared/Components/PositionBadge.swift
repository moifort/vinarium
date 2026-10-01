import SwiftUI

struct PositionBadge: View {
    let position: String

    var body: some View {
        // One line whatever it holds: with several cellars the slot carries its
        // cellar's name ("Garage · B4"), which shrinks rather than wraps.
        Text(position)
            .font(.subheadline.monospaced())
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemGray5))
            .clipShape(.rect(cornerRadius: 6))
    }
}

#Preview {
    HStack(spacing: 12) {
        PositionBadge(position: "A1")
        PositionBadge(position: "B3")
        PositionBadge(position: "C12")
        PositionBadge(position: "Cave principale · B4")
    }
    .padding()
}
