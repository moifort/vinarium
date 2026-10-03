import SwiftUI

struct JournalEventRow<Title: View>: View {
    let isEntry: Bool
    let position: String
    /// The producer, shown above the name; nil when there is none or the name says it.
    let producer: String?
    let memberName: String?
    let title: Title

    init(
        isEntry: Bool,
        position: String,
        producer: String? = nil,
        memberName: String? = nil,
        @ViewBuilder title: () -> Title
    ) {
        self.isEntry = isEntry
        self.position = position
        self.producer = producer
        self.memberName = memberName
        self.title = title()
    }

    var body: some View {
        // Same recipe and type sizes as the wine list: icon centered on the first
        // line, which it shares with the position; the lines below run under it,
        // full width, the name truncated with an ellipsis.
        HStack(alignment: .firstLine, spacing: 12) {
            Image(systemName: isEntry ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundStyle(isEntry ? .green : .red)
                .font(.title3)
                .alignmentGuide(.firstLine) { $0[VerticalAlignment.center] }

            VStack(alignment: .leading, spacing: 2) {
                WineRowHeading(producer: producer) {
                    styledTitle
                } marks: {
                    PositionBadge(position: position)
                }
                MemberTagLine(name: memberName) {
                    Text(isEntry ? "Entrée" : "Sortie")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
    }

    private var styledTitle: some View {
        title
            .font(.headline)
            .lineLimit(1)
    }
}

#Preview {
    List {
        JournalEventRow(isEntry: true, position: "A1") {
            Text("Chateau Margaux 2018")
        }
        JournalEventRow(isEntry: true, position: "A2", producer: "Domaine Leflaive") {
            Text("Les Pucelles 2019")
        }
        JournalEventRow(isEntry: false, position: "C5") {
            Text("Cotes de Provence 2022")
        }
        JournalEventRow(isEntry: true, position: "B2", memberName: "Marie") {
            Text("Sancerre 2021")
        }
    }
}
