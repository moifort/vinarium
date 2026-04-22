import SwiftUI

struct DashboardEventRow: View {
    let isEntry: Bool
    let wineName: String
    let label: String
    let position: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isEntry ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundStyle(isEntry ? .green : .red)
                .font(.title3)
                .accessibilityLabel(isEntry ? "Entr\u{00E9}e" : "Sortie")

            VStack(alignment: .leading, spacing: 2) {
                Text(wineName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            PositionBadge(position: position)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
    }
}

#Preview {
    VStack(spacing: 0) {
        DashboardEventRow(
            isEntry: true,
            wineName: "Ch\u{00E2}teau Margaux 2018",
            label: "Derni\u{00E8}re entr\u{00E9}e",
            position: "A3"
        )
        DashboardEventRow(
            isEntry: false,
            wineName: "Pouilly-Fum\u{00E9} 2021",
            label: "Derni\u{00E8}re sortie",
            position: "B1"
        )
    }
    .background(Color(.systemGray6))
    .clipShape(.rect(cornerRadius: 12))
    .padding()
}
