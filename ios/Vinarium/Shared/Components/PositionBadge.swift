import SwiftUI

struct PositionBadge: View {
    let position: String

    var body: some View {
        Text(position)
            .font(.subheadline.monospaced())
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
    }
    .padding()
}
