import SwiftUI

struct DashboardEventRow: View {
    let isEntry: Bool
    /// The producer, shown above the name; nil when there is none or the name says it.
    var producer: String? = nil
    let wineName: String
    let label: LocalizedStringKey
    let position: String
    /// The member behind the move, nil when it was you.
    var memberName: String? = nil

    var body: some View {
        // Same recipe as the other rows: icon centered on the first line, which it
        // shares with the position; the lines below run under it, full width, the
        // name truncated with an ellipsis.
        HStack(alignment: .firstLine, spacing: 12) {
            Image(systemName: isEntry ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundStyle(isEntry ? .green : .red)
                .font(.title3)
                .accessibilityLabel(isEntry ? "Entr\u{00E9}e" : "Sortie")
                .alignmentGuide(.firstLine) { $0[VerticalAlignment.center] }

            VStack(alignment: .leading, spacing: 2) {
                WineRowHeading(producer: producer) {
                    nameText
                } marks: {
                    PositionBadge(position: position)
                }
                MemberTagLine(name: memberName) {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
    }

    private var nameText: some View {
        Text(wineName)
            .font(.subheadline)
            .fontWeight(.medium)
            .lineLimit(1)
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
            producer: "Didier Dagueneau",
            wineName: "Pouilly-Fum\u{00E9} 2021",
            label: "Derni\u{00E8}re sortie",
            position: "B1",
            memberName: "Marie"
        )
    }
    .background(Color(.systemGray6))
    .clipShape(.rect(cornerRadius: 12))
    .padding()
}
