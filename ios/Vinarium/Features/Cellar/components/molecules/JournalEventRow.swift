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
        // Same recipe as the other rows: icon centered on the first line, which it
        // shares with the position; the lines below run under it, full width, the
        // name truncated with an ellipsis.
        HStack(alignment: .firstLine, spacing: 12) {
            Image(systemName: isEntry ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundStyle(isEntry ? .green : .red)
                .font(.title3)
                .alignmentGuide(.firstLine) { $0[VerticalAlignment.center] }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    if let producer {
                        ProducerOverline(producer: producer)
                    } else {
                        styledTitle
                    }
                    Spacer(minLength: 0)
                    PositionBadge(position: position)
                }
                .alignmentGuide(.firstLine) { $0[VerticalAlignment.center] }
                if producer != nil {
                    styledTitle
                }
                Text(isEntry ? "Entrée" : "Sortie")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let memberName {
                    MemberBadge(name: memberName)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
    }

    private var styledTitle: some View {
        title
            .font(.subheadline)
            .fontWeight(.medium)
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
